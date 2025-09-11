#' Query Korean census data by admin code (province or municipality) and year
#' @description The function queries a long format census data frame
#' ([`censuskor`]) for specific administrative codes (if provided)
#' @param codes integer or character vector of admin codes (e.g. 11, 26)
#'   or admin names (e.g. "Seoul").
#' @param type character(1). "population", "tax", "economy", "mortality",
#'   or "housing".
#'   Defaults to "population".
#' @param year  integer(1). One of 2010, 2015, or 2020.
#' @param level character(1). "adm1" for province-level or
#'   "adm2" for municipal-level. Defaults to "adm2".
#' @return A data.frame object containing census data
#'   for the specified codes and year.
#' @examples
#' anycensus(codes = "21", type = "mortality")
#' @importFrom dplyr filter mutate
#' @importFrom tidyr pivot_wider
#' @importFrom utils data
#' @export
anycensus <- function(year  = 2020,
                       codes = NULL,
                       type  = c("population", "tax", "mortality", "economy", "housing"),
                       level = c("adm1", "adm2")) {
  censuskor <- NULL
  .data <- NULL
  data("censuskor", package = "tidycensuskr", envir = environment())
  type     <- match.arg(type)
  level    <- match.arg(level)
  df       <- censuskor

  unit <- NULL

  # check if all codes are convertible to integer
  suppressWarnings(
    cond_chr <- all(is.na(as.integer(codes)))
  )

  # name search is supported only for adm1 level
  if (cond_chr) {
    query_col <- "adm1"
  } else {
    # code search
    query_col <- "adm2_code"
    stopifnot(nchar(codes) == 2)
  }

  # Default NULL codes: all admx codes are used
  if (is.null(codes)) {
    codes <- unique(df[[query_col]])
  } else {
    codes <- as.character(codes)
    if (cond_chr) {
      codes <- unique(df[[query_col]][df[[query_col]] %in% codes])
    } else {
      codes <- as.integer(codes)
    }
  }
  dfe <- df[
    df[["year"]] == year & df[["type"]] == type,
  ] |>
    dplyr::filter(
      grepl(
        sprintf(
          "^(%s)",
          paste(codes, collapse = "|")
        ),
        .data[[query_col]]
      ) | .data[[query_col]] %in% codes
    )

  # post-processing when levels are multiple
  dfe <- dfe |>
    dplyr::mutate(
      unit = abbreviate(unit, minlength = 3)
    ) |>
    tidyr::pivot_wider(
      names_from = c("class1", "class2", "unit"),
      values_from = "value"
    )
  # clean up the column names
  names(dfe) <- gsub(
    pattern = "_NA",
    replacement = "",
    perl = TRUE,
    x = names(dfe)
  )
  dfe
}
