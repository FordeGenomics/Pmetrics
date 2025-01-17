#' @title
#' Object to define and run a model and data in Pmetrics
#'
#' @description
#' `PM_fit` objects comprise a `PM_data` and `PM_model` object ready for analysis
#'
#' @details
#' Data and model objects can be previously created as [PM_data] or [PM_model] objects,
#' or created on the fly when making a new PM_fit object. PM_fit objects contain
#' methods to cross-check data and model objects for compatibility, as well as to
#' run the analysis.
#' @export

PM_fit <- R6::R6Class("PM_fit",
  public = list(

    #' @description
    #' Create a new object
    #' @param data Either the name of a  [PM_data]
    #' object in memory or the quoted name of a Pmetrics
    #' data file in the current working directory, which will crate a `PM_data`
    #' object on the fly. However, if created on the fly, this object
    #' will not be available to other
    #' methods or other instances of `PM_fit`.
    #' @param model Similarly, this is either the name of a [PM_model]
    #' object in memory or the quoted name of a Pmetrics text model file
    #' in the current working directory. Again, if created on the fly,
    #' the object will not be available to other
    #' methods or other instances of `PM_fit`.
    #' @param ... Other parameters passed to `PM_data` or `PM_model` if created
    #' from a filename
    initialize = function(data = data, model = model, ...) {
      if (is.character(data)) {
        data <- PM_data$new(data, ...)
      }
      if (is.character(model)) {
        model <- PM_model$new(model, ...)
      }
      stopifnot(inherits(data, "PM_data"))
      stopifnot(inherits(model, "PM_model"))
      private$data <- data
      private$model <- model
    },
    #' @description Fit the model to the data
    #' @param ... Other arguments passed to [NPrun]
    #' @param engine "NPAG" (default) or "IT2B"
    #' @param rundir This argument specifies an *existing* folder that will store the run inside.
    run = function(..., engine = "NPAG", rundir = getwd()) {
      wd <- getwd()
      if (!dir.exists(rundir)) {
          stop("You have specified a directory that does not exist, please create it first.")
       }
      setwd(rundir)
      engine <- tolower(engine)
      if (inherits(private$model, "PM_model_legacy")) {
        cat(sprintf("Runing Legacy"))
        if (engine == "npag") {
          Pmetrics::NPrun(private$model$legacy_file_path, private$data$standard_data, ...)
        } else if (engine == "it2b") {
          Pmetrics::ITrun(private$model$legacy_file_path, private$data$standard_data, ...)
        } else {
          endNicely(paste0("Unknown engine: ", engine, ". \n"))
        }
      } else if (inherits(private$model, "PM_model_list")) {
        engine <- tolower(engine)
        model_path <- private$model$write(engine = engine)
        cat(sprintf("Creating model file at: %s\n", model_path))
        if (engine == "npag") {
          Pmetrics::NPrun(model_path, private$data$standard_data, ...)
        } else {
          Pmetrics::ITrun(model_path, private$data$standard_data, ...)
        }
      } else if (inherits(private$model, "PM_model_julia")) {
        if (engine != "npag") {
          stop("Julia is only for NPAG currently.")
        }
        cat(sprintf("Runing Julia: %s-%s\n", private$data, private$model$name))
        return(
          julia_call(
            "npag.run",
            private$model$model_function,
            private$data,
            private$model$min,
            private$model$max,
            private$model$error[1],
            private$model$error[2],
            private$model$error[3],
            private$model$n_theta0
          )
        )
      }
      setwd(wd)
    },
    #' @description
    #' Save the current PM_fit object to a .rds file.
    #' @param file_name Name of the file to be created. The
    #' default is "PMfit.rds".
    save = function(file_name = "PMfit.rds") {
      saveRDS(self, file_name)
    },

    #' @description
    #' `PM_fit` objects contain a `save` method which invokes [saveRDS] to write
    #' the object to the hard drive as an .rds file. This is the corresponding load
    #' function.
    #' @param file_name Name of the file to be read, the default is "PMfit.rds".
    #' @return A `PM_fit` object.
    load = function(file_name) {
      return(invisible())
    },
    #' @description
    #' Checks for errors in data and model objects and agreement between them.
    check = function() {
      if (inherits(private$model, "PM_model_list")) {
        cat(sprintf("Checking...\n"))
        file_name <- random_name()
        private$model$write(file_name)
        Pmetrics::PMcheck(private$data$standard_data, file_name)
        system(sprintf("rm %s", file_name))
      }
    }
  ),
  private = list(
    data = NULL,
    model = NULL
  )
)



#' @export
PM_fit$load <- function(file_name = "PMfit.rds") {
  readRDS(file_name)
}
