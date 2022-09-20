oneATT<-function(model_path, data_object, engine, ...){
    IDs <- (data_object$data %>% select(id) %>% distinct())[[1]]
    wd <- getwd()
    system("mkdir oneATT")
    setwd("oneATT")
    for (subject in 1:length(IDs)){
        sub_data <- data_object$data %>% 
                    filter(id == IDs[subject]) %>%
                    PM_data$new()
        Pmetrics::NPrun(model_path, sub_data, intern = T, ...)
    }
    setwd(wd)
}