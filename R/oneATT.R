#' @export
oneATT<-function(model, data, engine, ...){
    IDs <- (data$data %>% select(id) %>% dplyr::distinct())[[1]]
    wd <- getwd()
    system("rm -rf oneATT")
    system("mkdir oneATT")
    setwd("oneATT")
    spp <- vector(mode = "list", length = length(IDs))
    for (subject in 1:length(IDs)){
        sub_data <- data$data %>% 
                    filter(id == IDs[subject]) %>%
                    PM_data$new()
        model$write("genmodel.txt")
        sub_data$write("gendata.csv")
        Pmetrics::NPrun("genmodel.txt", "gendata.csv", intern = T, ...)
        res <- PM_load(subject)
        spp[[subject]] <- res$final$data$popPoints
    }
    
    txt<-""
    for (index in 1:length(spp)){
        fv <- function(val){paste0(substr(sprintf("%20.18f",val),1,20),paste(rep(" ",8),collapse=""))}
        line <- spp[[index]]
        txt<-paste(txt,fv(line$Ka),fv(line$Ke),fv(line$V),fv(line$Tlag1),"1        \n",collapse="")
    }
    den_file <- readLines("1/outputs/DEN0001")
    den_file[4] <- den_file[4] %>% stringr::str_replace(" 1", as.character(length(IDs)))
    n_param <- as.integer(den_file[5])
    den_file <- den_file[-(15+2*n_param)]
    den_file <- append(den_file,strsplit(txt,"\n")[[1]],14+2*n_param)
    setwd(wd)
    writeLines(den_file,"DEN001")
}

# oneATT(modEx,dataEx)