#' Load district boundaries for a specific year
#' @param year The year for which to load district boundaries (2010, 2015, 2020, or 2025)
#' @param level The administrative level, one of "adm2" and "adm3"
#' @return An `sf` object containing district boundaries for the specified year
#' @importFrom sf st_read
#' @note
#' Other ADM2 years and ADM3 boundaries require the `tidycensuskr.sf` package to be installed.
#' No explicit dependency is defind; but users should install the package following
#' the instructions at vignette('v01_intro') or more succinctly:
#' `install.packages('tidycensuskr.sf', repos = 'https://sigmafelix.r-universe.dev')`
#' @import sf
#' @importFrom rlang is_installed
#' @export
load_districts <- function(year = 2020, level = "adm2") {
  requireNamespace("sf", quietly = TRUE)
  if (!year %in% c(2010, 2015, 2020, 2025)) {
    stop("Year must be one of 2010, 2015, 2020, or 2025")
  }

  if (level == "adm2" && year == 2020) {
    e <- new.env()
    name <- sprintf("adm2_sf_%d", year)
    utils::data(list = name, package = "tidycensuskr", envir = e)
    return(e[[name]])
  }

  if (!rlang::is_installed("tidycensuskr.sf")) {
    stop(
      "Package 'tidycensuskr.sf' is required for this function.",
      "Please install it by running:",
      "install.packages('tidycensuskr.sf', repos = 'https://sigmafelix.r-universe.dev')"
    )
  }
  if (level == "adm2") return(tidycensuskr.sf::load_districts(year))

  file_path <- system.file(sprintf("extdata/%s_sf_%d.rds", level, year),
    package = "tidycensuskr.sf"
  )

  boundary <- readRDS(file_path)
  boundary
}
