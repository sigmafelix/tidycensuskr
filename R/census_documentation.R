#' South Korean Census in year 2015 and 2020
#'
#' Census by sigungu.
#'
#' @format A data frame with {253} rows and {11} variables:
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
#' @source \url{data_URL}
"census"
