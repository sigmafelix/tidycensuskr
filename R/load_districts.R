#' Load district boundaries for a specific year
#' @param year The year for which to load district boundaries (2010, 2015, or 2020)
#' @return An `sf` object containing district boundaries for the specified year
#' @importFrom sf st_read
#' @note This function requires the `tidycensuskr.sf` package to be installed.
#' No explicit dependency is defind; but users should install the package following
#' the instructions at vignette('v01_intro') or more succinctly:
#' `install.packages('tidycensuskr.sf', repos = 'https://sigmafelix.r-universe.dev')`
#' @import sf
#' @importFrom rlang is_installed
#' @export
load_districts <- function(year = 2020) {
  if (!year %in% c(2010, 2015, 2020)) {
    stop("Year must be one of 2010, 2015, or 2020")
  }

  if (!rlang::is_installed("tidycensuskr.sf")) {
    stop("Package 'tidycensuskr.sf' is required for this function. Please install it.")
  }
  file_path <- system.file(sprintf("extdata/adm2_sf_%d.rds", year),
    package = "tidycensuskr.sf"
  )

  boundary <- readRDS(file_path)
  boundary
}
