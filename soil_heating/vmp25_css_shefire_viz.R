#Visualize and fit a regression model to soil temperature profile data collected 
#in prescribed burns (3 ibuttons mounted in a wooden stake) using 
# the SheFire measurement system and analysis package https://doi.org/10.1002/eap.2627
#
library(librarian)
librarian::shelf(tidyverse, googledrive)
library(SheFire)
#library(ggplot2)
library(SheFire)
library(tidyverse)
library(lubridate)
##-----------------##
#Get soil temperature data from shared google drive, grabbing one location at a time.
#Could be looped across all files but prefer to examine one location at a time
##-----------------##
##location SRA80 point 2, create output directory before proceeding - graphs/shefire/sra80/p2
#get SRA80 soil temp files
sra80_soil_temp_files <- googledrive::drive_ls(googledrive::as_id("https://drive.google.com/drive/u/2/folders/10OvZnpF-VQDEZJt6i3nGhCu7sscfEN-f?role=writer"), pattern = "csv") |> 
  dplyr::filter(stringr::str_detect(string = name, pattern = "sra80_css"))
#
  soiltemp_path <- file.path("data","fire","soil_temps")
  #
  for(i in c(1:nrow(sra80_soil_temp_files))){
  googledrive::drive_download(file = sra80_soil_temp_files[i,]$id, overwrite = T,
                              path = file.path(soiltemp_path,sra80_soil_temp_files[i,]$name))
  }

##-----------------##
#read in csv files, reformat date field, and extract 12 hours (2 before and 10 after max at 5 cm)
##-----------------##
sra80_file_paths <- list.files(path = "data/fire/soil_temps", pattern = "\\.csv$", full.names = TRUE)
  #
#read point_2 without header lines, name columns, format date and time
#could loop this
  d5 <- read_csv(sra80_file_paths[6],skip=20) #read in point, 5 cm ibutton first
      names(d5) <- c("Date.Time","unit","value") 
      d5$Date.Time <- as.POSIXct(d5$Date.Time, format = "%m/%d/%y %I:%M:%S %p")
  d10 <- read_csv(sra80_file_paths[4],skip=20)
      names(d10) <- c("Date.Time","unit","value") 
      d10$Date.Time <- as.POSIXct(d10$Date.Time, format = "%m/%d/%y %I:%M:%S %p")
  d15 <- read_csv(sra80_file_paths[5],skip=20)
      names(d15) <- c("Date.Time","unit","value")
      d15$Date.Time <- as.POSIXct(d15$Date.Time, format = "%m/%d/%y %I:%M:%S %p")
#get time of maximum temp at 5 cm - will use this to set data window
  time_maxt <- d5[which.max(d5$value),]
  start_time <- time_maxt$Date.Time - 2*3600 #start 2 hours before burning
  end_time <- time_maxt$Date.Time + 8*3600 #end 8 hours after burning begins
#extract and format ibutton data for shefire analysis window
    Date.Time <- d5[d5$Date.Time >= start_time & d5$Date.Time < end_time,1] #200 x 1
    Temp_S <- d5[d5$Date.Time >= start_time & d5$Date.Time < end_time,3] #200
    Temp_M <- d10[d10$Date.Time >= start_time & d10$Date.Time < end_time,3] #200
    Temp_D <- d15[d15$Date.Time >= start_time & d15$Date.Time < end_time,3] #200
  #reformat for shefire
    TimeCounter <- c(1:nrow(dat5)) * 3 #time in minutes beginning at 3 minutes
    shedat <- cbind(Date.Time,TimeCounter,Temp_S,Temp_M,Temp_D)
    names(shedat) <- c("Date.Time","TimeCounter","Temp_S","Temp_M","Temp_D")
  #write data file with appropriate sample name
    write.csv(shedat,"data/fire/soil_temps/shefire/input_data/shedat_css_sra80_p2.csv")
    
##-------------##
#shefire analysis
##-------------##
#save output files
  shefire_css_sra80 <- shefire(shedat,
                            sensor.depths=c(5,10,15),
                            #cutoff=c(1500),
                            #regression="F",
                            time.buffer=c(5),
                            print.plots.tables=T,
                            save.plots.tables=T,
                            save.directory="graphs/shefire/sra80/p2")
  
  ###note that shefire resets the working directory to the output directory 
  #End ----

