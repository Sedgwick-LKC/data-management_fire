## ------------------------------------------------ ##
# Live Fuel Moisture - Graph
## ------------------------------------------------ ##
# Purpose:
## Create a graph of LFM by species over time (for the website)

# Load libraries
# install.packages("librarian")
librarian::shelf(tidyverse, lubridate)

# Get set up
source("00_setup.r")

# Clear environment
rm(list = ls()); gc()

## ----------------------------- ##
# Load Data ----
## ----------------------------- ##

# Identify the local data file
(lfm_file <- dir(path = file.path("data", "tidy"), pattern = "live-fuel"))

# Read it in!
## The "[1]" just means we only take the first if there is more than one version found locally
lfm_v1 <- read.csv(file = file.path("data", "tidy", sort(lfm_file)[1]))

# Check structure
dplyr::glimpse(lfm_v1)

## ----------------------------- ##
# Prepare for Graphing ----
## ----------------------------- ##

# Do needed pre-graphing stuff
lfm_v2 <- lfm_v1 %>% 
  # Pare down to only needed columns
  dplyr::select(Date, Site, Species, RH, Temp_F, Moisture_content) %>% 
  # Drop non-unique rows (there are duplicates of moisture content for the two bottles)
  dplyr::distinct() %>% 
  # Make dates 'real' and tweak the format
  dplyr::mutate(Date = as.Date(Date)) %>% 
  # Transform moisture into a percent by multiplying by 100
  dplyr::mutate(Moisture = Moisture_content * 100) %>% 
  # Keep only rows with all needed data
  dplyr::filter(dplyr::if_all(.cols = dplyr::everything(),
                              .fns = ~ !is.na(.)))

# Check structure
dplyr::glimpse(lfm_v2)

## ----------------------------- ##
# Make Graph ----
## ----------------------------- ##

# Define some nicer colors
spp_colors <- c("Purple Sage" = "#9d4edd",
                "California Sagebrush" = "#a7c957",
                "Blue Oak" = "#0077b6",
                "Coast Live Oak" = "#3a5a40")

# And some species-specific shapes
spp_shapes <- c("Purple Sage" = 21,
                "California Sagebrush" = 22,
                "Blue Oak" = 24,
                "Coast Live Oak" = 25)

# Actually graph moisture over time by species
ggplot(data = lfm_v2, aes(x = Date, y = Moisture)) +
  geom_line(aes(color = Species)) + 
  geom_point(aes(fill = Species, shape = Species)) +
  # Add horizontal lines for key threshold LFM values
  geom_hline(yintercept = 60, lwd = 0.5, linetype = 2) +
  geom_hline(yintercept = 79, lwd = 0.5, linetype = 2, color = 'red') +
  # Tweak theme elements
  labs(y = "Live Fuel Moisture (%)", x = "Date") +
  scale_x_date(date_breaks = "3 months") +
  scale_color_manual(values = spp_colors) +
  scale_fill_manual(values = spp_colors) +
  scale_shape_manual(values = spp_shapes) +
  theme_classic(base_size = 16) +
  theme(legend.position = "top", 
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title.x = element_blank())

# Get a nice file name for this
(plot_name <- paste0("live-fuel-moisture_scatterplot_", 
                     min(year(lfm_v2$Date)), "-", max(year(lfm_v2$Date)),
                     "_made-", Sys.Date(),
                     ".png"))

# Export locally
ggsave(filename = file.path("graphs", plot_name),
       height = 6, width = 10, units = "in")

# End ----
