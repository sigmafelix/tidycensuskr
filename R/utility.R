#' Detect adm2 type from adm2_code field then return the exact codes
#'
#' adm2_code often refers to the codes of autonomous _Gu_s or
#' non-autonomous _Gu_s. The head table of the data frame may contain
#' either or both of the two types of codes. This function detects the type of
#' the codes in the adm2_code field and returns the exact codes accordingly.
#'
#' @param df A head data frame containing the full dataset.
#'   i.e., `censuskor`
#' @param year The year for which to filter the data.
#'   If not specified, the function will use the data.frame as is.
#' @param mode A character vector of "atn" (autonomous) and
#'   "non" (non-autonomous).
#' @param adm2_code A character vector of adm2_code field
#'   Default is "adm2_code".
#' @return filtered data frame with exact codes
#' @examples
#' # Load 2020 census population
#' pop20 <- anycensus(year = 2020, type = "population")
#' pop20_nonauto <- detect_adm2_type(pop20, mode = "non")
#' pop20_auto <- detect_adm2_type(pop20, mode = "atn")
#' unique(pop20_nonauto$adm2_code)
#' unique(pop20_auto$adm2_code)
#' @export
detect_adm2_type <-
  function(
    df,
    year = NULL,
    mode = "non",
    adm2_code = "adm2_code"
  ) {
    match.arg(mode, c("atn", "non"))
    if (!is.null(year)) {
      df <- df[df$year == year, ]
    }

    # adm2_code values always consist of five digits
    adm2_nonauto_flag <- substr(df[[adm2_code]], 5, 5) != "0"
    if (sum(adm2_nonauto_flag) > 0) {
      # check if auto vs nonauto all match
      adm2_nonauto <- unique(df[adm2_nonauto_flag, ][[adm2_code]])
      adm2_nonauto_upper <- substr(adm2_nonauto, 1, 4)
      adm2_nonauto_upper_str <- paste0(adm2_nonauto_upper, "0")
      adm2_auto <- df[df[[adm2_code]] %in% adm2_nonauto_upper_str, ]
      adm2_auto_upper <- substr(unique(adm2_auto[[adm2_code]]), 1, 4)
      adm2_auto_upper_str <- paste0(adm2_auto_upper, "0")
      if (mode == "atn") {
        filtered_df <- df[!adm2_nonauto_flag, ]
      }
      if (mode == "non") {
        auto_nonauto_cond <- adm2_nonauto_upper %in% adm2_auto_upper
        if (!all(auto_nonauto_cond)) {
          warning(
            "Inconsistent codes: Some non-autonomous Gu codes ",
            "do not have corresponding upper level administrative codes."
          )
        }
        filtered_df <- df[!df[[adm2_code]] %in% adm2_auto_upper_str, ]
      }
      return(filtered_df)
    }

    return(df)
  }
