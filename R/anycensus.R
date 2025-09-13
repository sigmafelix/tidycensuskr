#' Query Korean census data by admin code (province or municipality) and year
#' @description The function queries a long format census data frame
#' ([`censuskor`]) for specific administrative codes (if provided)
#' @param codes integer vector of admin codes (e.g. `c(11, 26)`)
#'   or character administrative area names (e.g. `c("Seoul", "Daejeon")`).
#' @param type character(1). "population", "housing", "tax", "economy",
#'   or "mortality"
#'   Defaults to "population".
#' @param year  integer(1). One of 2010, 2015, or 2020.
#' @param level character(1). "adm1" for province-level or
#'   "adm2" for municipal-level. Defaults to "adm2".
#' @param aggregator function to aggregate values when `level = "adm1"`.
#' @param ... additional arguments passed to the `aggregator` function.
#'   (e.g., `na.rm = TRUE`).
#' @note Using characters in `codes` has a side effect of returning
#'   all rows in the dataset that match year and type.
#' @return A data.frame object containing census data
#'   for the specified codes and year.
#' @examples
#' anycensus(codes = 21, type = "mortality")
#' anycensus(codes = c("Seoul", "Daejeon"), type = "housing", year = 2015)
#' @importFrom dplyr filter mutate
#' @importFrom tidyr pivot_wider
#' @importFrom utils data
#' @export
anycensus <- function(
  year  = 2020,
  codes = NULL,
  type  = c(
    "population", "housing", "tax", "mortality", "economy"
  ),
  level = c("adm2", "adm1"),
  aggregator = sum,
  ...
) {
  censuskor <- NULL
  .data <- NULL
  data("censuskor", package = "tidycensuskr", envir = environment())
  type     <- match.arg(type)
  level    <- match.arg(level)
  df       <- censuskor

  unit <- NULL
  is_int_code <- all(is.numeric(codes))
  query_col <- if (is_int_code) paste0(level, "_code") else level

  # Default NULL codes: all admx codes are used
  if (is.null(codes)) {
    codes <- unique(df[[query_col]])
  } else {
    codes <- as.character(codes)
    # search for both adm1 and adm2 if level is adm2 and codes are names
    if (!is_int_code && level == "adm2") {
      codes <- unique(
        df[
          grepl(
            sprintf("^(%s)", paste(codes, collapse = "|")),
            gsub(" ", "", df[["adm1"]])
          ),
          "adm1"
        ]
      )
      if (length(codes) == 0) {
        codes <- unique(
          df[
            grepl(
              sprintf("^(%s)", paste(codes, collapse = "|")),
              gsub(" ", "", df[["adm2"]])
            ),
            "adm2"
          ]
        )
      } else {
        query_col <- "adm1"
      }
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
        gsub(" ", "", .data[[query_col]])
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
    x = tolower(names(dfe))
  )
  # if level is adm1, aggregate adm2 to adm1
  if (level == "adm1") {
    dfe <- dfe |>
      dplyr::group_by(
        .data[["year"]], .data[["type"]], .data[["adm1"]], .data[["adm1_code"]]
      ) |>
      dplyr::summarise(
        dplyr::across(
          .cols = -c("adm2", "adm2_code"),
          .fns = aggregator,
          ...
        ),
        .groups = "keep"
      )
  }
  dfe
}
