## ------------------------------------------------ ##
# Upload Data (to Google Drive)
## ------------------------------------------------ ##
# Purpose:
## Upload outputs of the code to various parts of the LKC Shared Drive

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

# Identify the relevant local files
(lfm_data <- dir(path = file.path("data", "tidy"), pattern = "live-fuel-moisture"))
(lfm_graphs <- dir(path = file.path("graphs"), pattern = "live-fuel-moisture"))

# Identify link to destination Drive folder
lfm_drive <- googledrive::as_id("")

# # Upload data to that folder
# purrr::walk(.x = lfm_data, .f = ~ googledrive::drive_upload(media = file.path("data", "tidy", .x),
#                                                             overwrite = T, path = lfm_drive))
# 
# # Upload graphs to the folder too
# purrr::walk(.x = lfm_graphs, .f = ~ googledrive::drive_upload(media = file.path("graphs", .x),
#                                                               overwrite = T, path = lfm_drive))

# End ----
