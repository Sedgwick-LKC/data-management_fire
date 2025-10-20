## ------------------------------------------------ ##
# Live Fuel Moisture - Wrangle
## ------------------------------------------------ ##
# Purpose:
## Wrangle the 'raw' live fuel moisture (LFM) data

# Load libraries
# install.packages("librarian")
librarian::shelf(tidyverse, supportR)

# Get set up
source("00_setup.r")

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Load Data ----
## ----------------------------- ##

# Identify the most up-to-date file name
lfm_name <- "Live_fuel_moisture_data_sheet_103023.xlsx"

# Identify the file path we want locally
lfm_path <- file.path("data", "raw", lfm_name)

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
  # Fix any issues with site abbreviations
  dplyr::mutate(Site = dplyr::case_when(
    Site == "OQ2" ~ "OW2",
    T ~ Site)) %>% 
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
  ## And note the change in the "Notes column
  dplyr::mutate(Notes = dplyr::case_when(
    CC == "<5%" & is.na(Notes) ~ 'True CC was "<5%" but replaced with "2.5" so that column is numeric',
    CC == "<5%" & is.na(Notes) != T ~ paste(Notes, '; True CC was "<5%" but replaced with "2.5" so that column is numeric'),
    T ~ Notes
  ),
  ## Actually swap the non-number
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
  # Replace 0s in either of those totals with NA (to avoid getting bizarre values later)
  dplyr::mutate(Wet.weight.total = ifelse(Wet.weight.total == 0,
                                          yes = NA, no = Wet.weight.total),
                Dry.weight.total = ifelse(Dry.weight.total == 0,
                                          yes = NA, no = Dry.weight.total)) %>% 
  # Finally, calculate moisture content
  dplyr::mutate(Moisture_content = ifelse(is.na(Wet.weight.total) != T &
                                            is.na(Dry.weight.total) != T,
                                          yes = (Wet.weight.total - Dry.weight.total) / Dry.weight.total, no = NA)
                ) %>% 
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
                     min(year(grav_v99$Date)), "-", max(year(grav_v99$Date))))

# Do you want a date stamp in the file name?
date_file <- FALSE ## Set to TRUE if desired

# Add date stamp (or not) to file name
if(date_file == T){
  grav_name <- paste0(grav_name, "_updated-", Sys.Date(), ".csv")
} else {
  grav_name <- paste0(grav_name, ".csv")
}

# Does the file name look correct?
grav_name

# Export this locally
write.csv(x = grav_v99, na = '', row.names = F,
          file = file.path("data", "tidy", grav_name))

# End ----
