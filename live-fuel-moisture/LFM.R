library(tidyverse)
library(dplyr)
library(lubridate)
library(ggplot2)
##read in raw data
lfm <- read.csv("/Users/kazumdahl/Desktop/Sedgwick/R scripts/LFM_R.csv")
#class(lfm$Date)##date is character: turn to date
#lfm$Date <- as.numeric(lfm$Date)
#lfm$Date = as.Date(lfm$Date, format = "%m/%d%/%Y")
#lfm$Date <- factor(lfm$Date, levels = unique(lfm$Date))
######################
#time series
##mean LFM threshold sits at 60% https://sbcfire.com/wildfire-predictive-services/#:~:text=Sixty%20percent%20of%20live%20fuel,can%20cause%20extreme%20wildfire%20behavior.
#although Dennison and Moritz 2008 say 79% threshold is better for CA https://www.publish.csiro.au/WF/fulltext/WF08055?subscribe=false


##use this
#e <-ggplot(data= lfm) + geom_point(aes(x = Date, y = Moisture, color= Species, group = Species)) +
 # geom_line(aes(x = Date, y = Moisture, color = Species, group = Species)) 
#e+geom_hline(yintercept = 0.6, lwd=0.5, linetype="dashed", color='black') +
 # geom_hline(yintercept = 0.79, lwd=0.5, linetype="dashed", color='red') +
  #labs(title = "Live Fuel Moisture (%) by Species", 
   #    x = "Date",
    #   y = "Live Fuel Moisture (%)") +
#  theme_classic() + scale_y_continuous(breaks = c(0.5, 1, 1.5, 2, 2.5, 3, 3.5))







##### reorder the months
#lfm$Month <- as.factor(lfm$Month)
#lfm$Month <- factor(lfm$Month, c("January","February","March", "April", "May", "June", "July", "August", "September", "October", "November", "December"))
                                     
##FD edit
library(tidyverse)
library(dplyr)
library(lubridate)
library(ggplot2)
#
##read in raw data
#set working directoryt to shared folder with LFM data
  #e.g., setwd("/Users/davis/Library/CloudStorage/GoogleDrive-frank.davis@nceas.ucsb.edu/Shared drives/LaKretz_shared/LKC_FD_KZ/Live_fuel_moisture")
lfm <- read.csv("LFM_R.csv")
lfm$Date <- mdy(lfm$Date)
p1<- ggplot(lfm,aes(x=Date,y=Moisture*100)) +
  geom_line(aes(color=Species)) +
  geom_point(aes(color=Species)) +
  geom_hline(yintercept = 60, lwd=0.5, linetype="dashed", color='black') +
  geom_hline(yintercept = 79, lwd=0.5, linetype="dashed", color='red') +
  labs(title = "Live Fuel Moisture (%)",
       x = "Date",
       y = "Live Fuel Moisture (%)") +
  scale_x_date(date_breaks = "month") +
  theme(axis.text.x = element_text(angle = 90)) +theme_classic(base_size = 16)
#save plot
    p1 +theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
      ggsave("lfm_plot_20251010.png",plot=last_plot(),dpi=300)

