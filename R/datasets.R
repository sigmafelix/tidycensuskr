#' South Korean Census in year 2015 and 2020
#'
#' Census by sigungu.
#'
#' @format A data frame with 253 rows and 11 variables:
#' \describe{
#'   \item{adm1_code}{Code of the province-level (Sido) administrative unit, as defined by KOSIS (Korean Statistical Information Service)}
#'   \item{adm1_name}{Name of the province-level (Sido) administrative unit, as defined by KOSIS}
#'   \item{adm2_code}{Code of the municipal-level (Sigungu) administrative unit, as defined by KOSIS; nested within adm1}
#'   \item{adm2_name}{Name of the municipal-level (Sigungu) administrative unit, as defined by KOSIS}
#'   \item{pop2015_total}{Total population according to the 2015 Census}
#'   \item{pop2015_men}{Male population according to the 2015 Census}
#'   \item{pop2015_women}{Female population according to the 2015 Census}
#'   \item{pop2020_total}{Total population according to the 2020 Census}
#'   \item{pop2020_men}{Male population according to the 2020 Census}
#'   \item{pop2020_women}{Female population according to the 2020 Census}
#' }
#' @source KOSIS
#' @keywords datasets
"census"


#' South Korea Census Data
#'
#' District level data including tax, population, business entities, and mortality in South Korea.
#'
#' @format A data frame with 4410 rows and 9 variables:
#' \describe{
#'   \item{adm1}{Name of the province-level (Sido) administrative unit}
#'   \item{adm2}{Name of the district/municipal-level (Sigungu) administrative unit}
#'   \item{adm2_code}{Code of the district/municipal-level (Sigungu) administrative unit}
#'   \item{type}{Type of variable, e.g., "tax", "population", "mortality"}
#'   \item{class1}{First-level classification of the variable depending on the type}
#'   \item{class2}{Second-level classification of the variable depending on the type}
#'   \item{unit}{Unit of measurement for the variable}
#'   \item{value}{Value of the variable}
#'   \item{year}{Year of the census data, e.g., 2010, 2015, or 2020}
#' }
#' @note
#' For temporal comparison, province names in adm1 field are
#' standardized to the common names with no suffix in metropolitan cities
#' and "-do" suffix in provinces.
#' For example, "Seoul" instead of "Seoul Metropolitan City",
#' and "Jeollabuk-do" instead of "Jeonbuk State".
#' @source
#' * KOSIS (Korean Statistical Information Service)
#' @keywords datasets
"censuskor"