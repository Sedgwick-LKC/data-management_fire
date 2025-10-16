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

# Grab just the 'gravimetric' sheet(s)
grav_tabs <- lfm_tabs[stringr::str_detect(string = lfm_tabs, pattern = "gravi")]

# Read in the gravimetric tabs
grav_v1 <- grav_tabs %>% 
  purrr::map(.f = ~ readxl::read_excel(path = lfm_path, sheet = .x)) %>% 
  dplyr::bind_rows() %>% 
  dplyr::mutate(type = "gravimetric", .before = dplyr::everything())

# Check structure
dplyr::glimpse(grav_v1)

## ----------------------------- ##
# Fix Column Names ----
## ----------------------------- ##

# Do needed repairs to column names
grav_v2 <- grav_v1 %>% 
  # Need to remove spaces in column names
  dplyr::rename_with(.fn = ~ gsub(pattern = " ", replacement = ".", x = .)) %>% 
  # Also change symbols into words
  dplyr::rename_with(.fn = ~ gsub(pattern = "%", replacement = "percent", x = .))
  
# Re-check structure
dplyr::glimpse(grav_v2)

## ----------------------------- ##
# Fix Datetime Columns ----
## ----------------------------- ##

# Fix the date times
grav_v3 <- grav_v2 %>%
  # Strip out just the time part of the time columns
  ## GoogleSheets added a bizarre date in the 19th century that we want to ditch
  dplyr::mutate(
    dplyr::across(.cols = dplyr::ends_with(".time"),
                  .fns = ~ stringr::str_extract(string = .,
                                                pattern = "[:digit:]{2}:[:digit:]{2}:[:digit:]{2}"))) %>% 
  # Fix a malformed year in some of the dates
  dplyr::mutate(Date = as.Date(gsub(pattern = "2924", replacement = "2024", x = Date)))

# Re-check structure
dplyr::glimpse(grav_v3)

## ----------------------------- ##
# Fix Text Columns ----
## ----------------------------- ##

# Need to some general standardization for maximum machine readability
grav_v4 <- grav_v3 %>% 
  # Standardize delimeter between entries in 'Persons' column
  dplyr::mutate(Persons = dplyr::case_when(
    ## Remove spaces but keep commas (where both are present)
    stringr::str_detect(string = Persons, pattern = ", ") ~ gsub(pattern = ", ",
                                                                 replacement = ",",
                                                                 x = Persons),
    ## Replace spaces with commas (where this is no comma to start with)
    stringr::str_detect(string = Persons, pattern = " ") ~ gsub(pattern = " ",
                                                                 replacement = ",",
                                                                 x = Persons),
    ## Otherwise, keep the original entry
    T ~ Persons)) %>% 
  # Get a separate species code & species name column
  dplyr::rename(Species.Code = Species) %>% 
  dplyr::mutate(Species = dplyr::case_when(
    Species.Code == "ARCA" ~ "California Sagebrush", # Artemisia californica
    Species.Code == "SALE" ~ "Purple Sage", # Salvia leucophylla
    Species.Code == "QUAG" ~ "Coast Live Oak", # Quercus agrifolia
    Species.Code == "QUDO" ~ "Blue Oak"), # Quercus douglasii
    .after = Species.Code)

# Check structure
dplyr::glimpse(grav_v4)

## ----------------------------- ##
# Fix Numeric Columns ----
## ----------------------------- ##

# Identify all columns that _should_ be numeric
grav_num_cols <- c("RH", "Temp_F", "CC", "Bottle.weight_grams",
                   "Bottle_SampleWET_weight", "Wet.weight", 
                   "Wet.weight.total", "Bottle_SampleDRY_weight", 
                   "dry.bag", "Dry.weight", "Dry.weight.total", 
                   "Moisture_content")

# Check for non-numbers in those columns
supportR::num_check(data = grav_v4, col = grav_num_cols)

# Do needed repairs
grav_v5 <- grav_v4 %>% 
  # Fix non-numbers in "CC" column
  dplyr::mutate(Notes = ifelse(CC == "<5%",
                               yes = paste(Notes, '; True CC was "<5%" but replaced with 2.5 so that column is numeric'), 
                               no = Notes),
                CC = dplyr::case_when(
                  CC == "<5%" ~ "2.5",
                  CC == "none" ~ "0",
                  T ~ CC)) %>% 
  # Replace notes with true NAs
  dplyr::mutate(dplyr::across(.cols = dplyr::contains(c("weight")),
                              .fns = ~ gsub(pattern = "forgot bottle|na",
                                            replacement = NA, x = .)))

# Re-check for non-numbers
supportR::num_check(data = grav_v5, col = grav_num_cols)

# Actually coerce number columns into numbers!
grav_v6 <- grav_v5 %>% 
  dplyr::mutate(dplyr::across(.cols = dplyr::all_of(grav_num_cols),
                              .fns = as.numeric))

# General structure check
dplyr::glimpse(grav_v6)

## ----------------------------- ##
# Calculate Metrics ----
## ----------------------------- ##

# Some columns were calculated in Drive,
## We should ditch them and re-calculate here for reproducibility's sake
grav_v7 <- grav_v6 %>% 
  # Remove calculated columns
  dplyr::select(-Wet.weight, -Wet.weight.total,
                -Dry.weight, -Dry.weight.total,
                -Moisture_content) %>% 
  # Re-calculate bottle-specific metrics
  dplyr::mutate(
    ## Wet weight (g)
    Wet.weight = (Bottle_SampleWET_weight - Bottle.weight_grams),
    ## Dry weight (g)
    ## Rows with a "dry.bag" value get calculated slightly differently
    Dry.weight = ifelse(is.na(dry.bag) == T,
                        yes = (Bottle_SampleWET_weight - Bottle_SampleDRY_weight),
                        no = (Bottle_SampleDRY_weight - dry.bag))
  ) %>% 
  # Re-calculate metrics calculated across bottles
  dplyr::group_by(Date, Site, Species) %>% 
  dplyr::mutate(
    Wet.weight.total = sum(Wet.weight, na.rm = T),
    Dry.weight.total = sum(Dry.weight, na.rm = T)
  ) %>% 
  dplyr::ungroup() %>% 
  # Finally, calculate moisture content
  dplyr::mutate(Moisture_content = (Wet.weight.total - Dry.weight.total) / Dry.weight.total) %>% 
  # And relocate columns to original order
  dplyr::relocate(dplyr::starts_with("Wet.weight"), .after = Bottle_SampleWET_weight) %>% 
  dplyr::relocate(dplyr::starts_with("Dry.weight"), .after = dry.bag) %>% 
  dplyr::relocate(Moisture_content, .before = Notes)

# Check that we didn't inadvertently lose/gain any columns
supportR::diff_check(old = names(grav_v6),
                     new = names(grav_v7))

# Check structure
dplyr::glimpse(grav_v7)

## ----------------------------- ##
# Export ----
## ----------------------------- ##

# Make a final object
grav_v99 <- grav_v7

# One last structure check
dplyr::glimpse(grav_v99)

# Get a nice file name for this
(grav_name <- paste0("live-fuel-moisture_", 
                     min(year(grav_v99$Date)), "-", max(year(grav_v99$Date)),
                     "_updated-", Sys.Date(),
                     ".csv"))

# Export this locally
write.csv(x = grav_v99, na = '', row.names = F,
          file = file.path("data", "tidy", grav_name))

# End ----
