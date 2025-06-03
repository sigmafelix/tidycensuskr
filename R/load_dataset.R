#' Load KOSIS dataset
#'
#' @param type Statistics type. e.g., "population", "economy", etc.
#'   See `?stat_types`
#' @param cache Whether to cache the downloaded data. Default is TRUE.
#' @param ... Additional arguments passed to the `kosis` function.
#' @return A data frame containing the dataset.
#' @export
load_dataset <- function(type, cache = TRUE, ...) {
  # Check if the dataset_id is provided
  if (missing(type)) {
    stop("Please provide a dataset type.")
  }

  if (cache) {
    cache_dir <- rappdirs::user_cache_dir("tidycensuskr")
    if (!file.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
  }

  # Load the dataset using the kosis function
  dataset <- do.call(get(sprintf("%s_%s", "load", type)), ...)

  # Return the loaded dataset
  return(dataset)
}



#' Experimental function to load population data from KOSIS
#'
#' @param year The year for which to load the population data.
#' @param cache Whether to cache the downloaded data. Default is TRUE.
#' @return A data frame containing the population data for the specified year.
#' @export
#' @importFrom kosis getStatDataFromURL
#' @importFrom rappdirs user_cache_dir
#' @note This function is experimental and may change in future versions.
#'   It only supports loading raw population data in a single year.
#'   Reference table ID: DT_1IN1509
#' @examples
#' \dontrun{
#' # Load population data for the year 2020
#' population_data <- load_population(2020)
#' }
#' @references
#' - KOSIS
load_population <- function(year, cache = TRUE) {
  # Check if the year is provided
  if (missing(year)) {
    stop("Please provide a year.")
  }

  if (cache) {
    cache_dir <- rappdirs::user_cache_dir("tidycensuskr")
    if (!file.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
  }

  # nolint start
  # Load the population dataset using the kosis function
  dataset <- kosis::getStatDataFromURL(
    sprintf(
      paste0(
        "https://kosis.kr/openapi/Param/statisticsParameterData.do?",
        "method=getList&apiKey=&itmId=T00&",
        "objL1=ALL",
        "&objL2=ALL&objL3=ALL&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&",
        "jsonVD=Y&prdSe=Y&startPrdDe=%d&",
        "endPrdDe=%d&outputFields=ORG_ID+TBL_ID+OBJ_ID+OBJ_NM+OBJ_NM_ENG+",
        "NM+NM_ENG+ITM_ID+ITM_NM+",
        "ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+PRD_SE+PRD_DE+&orgId=101&",
        "tblId=DT_1IN1509"
      ),
      year, year
    )
  )
  # nolint end

  # Return the loaded dataset
  return(dataset)
}


#' Load employment data from KOSIS
#' @param year The year for which to load the employment data.
#' @param cache Whether to cache the downloaded data. Default is TRUE.
#' @return A data frame containing the employment data for the specified year.
#' @export
#' @importFrom kosis getStatDataFromURL
#' @importFrom rappdirs user_cache_dir
#' @note This function is experimental and may change in future versions.
#'  It only supports loading two semiannual period during `year`.
#'  Reference table ID: DT_1ES3A01S
#' @examples
#' \dontrun{
#' # Load employment data for the year 2020
#' employment_data <- load_employment(2020)
#' }
load_employment <- function(year, cache = TRUE) {
  # Check if the year is provided
  if (missing(year)) {
    stop("Please provide a year.")
  }

  if (cache) {
    cache_dir <- rappdirs::user_cache_dir("tidycensuskr")
    if (!file.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
  }

  # Load the employment dataset using the kosis function
  dataset <- kosis::getStatDataFromURL(
    sprintf(
      paste0(
        "https://kosis.kr/openapi/Param/statisticsParameterData.do?",
        "method=getList&",
        "apiKey=&itmId=T1+T2+T3+T4+T9+T5+T6+T7+T11+T8+T10+&",
        "objL1=ALL&",
        "objL2=&objL3=&objL4=&objL5=&objL6=&objL7=&objL8=&",
        "format=json&jsonVD=Y&prdSe=H&startPrdDe=%d01&endPrdDe=%d02&",
        "outputFields=ORG_ID+TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+",
        "NM_ENG+ITM_ID+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+PRD_DE+&",
        "orgId=101&tblId=DT_1ES3A01S"
      ), year, year
    )
  )

  # Return the loaded dataset
  return(dataset)
}
