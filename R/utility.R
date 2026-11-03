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
#'   If not specified, each year in the data frame is processed separately.
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
    mode <- match.arg(mode, c("atn", "non"))
    if (!is.null(year)) {
      df <- df[df$year == year, ]
    }

    # Compare parents and non-autonomous districts within the same year.
    groups <- if ("year" %in% names(df)) {
      split(seq_len(nrow(df)), match(df$year, unique(df$year)))
    } else {
      list(seq_len(nrow(df)))
    }
    keep <- rep(FALSE, nrow(df))
    for (indices in groups) {
      codes <- df[[adm2_code]][indices]
      nonauto <- substr(codes, 5, 5) != "0"
      if (!any(nonauto)) {
        keep[indices] <- TRUE
      } else if (mode == "atn") {
        keep[indices] <- !nonauto
      } else {
        parents <- paste0(substr(unique(codes[nonauto]), 1, 4), "0")
        present_parents <- parents[parents %in% codes]
        if (!all(parents %in% present_parents)) {
          warning(
            "Inconsistent codes: Some non-autonomous Gu codes ",
            "do not have corresponding upper level unit codes."
          )
        }
        keep[indices] <- !codes %in% present_parents
      }
    }

    df[keep, , drop = FALSE]
  }
