#' South Korean Census in year 2015 and 2020
#'
#' Census by sigungu.
#'
#' @format A data frame with {253} rows and {11} variables:
#' \describe{
#'   \item{year}{Census reference year (e.g., 2010, 2015, 2020)}
#'   \item{adm1}{Name of the province-level (Sido) administrative unit, as defined by KOSIS}
#'   \item{adm2}{Name of the municipal-level (Sigungu) administrative unit, as defined by KOSIS}
#'   \item{adm2_code}{Code of the municipal-level (Sigungu) administrative unit, as defined by KOSIS}
#'   \item{type}{Type of census indicator (e.g., 'population')}
#'   \item{class1}{Population breakdown category (e.g., 'total', 'men', 'women')}
#'   \item{class2}{Metric class; 'count' for population totals}
#'   \item{unit}{Unit of measurement (e.g., 'persons')}
#'   \item{value}{Observed value for the indicator}
#' }
#' @source \url{data_URL}
"census"
