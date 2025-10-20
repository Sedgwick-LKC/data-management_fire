## ------------------------------------------------ ##
# Download Data (from Google Drive)
## ------------------------------------------------ ##
# Purpose:
## Wrangle the 'raw' live fuel moisture (LFM) data

# For the code to talk to Drive, you need to tell R who you are (in Google)
## Work through the following tutorial to do so
### https://lter.github.io/scicomp/tutorial_googledrive-pkg.html
## Alternatively, see the help file for the following function:
### `?googledrive::drive_auth`

# Load libraries
# install.packages("librarian")
librarian::shelf(tidyverse, googledrive)

# Get set up
source("00_setup.r")

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Download LFM Data ----
## ----------------------------- ##

# Identify the relevant file in Google Drive
lfm_drive <- googledrive::drive_ls(path = googledrive::as_id("https://drive.google.com/drive/folders/1EOrKk39IppCX9gQ5KWlpO890XGpcgwzg")) %>% 
  dplyr::filter(stringr::str_detect(string = name, pattern = "Live_fuel_moisture"))

# Did that work?
## It did if you see the name of an Excel file when you run the next line
lfm_drive

# Identify the file path we want locally
lfm_path <- file.path("data", "raw", lfm_drive$name)

# Download this file
googledrive::drive_download(file = lfm_drive$id, overwrite = T, path = lfm_path)

# End ----
