#' Load `sf` district polygons
#' @param year integer(1). census year to load. Defaults to 2020.
#' @return An `sf` object containing the district polygons.
#' @details
#' The function loads district polygons for the specified year from the package's
#' extdata directory. The polygons are stored in an RDS file and are read using
#' the `readRDS` function. The polygons are in the Simple Features (sf) format,
#' which is suitable for spatial data analysis in R. The polygons include following
#' attributes:
#' - `year`: The census year (e.g., 2020).
#' - `adm2_code`: The administrative code for the district.
#' @examples
#' library(sf)
#' sf_use_s2(FALSE)
#' sf_2020 <- load_districts(year = 2020)
#' @import sf
#' @export
load_districts <- function(year = 2020) {
  # Load the district polygons using the sf package
  file_path <- sprintf("adm2_sf_%d.rds", year)

  districts <-
    readRDS(
      system.file("extdata", file_path, package = "tidycensuskr")
    )
  # Return the loaded districts
  return(districts)
}
