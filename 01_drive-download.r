## ------------------------------------------------ ##
# Download Data (from Google Drive)
## ------------------------------------------------ ##
# Purpose:
## Download 'raw' data from various parts of the LKC Shared Drive

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

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Download Thermocouple (Tree) Data ----
## ----------------------------- ##

# These data make extensive use of sub-folders so we need to identify all of them
therm.tree_links <- c(
  "https://drive.google.com/drive/folders/1Shz3LOhVZlnmSpq2QiGcwvKTMJ2CU3Kz", # 1 
  "https://drive.google.com/drive/folders/1c3hFB6o4oczw4pTxGfu2R6wo4SB59RMY", # 2 
  "https://drive.google.com/drive/folders/1AJ5W-lCQyRpP7tugC55tQfySf_p3FJ66", # 3
  "https://drive.google.com/drive/folders/1I5csW49wSpAIHSuZ0qpaBU_p5t4qdhbr", # 4
  "https://drive.google.com/drive/folders/1tszWRyLCBJhXXCQQdExdrq0drhCUZ5er", # 5
  "https://drive.google.com/drive/folders/1jjur6Wu5jZ5ip04dLr5iu2I3Z9Hqsocn", # 6
  "https://drive.google.com/drive/folders/1Je91pBBl9olwq-rr9QT7mzTSNjOa9_P6", # 7
  "https://drive.google.com/drive/folders/1vP__OX0608cjljfpp2teJZ98Wuq8TBER", # 8
  "https://drive.google.com/drive/folders/1tr1timRnEDn2A6SnX6FA8U0LVcyH0bwO", # 9
  "https://drive.google.com/drive/folders/1TtgxRAN6mXa9j5jX5vgFzAVMepfVluKT", # 10
  "https://drive.google.com/drive/folders/1lC8ytrd0KxTUQ08H3j3rUXIl5_zK83CB", # 11
  "https://drive.google.com/drive/folders/1dzJF12Q62NuNMF47kp0IzRnQj0E69nYi", # 12
  "https://drive.google.com/drive/folders/1SPBUADSbI5tusOHcTk47IV2j3k3UXGjF", # 13
  "https://drive.google.com/drive/folders/13R3Qy-xC2Wj1QaA8VcdfooPq9jr-HVkW", # 14
  "https://drive.google.com/drive/folders/1yduaZqbKzmJoHDJLgVtF4P-lB6XDE2dS", # 15
  "https://drive.google.com/drive/folders/1UQx2WYC5HNM2KPwb-ImKt5d0K3EW8TL8" # 16
  )

# Loop across sub-folders' links
for(focal_therm in therm.tree_links){

  # Identify the relevant file in Google Drive
therm.tree_drive <- googledrive::drive_ls(path = googledrive::as_id(focal_therm)) %>% 
  dplyr::filter(stringr::str_detect(string = name, pattern = "csv"))

# Identify the file path we want locally
therm.tree_path <- file.path("data", "raw", paste0("VMP25_", therm.tree_drive$name))

# Download this file
googledrive::drive_download(file = therm.tree_drive$id, overwrite = T, 
  path = therm.tree_path) }

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Download Thermocouple (Tree) Metadata ----
## ----------------------------- ##

# Identify the relevant files in Google Drive
therm.tree.meta_drive <- googledrive::drive_ls(path = googledrive::as_id("https://drive.google.com/drive/folders/1HxcRI9hndHUwvjn9gETBFreeEA74FlfP")) %>% 
  dplyr::filter(stringr::str_detect(string = name, pattern = "TREX-surveys-Data"))

# Did that work?
## It did if you see the name of an Excel file when you run the next line
therm.tree.meta_drive

# Download these files
purrr::walk2(.x = therm.tree.meta_drive$id, .y = therm.tree.meta_drive$name,
.f = ~ googledrive::drive_download(file = .x, overwrite = T,
  path = file.path("data", "raw", paste0("VMP25_", .y))))

# Clear environment
rm(list = ls()); gc()

# End ----
