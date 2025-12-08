## ------------------------------------------------ ##
# Thermocouples (Tree) - Wrangle
## ------------------------------------------------ ##
# Purpose:
## Wrangle the 'raw' thermocouple data (from trees)

# Load libraries
# install.packages("librarian")
librarian::shelf(tidyverse, supportR, tidyxl)

# Get set up
source("00_setup.r")

# Clear environment
rm(list = ls()); gc()

# Load custom function(s)
purrr::walk(.x = dir(path = file.path("tools"), pattern = "fxn_"),
  .f = ~ source(file = file.path("tools", .x)))

## ----------------------------- ##
# Load Data ----
## ----------------------------- ##

# Identify all of the logger data
(local_therm <- dir(path = file.path("data", "raw"), pattern = "VMP25_logger"))

# Read each of these files in (as a list)
therm_v01 <- purrr::map(.x = local_therm, 
    .f = ~ read_logger(hobo_path = file.path("data", "raw", .x))) %>% 
  # Unlist to a single, big dataframe
  purrr::list_rbind(x = .)

# Check structure
dplyr::glimpse(therm_v01)
sort(unique(therm_v01$plot.title))

## ----------------------------- ##
# Load Metadata ----
## ----------------------------- ##

# Identify all of the wildnote metadata for those loggers
(local_wn.meta <- dir(path = file.path("data", "raw"), pattern = "VMP25_TREX"))

# Read each of these files in (as a list)
meta_v01 <- purrr::map(.x = local_wn.meta, 
    .f = ~ read_wildnote(wn_path = file.path("data", "raw", .x))[["Activity"]]) %>% 
  # Unlist to a single, big dataframe
  purrr::list_rbind(x = .)

# Check structure
dplyr::glimpse(meta_v01)

## ----------------------------- ##

## ----------------------------- ##




# End ----
