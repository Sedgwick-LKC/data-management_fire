## ------------------------------------------------ ##
# Live Fuel Moisture - Wrangle
## ------------------------------------------------ ##
# Purpose:
## Wrangle the 'raw' live fuel moisture (LFM) data

# Load libraries
# install.packages("librarian")
librarian::shelf(tidyverse, googledrive)

# Get set up
source("00_setup.r")

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Download Data ----
## ----------------------------- ##

# For the code to talk to Drive, you need to tell R who you are (in Google)
## Work through the following tutorial to do so
### https://lter.github.io/scicomp/tutorial_googledrive-pkg.html
## Alternatively, see the help file for the following function:
### `?googledrive::drive_auth`

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

## ----------------------------- ##
# Load Data ----
## ----------------------------- ##

# What sheets are in the data?
(lfm_tabs <- readxl::excel_sheets(path = lfm_path))

# Separate 'gravimetric' and 'immediate' sheets
grav_tabs <- lfm_tabs[stringr::str_detect(string = lfm_tabs, pattern = "gravi")]
imm_tabs <- lfm_tabs[stringr::str_detect(string = lfm_tabs, pattern = "immediate")]

# Read in the gravimetric tabs
grav_v1 <- readxl::read_excel(path = lfm_path, sheet = grav_tabs)

# Check structure
dplyr::glimpse(grav_v1)

# Read in the immediate tabs too
imm_v1 <- imm_tabs %>% 
  purrr::map(.f = ~ readxl::read_excel(path = lfm_path, sheet = .x)) %>% 
  dplyr::bind_rows()

# Check structure
dplyr::glimpse(imm_v1)

## ----------------------------- ##
# Fix Column Names ----
## ----------------------------- ##

# Do needed repairs
grav_v2 <- grav_v1 %>% 
  # Need to remove spaces in column names
  dplyr::rename_with(.fn = ~ gsub(pattern = " ", replacement = ".", x = .)) %>% 
  # Also change symbols into words
  dplyr::rename_with(.fn = ~ gsub(pattern = "%", replacement = "percent", x = .))
  
# Re-check structure
dplyr::glimpse(grav_v2)

# Do the same edits for the other table
imm_v2 <- imm_v1 %>% 
  dplyr::rename_with(.fn = ~ gsub(pattern = " ", replacement = ".", x = .)) %>% 
  dplyr::rename_with(.fn = ~ gsub(pattern = "%", replacement = "percent", x = .))

# Re-check structure
dplyr::glimpse(imm_v2)

## ----------------------------- ##
# Combine Types of LFM ----
## ----------------------------- ##

# Combine the 


## ----------------------------- ##
# Export ----
## ----------------------------- ##


# End ----
