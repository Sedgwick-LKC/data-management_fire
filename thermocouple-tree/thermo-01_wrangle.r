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
  purrr::list_rbind(x = .) %>% 
  # Identify numeric logger names
  dplyr::mutate(logger.number = dplyr::case_when(
    plot.title == "one" ~ 1,
    plot.title == "two" ~ 2,
    plot.title == "three" ~ 3,
    plot.title == "four" ~ 4,
    plot.title == "five" ~ 5,
    plot.title == "six" ~ 6,
    plot.title == "seven" ~ 7,
    plot.title == "eight" ~ 8,
    plot.title == "nine" ~ 9,
    plot.title == "ten" ~ 10,
    plot.title == "eleven" ~ 11,
    plot.title == "twelve" ~ 12,
    plot.title == "thirteen" ~ 13,
    plot.title == "fourteen" ~ 14,
    plot.title == "fifteen" ~ 15,
    plot.title == "sixteen" ~ 16), .before = plot.title)

# Check structure
dplyr::glimpse(therm_v01)

## ----------------------------- ##
# Initial Data Wrangling ----
## ----------------------------- ##

# Do some generally-useful tidying
therm_v02 <- therm_v01 %>% 
  # Replace any empty cells with true NAs
  dplyr::mutate(dplyr::across(.cols = dplyr::everything(),
    .fns = ~ ifelse(test = (nchar(.) == 0 | is.na(.)),
    yes = NA, no = .))) %>% 
  # Retain only wanted columns
  dplyr::select(-plot.title, -row.number, -host.connect, -stop, -end.of.file) %>% 
  # Fix column class issues
  dplyr::mutate(dplyr::across(.cols = dplyr::starts_with("port"),
    .fns = as.numeric)) %>% 
  dplyr::mutate(date.time = as.POSIXct(date.time, format = "%m/%d/%y %H:%M:%S"))

# Check structure
dplyr::glimpse(therm_v02)

# What columns are lost?
supportR::diff_check(old = names(therm_v01), new = names(therm_v02))

## ----------------------------- ##
# Reshape Data ----
## ----------------------------- ##

# Need data to be in long format to attach metadata (see below)
therm_v03 <- therm_v02 %>% 
  # Actually reshape data
  tidyr::pivot_longer(cols = dplyr::starts_with("port."),
    names_to = "port", values_to = "temperature_deg.F") %>% 
  # Remove any missing temperature values
  dplyr::filter(!is.na(temperature_deg.F)) %>% 
  # Tweak the 'port' entries to match the metadata
  dplyr::mutate(port = gsub(pattern = "port.", replacement = "thermocouple_", x = port)) %>% 
  # Calculate average temperature (across ports) while we're here
  dplyr::group_by(logger.number, date.time) %>% 
  dplyr::mutate(mean.temperature_deg.F = mean(temperature_deg.F, na.rm = T)) %>% 
  dplyr::ungroup()

# Check structure
dplyr::glimpse(therm_v03)

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
# Initial Metadata Wrangling ----
## ----------------------------- ##

# Do some generally-useful tidying of the metadata
meta_v02 <- meta_v01 %>% 
  # Streamline column names
  dplyr::rename_with(.fn = ~ gsub(pattern = "activity...", replacement = "", x = .)) %>% 
  # Pare down to desired columns
  dplyr::select(-survey.date, -notes, -battery_level) %>% 
  # Make data logger name into true number
  dplyr::mutate(data_logger_name = as.numeric(data_logger_name))

# Check structure
dplyr::glimpse(meta_v02)

## ----------------------------- ##
# Reshape Metadata ----
## ----------------------------- ##

# Need data to be in long format to attach data (see below)
meta_v03 <- meta_v02 %>% 
  # Actually reshape data to long format
  tidyr::pivot_longer(cols = dplyr::starts_with("thermocouple_"), names_to = "port") %>% 
  # Make the 'value' column into the true information
  dplyr::mutate(
    height_cm = dplyr::case_when(
      value %in% c("0_m", "Away") ~ 0,
      value == "50_m" ~ 50,
      value == "DBH" ~ 137), # DBH = diameter at breast height (1.37 m)
    dist.from.tree_cm = ifelse(stringr::str_detect(string = tolower(value), pattern = "away"),
      yes = as.numeric(away_distance), no = 0)
  ) %>% 
  # Ditch superseded 'value' column
  dplyr::select(-value)

# Check structure
dplyr::glimpse(meta_v03)

## ----------------------------- ##
# Join Data & Metadata ----
## ----------------------------- ##

# Integrate useful metadata into data
therm_v04 <- therm_v03 %>% 
  dplyr::left_join(x = ., y = meta_v03, 
    by = c("logger.number" = "data_logger_name", "port")) %>% 
  # Relocate metadata columns to the left
  dplyr::relocate(survey.id:dist.from.tree_cm, .before = logger.number)

# Check structure
dplyr::glimpse(therm_v04)

## ----------------------------- ##
# Export ----
## ----------------------------- ##

# Make a final object
therm_v99 <- therm_v04

# One last structure check
dplyr::glimpse(therm_v99)

# Export this locally
write.csv(x = therm_v99, na = '', row.names = F,
          file = file.path("data", "tidy", "vmp-25_thermocouple-logger-data.csv"))

# End ----
