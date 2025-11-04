#' South Korea Census Data
#'
#' District level data including tax, population, business entities,
#' housing, economy, medicine
#' and mortality in South Korea in 2010, 2015, and/or 2020. The availble
#' years and variables depend on the type of data.
#'
#' @format A data.frame with 54218 rows and 10 variables:
#' @details
#' * year Year of the census data, e.g., 2010, 2015, or 2020
#' * adm1 Name of the province-level (Sido) administrative unit
#' * adm1_code Code of the province-level (Sido) administrative unit
#' * adm2 Name of the district/municipal-level (Sigungu) administrative unit
#' * adm2_code  Code of the district/municipal-level (Sigungu) administrative unit
#' * type Type of variable,
#'   e.g., "population", "tax", "mortality", "housing", "medicine", "migration", "environment" or "economy"
#' * class1 First-level classification of the variable depending on the type
#' * class2 Second-level classification of the variable depending on the type
#' * unit Unit of measurement for the variable
#' * value  Value of the variable
#'
#' @note
#' NA values in the value field indicate that the data was omitted
#' or suppressed. We kept these NA values as-is to reflect the
#' original data from the source.
#' For temporal comparison, province names in adm1 field are
#' standardized to the common names with no suffix in metropolitan cities
#' and "-do" suffix in provinces.
#' For example, "Seoul" instead of "Seoul Metropolitan City",
#' and "Jeollabuk-do" instead of "Jeonbuk State".
#' "KRW" in the unit field stands for South Korean Won.
#' Values are as-is unless otherwise noted in the unit field
#' (e.g., "per 100k population" or "million KRW").
#' @source
#' * KOSIS (Korean Statistical Information Service)
#' @keywords datasets
"censuskor"

#' South Korea Census Boundary in 2020
#'
#' District level boundary data in South Korea in 2020. `adm2_code` column
#' can be used to join with an [anycensus()] output.
#'
#' @format A sf object with 250 rows and 3 variables:
#' @details
#' * year Year of the census data, e.g., 2010, 2015, or 2020
#' * adm2_code  Code of the district/municipal-level (Sigungu) administrative unit
#' * geometry Geometry list-column
#'
#' @source
#' * Statistical Geographic Information Service (SGIS)
#' @keywords datasets
"adm2_sf_2020"


#' geofacet Grid for South Korea Administrative Districts (SGIS Standard, 2020)
#'
#' A geofacet grid for South Korea administrative districts (_Si-Gun-Gu_) based on
#' the Statistical Geographic Information Service (SGIS) standard in 2020.
#' Non-autonomous districts in cities are retained as separate entities.
#' This grid can be used with the [geofacet](https://CRAN.R-project.org/package=geofacet)
#' package to create faceted visualizations based on geographic layout.
#'
#' @format A data.frame with 250 rows and 6 variables
#' @details
#' * name Name of the district/municipal-level (Sigungu) administrative unit
#' * code SGIS code of the district/municipal-level (Sigungu) administrative unit
#' * row Row position in the geofacet grid
#' * col Column position in the geofacet grid
#'
#' @source
#' * Statistical Geographic Information Service (SGIS)
#' * GitHub username chichead in [GitHub geofacet issue page](https://github.com/hafen/geofacet/issues/358)
#' @keywords datasets
"kr_grid_adm2_sgis_2020"