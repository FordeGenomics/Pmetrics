oneATT<-function(model, data, engine, ...){
    IDs <- (data$data %>% select(id) %>% distinct())[[1]]
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
    setwd(wd)
    spp
}