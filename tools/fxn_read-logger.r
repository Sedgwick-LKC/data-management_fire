#' @title Read CSV in 'Hobo Logger' Format
#' 
#' @description Reads in a CSV presumed to be in 'Hobo Logger' format. This is necessary to retain plot titles (stored by default in a pseudo-header row) as well as do some slightly column renaming.
#' 
#' @param hobo_path (character) File name (and path if needed) for the CSV file in Hobo logger format to read in
#' 
read_logger <- function(hobo_path = NULL){

  # Error checks for 'hobo_path'
  if(is.null(hobo_path) || is.character(hobo_path) != T || length(hobo_path) != 1)
    stop("'hobo_path' must be a file path to a single Excel file")

  # Make sure file actually exists in file path
  if(file.exists(hobo_path) != T)
    stop("File not found at specified file path; check working directory and file name")
  
  # Identify the sheets in this file (can use `readxl` for this)
  hobo_v01 <- readLines(con = hobo_path)

  # Grab the first row (bad header)
  header <- gsub(pattern = '\\\\|\\"|plot title: ',  replacement = "", tolower(hobo_v01[1]))

  # Wrangle the actual table (actually starts in the third row) into something more usable
  hobo_v02 <- data.frame('x' = hobo_v01[-1:-2]) %>% 
    tidyr::separate_wider_delim(cols = "x", delim = ",",
      names = c("row.number", "date.time", "port.a", "port.b", "port.c", "port.d",
      "host.connect", "stop", "end.of.file")) %>% 
    # Add the header back in as a column
    dplyr::mutate(plot.title = header, .before = dplyr::everything())

  # Return the tidied table
  return(hobo_v02) }

# End ----
