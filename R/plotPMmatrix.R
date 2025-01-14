#' `plot.PM_data` plots *PM_data* objects
#'
#' This function will plot raw and fitted time and concentration data with a variety of options.
#' By default markers are included and  have the following plotly properties:
#' `list(symbol = "circle", color = "red", size = 10, opacity = 0.5, line = list(color = "black", width = 1))`. 
#' Markers can be joined by lines, default is `FALSE`. If chosen to be `TRUE`, 
#' the joining lines will have the following properties:
#' `list(color = "dodgerblue", width = 1, dash = "solid"`.
#' The grid and legend are omitted by default.
#'
#' @title Plot PM_data Time-Output Data
#' @method plot PM_data
#' @param x The name of an `PM_data` data object created by [PM_data$new()] or loaded as a field
#' in a [PM_result] object
#' @param include `r template("include")` 
#' @param exclude `r template("exclude")` 
#' @param line Formats the lines joining observations. `r template("line")` 
#' @param pred The name of a population or posterior prediction object in a [PM_result] object, eg. 
#' `run1$post` or `run1$pop`. Can be a list, with the prediction object first, followed by named options to control the 
#' prediction plot
#' * icen Chooses the median or mean of each
#' subject's Bayesian posterior parameter distribution.  Default is "median", but could be "mean".
#' * Other parameters to pass to plotly to control line characteristics, including `color`, `width`, and `dash`.
#' For example: `pred = list(run1$post, icen = "mean", color = "red", width = 2)`. 
#' Defaults are the same as for the `line` argument, since normally one would not plot
#' both lines joining observations and prediction lines.
#' @param marker Formats the symbols plotting observations. `r template("marker")` 
#' @param color Character vector naming a column in `x` to **group** by, e.g. "id" or 
#' a covariate like "gender"
#' @param colors to use for **groups**. This can be a palette or a vector of colors.
#' For accepted palette names see `RColorBrewer::brewer.pal.info`. Examples include
#' "BrBG", or "Set2". An example vector could be `c("red", "green", "blue")`. It is not
#' necessary to specify the same number of colors as groups within `color`, as colors
#' will be interpolated to generate the correct number. The default when `color`
#' is specified is the "Spectral" palette.
#' @param names A character vector of names to label the **groups** if `legend = T`.
#' This vector does need to be the same length as the number of groups within `color`.
#' Example: `c("Male", "Female")` if `color = "gender"` and "gender" is a covariate
#' in the data.
#' @param mult `r template("mult")` 
#' @param outeq `r template("outeq")` 
#' @param block `r template("block")` Default is 1.
#' @param tad `r template("tad")` 
#' @param overlay Boolean operator to overlay all time concentration profiles in a single plot.
#' The default is `TRUE`.
#' @param legend `r template("legend")` Default is `FALSE`
#' @param log `r template("log")` 
#' @param grid `r template("grid")` 
#' @param xlim `r template("xlim")` 
#' @param ylim `r template("ylim")` 
#' @param xlab `r template("xlab")` Default is "Time".
#' @param ylab `r template("ylab")` Default is "Output".
#' @param title `r template("title")` Default is to have no title.
#' @param \dots `r template("dotsPlotly")`
#' @return Plots the object.
#' @author Michael Neely
#' @seealso [PM_data], [PM_result]
#' @export
#' @examples 
#' #basic spaghetti plot
#' exData$plot()
#' #plot by subject
#' exData$plot(overlay = F)
#' #format line and marker
#' exData$plot(
#' marker = list(color = "blue", symbol = "square", size = 12, opacity = 0.4),
#' line = list(color = "orange"))
#' #include predictions with default format and suppress joining lines
#' exData$plot(
#' line = F,
#' pred = NPex$pop,
#' xlim = c(119,146))
#' #customize prediction lines
#' exData$plot(
#' line = F,
#' pred = list(NPex$post, color = "slategrey", dash = "dash"))
#' @family PMplots

plot.PM_data <- function(x, 
                         include, exclude, 
                         line,
                         marker = T,
                         color,
                         colors,
                         names,
                         mult = 1, 
                         outeq = 1, 
                         block = 1,
                         tad = F,
                         overlay = T,
                         legend = F, 
                         log = F, 
                         grid = F,
                         xlab, ylab,
                         title,
                         xlim, ylim,...){
  
  
  
  # Plot parameters ---------------------------------------------------------
  
  #process marker
  marker <- amendMarker(marker)
  
  #process line
  if(missing(line)){
    line <- list(join = T, pred = NULL)
  } else {
    if(any(!base::names(line)%in% c("join", "pred"))){
      cat(paste0(crayon::red("Warning: "),"<line> should be a list with at most two named elements: ",crayon::blue("<join>")," and/or ",crayon::blue("<pred>"),".\n See help(\"plot.PM_data\")."))
    }
    if(is.null(line$join)) {line$join <- F}
    if(is.null(line$pred)) {line$pred <- NULL}
  }
  
  join <- amendLine(line$join)
  pred <- line$pred #process further later
  
  
  #process for groups
  if(missing(color)){
    color <- NULL
  } else {
    if(!color %in% base::names(x$standard_data)){
      stop(paste0(crayon::red(color), " is not a column in the data.\n"))
    }
  }
  
  palettes <- RColorBrewer::brewer.pal.info %>% mutate(name = rownames(.))
  if(missing(colors)){
    colors <- "Spectral"
  }
  
  if(missing(names)){
    names <- NULL
  }
  
  
  #get the rest of the dots
  layout <- amendDots(list(...))
  
  #legend
  legendList <- amendLegend(legend)
  layout <- modifyList(layout, list(showlegend = legendList$showlegend))
  if(length(legendList)>1){layout <- modifyList(layout, list(legend = within(legendList,rm(showlegend))))}
  
  #grid
  layout$xaxis <- setGrid(layout$xaxis, grid)
  layout$yaxis <- setGrid(layout$yaxis, grid)
  
  #axis labels if needed
  xlab <- if(missing(xlab)){"Time"} else {xlab}
  ylab <- if(missing(ylab)){"Output"} else {ylab}
  
  layout$xaxis$title <- amendTitle(xlab)
  if(is.character(ylab)){
    layout$yaxis$title <- amendTitle(ylab, layout$xaxis$title$font)
  } else {
    layout$yaxis$title <- amendTitle(ylab)
  }
  
  
  #axis ranges
  if(!missing(xlim)){layout$xaxis <- modifyList(layout$xaxis, list(range = xlim)) }
  if(!missing(ylim)){layout$yaxis <- modifyList(layout$yaxis, list(range = ylim)) }
  
  #log y axis
  if(log){
    layout$yaxis <- modifyList(layout$yaxis, list(type = "log"))
  }
  
  #title
  if(missing(title)){ title <- ""}
  layout$title <- amendTitle(title, default = list(size = 20))
  
  
  
  # Data processing ---------------------------------------------------------
  
  #filter & group by id
  if(missing(include)) {include <- NA}
  if(missing(exclude)) {exclude <- NA}
  
  presub <- x$standard_data %>% filter(outeq == !!outeq, block == !!block, evid == 0) %>% 
    includeExclude(include,exclude) %>% 
    group_by(id)
  
  #time after dose
  if(tad){presub$time <- calcTAD(presub)}
  
  #select relevant columns
  sub <- presub %>% select(id, time, out)
  if(!is.null(color)){
    group <- presub %>% ungroup() %>% select(group = !!color) 
    sub <- bind_cols(sub, group)
  }
  
  #add identifier
  sub$src <- "obs"
  
  #remove missing
  sub <- sub %>% filter(out !=-99)
  
  #now process pred data if there
  if(!is.null(pred)){
    if(inherits(pred,c("PM_post", "PM_pop"))){pred <- list(pred)} #only PM_post/pop was supplied, make into a list of 1
    if(!inherits(pred[[1]],c("PM_post", "PM_pop"))){
      cat(paste0(crayon::red("Warning: "), "The first element of ", crayon::blue("pred"), " must be a PM_pop or PM_post object.\n"))
    } else {
      predData <- pred[[1]]$data
      if(length(pred)==1){ #default
        predArgs <- T
        icen <- "median"
      } else { #not default, but need to extract icen if present
        icen <- purrr::pluck(pred, "icen") #check if icen is in list
        if(is.null(icen)){ #not in list so set default
          icen <- "median"
        } else {pluck(predArgs, "icen") <- NULL} #was in list, so remove after extraction
        predArgs <- pred[-1]
      }
      
      predArgs <- amendLine(predArgs)
      
    }
    
    #filter and group by id
    predsub <- predData %>% filter(outeq == !!outeq, block == !!block, icen == !!icen) %>% 
      includeExclude(include,exclude) %>% group_by(id)
    
    #time after dose
    if(tad){predsub$time <- calcTAD(predsub)}
    
    #select relevant columns and filter missing
    predsub <- predsub %>% select(id, time, out = pred) %>%
      filter(out !=-99)
    
    #add group if needed
    if(!is.null(color)){
      predsub$group <- sub$group[match(predsub$id, sub$id)]
    }
    
    #add identifier
    predsub$src <- "pred"
    
  } else {predsub <- NULL} #end pred processing
  
  
  
  # Plot function ----------------------------------------------------------
  
  dataPlot <- function(allsub, overlay, includePred){
    
    #set appropriate pop up text
    if(!overlay){
      hovertemplate <-  "Time: %{x}<br>Out: %{y}<extra></extra>"
      text <- ""
    } else {
      hovertemplate <- "Time: %{x}<br>Out: %{y}<br>ID: %{text}<extra></extra>"
      text <- ~id
    }
    
    
    if(!is.null(color)){ #there was grouping
      if(!is.null(names)){
        allsub$group <- factor(allsub$group, labels = names)
      } else {
        allsub$group <- factor(allsub$group)
      }
      
      if(length(colors)==1 && colors %in% palettes$name){
        max_colors <- palettes$maxcolors[match(colors, palettes$name)]
        n_colors <- length(levels(allsub$group))
        colors <- colorRampPalette(RColorBrewer::brewer.pal(max_colors, colors))(n_colors)
      }
      
      # colorLevels <- allsub$group
      # nameLevels <- allsub$group
      marker$color <- NULL
      join$color <- NULL
    } else {
      # colorLevels <- NULL
      # nameLevels <- "Observed"
      allsub$group <- factor(1,labels = "Observed")
    }
    
    p <- allsub %>% plotly::filter(src == "obs") %>%
      plotly::plot_ly(x = ~time, y = ~out * mult,
                      color = ~group,
                      colors = colors,
                      name = ~group) %>%
      plotly::add_markers(marker = marker,
                          text = text,
                          hovertemplate = hovertemplate) %>%
      plotly::add_lines(line = join,
                        showlegend = F)
    
    
    if(includePred){
      if(!is.null(color)){ predArgs$color <- NULL}
      p <- p %>% 
        plotly::add_lines(data = allsub[allsub$src == "pred",], x = ~time, y = ~out,
                          line = predArgs,
                          name = "Predicted",
                          showlegend = F)
    }
    p <- p %>% plotly::layout(xaxis = layout$xaxis,
                              yaxis = layout$yaxis,
                              title = layout$title,
                              showlegend = layout$showlegend,
                              legend = layout$legend) 
    return(p)
  } #end dataPlot
  
  
  # Call plot ---------------------------------------------------------------
  
  
  #if pred present, need to combine data and pred for proper display
  if(!is.null(predsub)){
    allsub <- dplyr::bind_rows(sub, predsub) %>% dplyr::arrange(id, time)
    includePred <- T
  } else {
    allsub <- sub
    includePred <- F
  }
  
  #call the plot function and display appropriately 
  if(overlay){
    p <- dataPlot(allsub, overlay = T, includePred)
    print(p)
  } else { #overlay = F, ie. split them
    sub_split <- allsub %>% nest(data = -id) %>%
      mutate(panel = trelliscopejs::map_plot(data, dataPlot, overlay = F, includePred = includePred))
    p <- sub_split %>% ungroup() %>% trelliscopejs::trelliscope(name = "Data", self_contained = F)
    print(p)
  }
  
  return(p)
}



#' \code{plot.PMmatrix} plots \emph{PMmatrix} objects
#'
#' This function will plot raw and fitted time and concentration data with a variety of options.
#' For the legend, defaults that are different that the standard are:
#' \itemize{
#'   \item x Default \dQuote{topright}
#'   \item legend Default will be factor label names if \code{group} is specified and valid; otherwise
#'   \dQuote{Output 1, Output 2,...Output n}, where \emph{n} is the number of output equations.  This default
#'   can be overridden by a supplied character vector of output names.
#'   \item fill The color of each group/output as specified by the default color scheme or \code{col}
#'   \item bg Default \dQuote{white}
#' }
#'
#' @title Plot PMmatrix Time-Output Data
#' @method plot PMmatrix
#' @param x The name of an \emph{PMmatrix} data object read by \code{\link{PMreadMatrix}}
#' @param include A vector of subject IDs to include in the plot, e.g. c(1:3,5,15)
#' @param exclude A vector of subject IDs to exclude in the plot, e.g. c(4,6:14,16:20)
#' @param pred The name of a population or posterior prediction object read by \code{\link{makePop}} or 
#' \code{\link{makePost}}, respectively
#' @param icen Only relevant for PMpost or PMpop objects which have predictions based on median or mean of each
#' subject's Bayesian posterior parameter distribution.  Default is "median", but could be "mean".
#' @param mult Multiplication factor for y axis, e.g. to convert mg/L to ng/mL
#' @param outeq A vector of output equation(s) to plot; if missing, plot all.  E.g. outeq=1, outeq=2, outeq=c(1,3).
#' @param group Quoted name of a covariate in \code{data} by which
#' to distinguish groups with color in the plot. Note that if covariates do not have values on observation
#' rows, those observations will be unable to be grouped.  Grouping is only applicable if \code{outeq} is
#' specified; otherwise there would be a confusing mix of colors for groups and output equations.
#' @param block Which block to plot, where a new block is defined by dose resets (evid=4); default is 1.
#' @param layout If \code{overlay} is \code{False}, this parameter specifies the number of plots per page.
#' @param log Boolean operator to plot in log-log space; the default is \code{False}
#' @param pch Controls the plotting symbol for observations; default is NA which results in no symbol.
#' Use 0 for open square, 1 for open circle, 2 for open triangle, 3 for cross, 4 for X, or 5 for a diamond.
#' Other alternatives are \dQuote{*} for asterisks, \dQuote{.} for tiny dots, or \dQuote{+} for a smaller,
#' bolder cross.  These plotting symbols are standard for R (see \code{\link{par}}).
#' @param errbar Either boolean (true/false) or a list.  If assay error coefficients are included
#' in the data file, setting this to \code{True} will plot error bars around each observation
#' according to the standard deviation calculated from C0, C1, C2 and C3 in the data file.
#' If C0, C1, C2, and C3 are missing in the data file, you can specify \code{errbar} to be a named list,
#' i.e. \code{list(c0=,c1=,c2=,c3=)}, where each value is a vector of length equal to the number of
#' output equations.  For example, with two output equations having coefficients of 
#' 0.1, 0.15, 0, 0 and 0.2, 0.1, -0.001, and 0, specify as \code{errbar=list(c0=c(0.1,0.2),
#' c1=c(0.15,0.1),c2=c(0,-0.001),c3=c(0,0))}.
#' @param doses Boolean operator to include doses as small lines at the bottom of the plot.
#' Infusions are correctly represented according to their duration.  The default is \code{False}.
#' This parameter is ignored if \code{overlay} is \code{True}.
#' @param tad Boolean operator to use time after dose rather than time after start.  Default is \code{False}.
#' @param join Boolean operator to join observations by a straight line; the default is \code{True}.
#' @param grid Either a boolean operator to plot a reference grid, or a list with elements x and y,
#' each of which is a vector specifying the native coordinates to plot grid lines; the default is \code{False}.
#' For example, grid=list(x=seq(0,24,2),y=1:10).  Defaults for missing x or y will be calculated by \code{\link{axTicks}}.
#' @param ident Boolean operator to plot points as ID numbers in overlay plots; the default is \code{False}.  Ignored if \code{overlay} is false.
#' This option is useful to identify outliers.
#' @param overlay Boolean operator to overlay all time concentration profiles in a single plot.
#' The default is \code{True}.
#' @param main An optional parameter to specify the title for plot(s).  If \code{overlay} is \code{False},
#' the default will be the subject identification. If \code{overlay} is \code{True}, the default is blank.
#' To omit a title from a non-overlaid plot, use the syntax \code{main=}\dQuote{}.
#' @param xlim Optional to specify the limits for the x axis.
#' @param ylim Optional to specify the limits for the y axis.
#' @param xlab Label for the x axis.  Default is \dQuote{Time (h)}
#' @param ylab Label for the y axis.  Default is \dQuote{Observation}
#' @param col A vector of color names to be used for output equation or group coloring.  If the
#' length of \code{col} is too short, values will be recycled.
#' @param col.pred  A vector of color names to be used for prediction (post or pop) coloring.  Default is the same
#' as \code{col}.
#' @param cex Size of the plot symbols.
#' @param legend Either a boolean operator or a list of parameters to be supplied to the \code{\link{legend}}
#' function (see its documentation).  If \code{False} or missing, a legend will not be plotted.
#' If \code{True}, the default legend parameters will be used, as documented in that function, with exceptions
#' as noted in \emph{Details}.
#' @param out Direct output to a PDF, EPS or image file.  Format is a named list whose first argument, 
#' \code{type} is one of the following character vectors: \dQuote{pdf}, \dQuote{eps} (maps to \code{postscript}),
#' \dQuote{\code{png}}, \dQuote{\code{tiff}}, \dQuote{\code{jpeg}}, or \dQuote{\code{bmp}}.  Other named items in the list
#' are the arguments to each graphic device. PDF and EPS are vector images acceptable to most journals
#' in a very small file size, with scalable (i.e. infinite) resolution.  The others are raster images which may be very
#' large files at publication quality dots per inch (DPI), e.g. 800 or 1200. Default value is \code{NA} which means the 
#' output will go to the current graphic device (usually the monitor). For example, to output an eps file,
#' out=list(\dQuote{eps}) will generate a 7x7 inch (default) graphic.
#' @param \dots Other parameters as found in \code{\link{plot.default}}.
#' @return Plots the object.
#' @author Michael Neely
#' @seealso \code{\link{PMreadMatrix}}, \code{\link{plot}}, \code{\link{par}}, \code{\link{axis}}
#' @export
#' @examples
#' data(mdata.1)
#' plot(mdata.1)

plot.PMmatrix <- function(x,include,exclude,pred=NULL,icen="median",mult=1,outeq,group,block=1,
                          layout=c(3,3),log=F,pch=NA,errbar=F,doses=F,tad=F,
                          join=T,grid,ident=F,overlay=T,main,xlim,ylim,
                          xlab="Time (h)",ylab="Observation",col,col.pred,cex=1,legend,out=NA,...){
  
  #error bar function
  add.ebar <- function(x, y, upper, lower=upper, length=0.05,...){
    if(length(x) != length(y) | length(y) !=length(lower) | length(lower) != length(upper))
      stop("vectors must be same length")
    arrows(x,y+upper, x, y-lower, angle=90, code=3, length=length, ...)
  }
  
  #choose output
  if(inherits(out,"list")){
    if(out$type=="eps") {setEPS();out$type <- "postscript"}
    if(length(out)>1) {do.call(out$type,args=out[-1])} else {do.call(out$type,list())}
  }
  
  data <- x
  
  #switch to time after dose if requested
  if(tad){
    for(i in 1:nrow(data)){
      if(data$evid[i]!=0){
        doseTime <- data$time[i]
        prevDose <- data$dose[i]
      }
      data$orig.time[i] <- data$time[i]
      data$time[i] <- data$time[i] - doseTime
      data$prevDose[i] <- prevDose
      if(xlab=="Time (h)") xlab <- "Time After Dose (h)"
    }
    data <- data[order(data$id,data$time,-data$evid),]
  }
  
  if(!missing(include)){
    data <- subset(data,sub("[[:space:]]+","",as.character(data$id)) %in% as.character(include))
    if(!is.null(pred)) pred <- pred[sub("[[:space:]]+","",as.character(pred$id)) %in% as.character(include),]
  } 
  if(!missing(exclude)){
    data <- subset(data,!sub("[[:space:]]+","",as.character(data$id)) %in% as.character(exclude))
    if(!is.null(pred)) pred <- pred[!sub("[[:space:]]+","",as.character(pred$id)) %in% as.character(exclude),]
  } 
  
  if(missing(col)) col <- c("black","red","blue","green","purple","orange","pink","gray50") 
  
  #make error bar object
  obsdata <- data[data$evid==0,]
  if(is.logical(errbar)){
    ebar <- list(plot=errbar,id=obsdata$id,sd=obsdata$c0+obsdata$c1*obsdata$out+obsdata$c2*obsdata$out^2+obsdata$c3*obsdata$out^3,
                 outeq=obsdata$outeq)
    
  } else {
    if(!identical(names(errbar),c("c0","c1","c2","c3"))) stop("\nSee plot.PMmatrix help for structure of errbar argument.\n")
    if(any(sapply(errbar,length)!=max(obsdata$outeq,na.rm=T))) stop("\nSee plot.PMmatrix help for structure of errbar argument.\n")
    ebar <- list(plot=T,id=obsdata$id,sd=errbar$c0[obsdata$outeq]+errbar$c1[obsdata$outeq]*obsdata$out+errbar$c2[obsdata$outeq]*obsdata$out^2+errbar$c3[obsdata$outeq]*obsdata$out^3,
                 outeq=obsdata$outeq)
  }
  
  if(!missing(legend)){        
    if(class(legend)=="list"){
      legend$plot<- T
      if(is.null(legend$x)) legend$x <- "topright"
      if(is.null(legend$bg)) legend$bg <- "white"
    } else {
      if(legend) legend <- {list(plot=T,x="topright",bg="white")} else {legend <- list(plot=F)}
    }
  } else {legend <- list(plot=F)}
  
  if(length(grep("SIM",data$id))>0) data$id <- as.numeric(gsub("[[:alpha:]]","",data$id))
  
  if(!is.null(pred)){
    #remove SIM prefix from simulated IDs if necessary
    if(length(grep("SIM",pred$id))>0) pred$id <- as.numeric(gsub("[[:alpha:]]","",pred$id))
    #check to make sure updated
    if("pred1" %in% names(pred)){stop("\nPlease update your pred object using makePost or makePop and then PMsave.\n")}
    #filter to icen
    pred <- pred[pred$icen==icen,]
    #multiply by mult
    pred$pred <- pred$pred * mult
  }
  
  data$out[data$out==-99] <- NA
  data$out <- data$out*mult
  if(log){
    logplot <- "y"
    yaxt <- "n"
    if(any(data$out<=0,na.rm=T)){
      cat("Observations <= 0 omitted from log plot.\n")
      data$out[data$out<=0] <- NA
    }
  } else {
    logplot <- ""
    yaxt <- "s"
  }
  if(join){jointype <- "o"} else {jointype <- "p"}
  ndrug <- max(data$input,na.rm=T)
  numeqt <- max(data$outeq,na.rm=T)
  #make sure pch is long enough
  pch <- rep(pch,numeqt)
  
  #make event blocks, delimited by evid=4
  data <- makePMmatrixBlock(data)
  
  #filter data and predictions (if present) by block
  data <- data[data$block==block,]
  if(!is.null(pred)){pred <- pred[pred$block==block,]}
  
  #set outeq if missing to all 
  if(missing(outeq)) outeq <- 1:numeqt
  
  #if length of outeq is only 1
  if(length(outeq)==1){
    omit <- which(!is.na(data$outeq) & data$outeq!=outeq)
    if(length(omit)>0) data <- data[-omit,]
    numeqt <- 1
    #filter predicted if outeq supplied
    if(!is.null(pred)){pred <- pred[pred$outeq==outeq,]}
    #if group supplied, color data by group
    if(!missing(group)){
      groupindex <- which(names(data)==group)
      if(length(groupindex)==1) group <- data[,groupindex]
      if(length(groupindex)>1) stop("Group must be a single factor.\n")
      if(length(groupindex)==0) stop("Group must be a factor in the data.\n")
      group <- as.factor(group)
      #filter group
      if(length(omit)>0) group <- group[-omit]
      #make sure there are enough colors; if not, recycle
      if(length(col)<length(levels(group))) col <- rep(col,ceiling(length(levels(group))/length(col)))
      data$col <- col[as.numeric(group)]
      if(is.null(legend$legend)) legend$legend <- levels(group)
      if(is.null(legend$fill)) legend$fill <- col[1:length(legend$legend)]
      if(is.na(legend$fill[1])) legend$fill <- NULL
      #color predicted if supplied
      if(!is.null(pred)){
        if(!missing(col.pred)){
          #make sure there are enough colors; if not, recycle
          if(length(col.pred)<length(levels(group))) col.pred <- rep(col.pred,ceiling(length(levels(group))/length(col.pred)))
          pred$col <- col.pred[as.numeric(group)]
        }else{pred$col <- data$col[match(as.character(pred$id),data$id[data$outeq==outeq])]}
      }
    } else {
      #no group, so color the single output equqtion
      data$col <- ifelse(!is.na(data$outeq),col[data$outeq],NA)
      if(is.null(legend$legend)) legend$legend <- paste("Output",outeq)
      if(is.null(legend$fill)) legend$fill <- col[outeq]
      if(is.na(legend$fill[1])) legend$fill <- NULL
      
      #color predicted if supplied
      if(!is.null(pred)){
        if(!missing(col.pred)){
          #make sure there are enough colors; if not, recycle
          if(length(col.pred)<outeq) col.pred <- rep(col.pred,ceiling(outeq/length(col.pred)))
          pred$col <- col.pred[outeq]
        }else{pred$col <- col[outeq]}        
      }
    }
  } else {
    #outeq length>1, so groups won't apply and color by outeq
    numeqt <- length(outeq)
    if(!missing(group)) warning("Group factor ignored with multiple outputs.\n")
    if(length(col) < numeqt) col <- rep(col,ceiling(numeqt/length(col)))
    data$col <- ifelse(!is.na(data$outeq),col[data$outeq],NA)
    if(is.null(legend$legend)) legend$legend <- paste("Output",outeq)
    if(is.null(legend$fill)) legend$fill <- col[outeq]
    if(is.na(legend$fill[1])) legend$fill <- NULL
    
    #color predicted if supplied
    if(!is.null(pred)){
      if(!missing(col.pred)){
        #make sure there are enough colors; if not, recycle
        if(length(col.pred)<numeqt) col.pred <- rep(col.pred,ceiling(numeqt/length(col.pred)))
        for(i in outeq){pred$col[pred$outeq==i] <- col.pred[i]}
      }else{
        for(i in outeq){pred$col[pred$outeq==i] <- col[i]}
      } 
    }
    
  }
  
  if (missing(xlim)) {xlim.flag <- T} else {xlim.flag <- F}
  if (missing(ylim)) {ylim.flag <- T} else {ylim.flag <- F}
  if (missing(main)) {main.flag <- T} else {main.flag <- F}
  
  # PLOTS -------------------------------------------------------------------
  
  #don't overlay
  if(!overlay){
    par(mfrow=layout)
    devAskNewPage(ask=T)
    
    #predicted is supplied
    if(!is.null(pred)){
      for (i in unique(data$id)){      
        if (xlim.flag){
          xlim <- base::range(c(data$time[data$id==i],pred$time[pred$id==i]),na.rm=T)
          if(abs(xlim[1])==Inf | abs(xlim[2])==Inf) xlim <- base::range(data$time,na.rm=T)
        }
        if (ylim.flag){
          ylim <- base::range(c(data$out[data$id==i],pred$pred[pred$id==i]),na.rm=T)
          if(abs(ylim[1])==Inf | abs(ylim[2])==Inf) ylim <- base::range(data$out,na.rm=T)
          if(log){ylim[1][ylim[1]==0] <- 0.5*min(data$out[data$id==i],na.rm=T)}
        }
        if (main.flag) main <- paste("ID",i)
        plot(out~time,data=subset(data,data$id==i),xlab=xlab,ylab=ylab,main=main,xlim=xlim,ylim=ylim,log=logplot,type="n",yaxt=yaxt,...)
        if(missing(grid)){
          grid <- list(x=NA,y=NA)
        } else {
          if(inherits(grid,"logical")){
            if(grid){
              grid <- list(x=axTicks(1),y=axTicks(2))
            } else {
              grid <- list(x=NA,y=NA)
            }
          }
          if(inherits(grid,"list")){
            if(is.null(grid$x) | all(!is.na(grid$x))) grid$x <- axTicks(1)
            if(is.null(grid$y) | all(!is.na(grid$y))) grid$y <- axTicks(2)
          }
        }
        if(yaxt=="n") logAxis(2,grid=!all(is.na(grid$y)))
        abline(v=grid$x,lty=1,col="lightgray")
        abline(h=grid$y,lty=1,col="lightgray")
        for(j in outeq){
          tempdata <- subset(data,data$id==i & data$outeq==j)
          temppred <- pred[pred$id==i & pred$outeq==j,]
          points(out~time,data=tempdata,type=jointype,pch=pch[j],col=tempdata$col,cex=cex,...)
          lines(pred~time,data=temppred,col=temppred$col,...)
          if(ebar$plot){add.ebar(x=tempdata$time[data$evid==0],
                                 y=tempdata$out[data$evid==0],
                                 upper=ebar$sd[ebar$id==i & ebar$outeq==j],col=subset(data$col,data$id==i & data$outeq==j))
          }
        }
        if (doses){
          for(k in 1:ndrug){
            x <- data$time[data$id==i & data$input==k & !is.na(data$input)]
            dur <- data$dur[data$id==i & data$input==k & !is.na(data$input)]
            dur[dur<0.051*diff(xlim)] <- 0.05*diff(xlim)
            ndose <- length(x)
            for (l in 1:ndose){
              xmin <- x[l]
              xmax <- x[l]+dur[l]
              ymin <- ylim[1]
              ymax <- c(ylim[1]+0.1*(ylim[2]-ylim[1]),10**(log10(ylim[1]) + 0.1*log10(ylim[2]/ylim[1])))[1 + as.numeric(log)]
              abline(v=x[l],lty="dotted",lwd=1,col="black")
              polygon(x=c(xmin,xmin,xmax,xmax),y=c(ymin,ymax,ymax,ymin),col=col[k],border=NA)
            }
          }
        }
        if(legend$plot) do.call("legend",legend)
        
      }
    } else {
      #case where there is no predicted
      for (i in unique(data$id)){
        if (xlim.flag){
          xlim <- base::range(data$time[data$id==i],na.rm=T)
          if(abs(xlim[1])==Inf | abs(xlim[2])==Inf) xlim <- base::range(data$time,na.rm=T)
        }
        if (ylim.flag){
          ylim <- base::range(data$out[data$id==i],na.rm=T)
          if(abs(ylim[1])==Inf | abs(ylim[2])==Inf) ylim <- base::range(data$out,na.rm=T)
          if(log){ylim[1][ylim[1]==0] <- 0.5*min(data$out[data$id==i],na.rm=T)}
        }
        if (main.flag) main <- paste("ID",i)
        plot(out~time,data=subset(data,data$id==i),xlab=xlab,ylab=ylab,main=main,xlim=xlim,ylim=ylim,log=logplot,type="n",yaxt=yaxt,...)
        if(missing(grid)){
          grid <- list(x=NA,y=NA)
        } else {
          if(inherits(grid,"logical")){
            if(grid){
              grid <- list(x=axTicks(1),y=axTicks(2))
            } else {
              grid <- list(x=NA,y=NA)
            }
          }
          if(inherits(grid,"list")){
            if(is.null(grid$x) | all(!is.na(grid$x))) grid$x <- axTicks(1)
            if(is.null(grid$y) | all(!is.na(grid$y))) grid$y <- axTicks(2)
          }
        }
        
        if(yaxt=="n") logAxis(2,grid=!all(is.na(grid$y)))
        abline(v=grid$x,lty=1,col="lightgray")
        abline(h=grid$y,lty=1,col="lightgray")
        for(j in outeq){
          tempdata <- subset(data,data$id==i & data$outeq==j)
          temppred <- pred[pred$id==i & pred$outeq==j,]
          points(out~time,data=tempdata,type=jointype,pch=pch[j],col=tempdata$col,cex=cex,...)
          if(ebar$plot){add.ebar(x=data$time[data$id==i & data$evid==0 & data$outeq==j],
                                 y=data$out[data$id==i & data$evid==0 & data$outeq==j],
                                 upper=ebar$sd[ebar$id==i & ebar$outeq==j],col=subset(data$col,data$id==i & data$outeq==j))
          }
        }
        if (doses){
          for(k in 1:ndrug){
            x <- data$time[data$id==i & data$input==k & !is.na(data$input)]
            dur <- data$dur[data$id==i & data$input==k & !is.na(data$input)]
            dur[dur<0.01*xlim[2]] <- 0.01*xlim[2]
            ndose <- length(x)
            for (l in 1:ndose){
              xmin <- x[l]
              xmax <- x[l]+dur[l]
              ymin <- ylim[1]
              ymax <- c(ylim[1]+0.1*(ylim[2]-ylim[1]),10**(log10(ylim[1]) + 0.1*log10(ylim[2]/ylim[1])))[1 + as.numeric(log)]
              abline(v=x[l],lty="dotted",lwd=1,col="black")
              polygon(x=c(xmin,xmin,xmax,xmax),y=c(ymin,ymax,ymax,ymin),col=col[k],border=NA)
            }
          }
        }
        if(legend$plot) do.call("legend",legend)
      }
    }   
    devAskNewPage(ask=F)
    
  } else {  #there is overlay
    #predicted suppplied
    if(!is.null(pred)){
      if (xlim.flag) xlim <- base::range(c(data$time,pred$time),na.rm=T)
      if (ylim.flag){
        ylim <- base::range(c(data$out,pred$pred),na.rm=T)
        if(log){ylim[1][ylim[1]==0] <- 0.5*min(data$out,na.rm=T)}
      }
      
      if (main.flag){main <- ""}
      plot(out~time,data=data,xlab=xlab,ylab=ylab,main=main,xlim=xlim,ylim=ylim,log=logplot,type="n",yaxt=yaxt,...)
      if(missing(grid)){
        grid <- list(x=NA,y=NA)
      } else {
        if(inherits(grid,"logical")){
          if(grid){
            grid <- list(x=axTicks(1),y=axTicks(2))
          } else {
            grid <- list(x=NA,y=NA)
          }
        }
        if(inherits(grid,"list")){
          if(is.null(grid$x)) grid$x <- axTicks(1)
          if(is.null(grid$y)) grid$y <- axTicks(2)
        }
      }
      if(yaxt=="n") logAxis(2,grid=!all(is.na(grid$y)))
      abline(v=grid$x,lty=1,col="lightgray")
      abline(h=grid$y,lty=1,col="lightgray")
      for (i in unique(data$id)){
        for(j in outeq){
          tempdata <- subset(data,data$id==i & data$outeq==j)
          temppred <- pred[pred$id==i & pred$outeq==j,]
          if(!ident) {
            points(out~time,data=tempdata,type=jointype,pch=pch[j],col=tempdata$col,cex=cex,...)
          } else {
            lines(out~time,data=tempdata,col=col,...)
            text(out~time,data=tempdata,labels=tempdata$id,col=col,cex=cex,...)
          }
          lines(pred~time,data=temppred,col=temppred$col,...)
          if(ebar$plot){add.ebar(x=data$time[data$id==i & data$evid==0 & data$outeq==j],
                                 y=data$out[data$id==i & data$evid==0 & data$outeq==j],
                                 upper=ebar$sd[ebar$id==i & ebar$outeq==j],col=subset(data$col,data$id==i & data$outeq==j))
          }
        }
      }
      if(legend$plot) do.call("legend",legend)
      
    } else { #there is no predicted
      if (xlim.flag) xlim <- base::range(data$time,na.rm=T)
      if (ylim.flag){
        ylim <- base::range(data$out,na.rm=T)
        if(log){ylim[1][ylim[1]==0] <- 0.5*min(data$out,na.rm=T)}
      }     
      if (main.flag){main <- ""}
      plot(out~time,data=data,xlab=xlab,ylab=ylab,main=main,xlim=xlim,ylim=ylim,log=logplot,type="n",yaxt=yaxt,...)
      if(missing(grid)){
        grid <- list(x=NA,y=NA)
      } else {
        if(inherits(grid,"logical")){
          if(grid){
            grid <- list(x=axTicks(1),y=axTicks(2))
          } else {
            grid <- list(x=NA,y=NA)
          }
        }
        if(inherits(grid,"list")){
          if(is.null(grid$x)) grid$x <- axTicks(1)
          if(is.null(grid$y)) grid$y <- axTicks(2)
        }
      }
      if(yaxt=="n") logAxis(2,grid=!all(is.na(grid$y)))
      abline(v=grid$x,lty=1,col="lightgray")
      abline(h=grid$y,lty=1,col="lightgray")
      for (i in unique(data$id)){
        for(j in outeq){
          tempdata <- subset(data,data$id==i & data$outeq==j)
          if(!ident) {
            points(out~time,data=tempdata,type=jointype,pch=pch[j],col=tempdata$col,cex=cex,...)
          } else {
            lines(out~time,data=tempdata,col=col,...)
            text(out~time,data=tempdata,labels=tempdata$id,col=col,cex=cex,...)
          }
          if(ebar$plot){add.ebar(x=data$time[data$id==i & data$evid==0 & data$outeq==j],
                                 y=data$out[data$id==i & data$evid==0 & data$outeq==j],
                                 upper=ebar$sd[ebar$id==i & ebar$outeq==j],col=subset(data$col,data$id==i & data$outeq==j))
          }
        }
      }
      if(legend$plot) do.call("legend",legend)
    }
  }            
  
  #clean up    
  par(mfrow=c(1,1))
  #close device if necessary
  if(inherits(out,"list")) dev.off()
}



