#' Installation of the companion data package
#'
#' tidycensuskr will work at its full potential with the companion data package
#' tidycensussfkr, which contains the district boundaries of South Korea.
#' The package can be installed from R-universe:
#'
#' `install.packages("tidycensussfkr", repos = "https://sigmafelix.r-universe.dev")`
#'
#' After installing the companion package, three RDS files for 2010, 2015, and
#' 2020 will be accessible through the function `system.file()`. For example,
#' the RDS file path of the 2010 district boundaries can be loaded as follows:
#'
#' `fs10 <- system.file("extdata", "adm2_sf_2010.rds", package = "tidycensussfkr")`
#'  `adm2_sf_2010 <- readRDS(fs10)`
#'
#' @source
#' * KOSIS (Korean Statistical Information Service)
#' @keywords guide
"install_companion"