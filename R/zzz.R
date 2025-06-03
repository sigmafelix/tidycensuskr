###
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    sprintf("tidycensuskr %s (%s)", utils::packageVersion(pkgname), Sys.Date())
  )
}


#' Set KOSIS API Key from a File
#'
#' @param file A character string specifying the path to the file containing the KOSIS API key.
#' @return NULL
#' @export
#' @description This function reads a KOSIS API key from a specified file and sets it for use in KOSIS API calls.
#' @details The file should contain the API key as a single line of text. If the file does not exist, an error will be raised.
#' @importFrom kosis kosis.setKey
set_kosis_key <- function(file) {
  # Check if the file exists
  if (!file.exists(file)) {
    stop("The specified file does not exist.")
  }

  # Read the key from the file
  key <- readLines(file, warn = FALSE)

  # Set the KOSIS key
  kosis::kosis.setKey(key[1])

  message("KOSIS key has been set successfully.")
}



#' Statistics types list
#'
#' @details This package provides a list of statistics types:
#' - `population`: Population statistics fro KOSIS.
#' @concept Documentation
#' @keywords docs


#' Load `sf` district polygons
#'
#' @param ... Additional arguments passed to the `sf` function.
#' @return An `sf` object containing the district polygons.
#' @export
load_districts <- function(crs = NULL) {
  # Load the district polygons using the sf package
  load(system.file("extdata", "sgg2020.RData", package = "habit"))
  if (!is.null(crs)) {
    # Transform the CRS if specified
    districts <- sf::st_transform(sf_sgg_2020, crs)
  } else {
    districts <- sf_sgg_2020
  }

  # Return the loaded districts
  return(districts)
}