#' Query Korean census data by admin code (province or municipality) and year
#' @description The function queries a long format census data frame
#' ([`censuskor`]) for specific administrative codes (if provided)
#' @param codes integer vector of admin codes (e.g. `c(11, 26)`)
#'   or character administrative area names (e.g. `c("Seoul", "Daejeon")`).
#' @param type character(1). "population", "housing", "tax", "economy",
#'   "medicine", "migration", "environment" or "mortality"
#'   Defaults to "population".
#' @param year  integer(1). One of 2010, 2015, or 2020.
#' @param level character(1). "adm1" for province-level or
#'   "adm2" for municipal-level. Defaults to "adm2".
#' @param aggregator function to aggregate values when `level = "adm1"`.
#' @param ... additional arguments passed to the `aggregator` function.
#'   (e.g., `na.rm = TRUE`).
#' @note Using characters in `codes` has a side effect of returning
#'   all rows in the dataset that match year and type.
#'   The 'wide' table is returned with separate columns for each
#'   `class1` and `class2` and `unit` (abbreviated whereof) combination.
#' @return A data.frame object containing census data
#'   for the specified codes and year.
#' @examples
#' # Query mortality data for adm2_code 21 (Busan)
#' anycensus(codes = 21, type = "mortality")
#'
#' # Query population data for adm1 "Seoul" or "Daejeon"
#' anycensus(codes = c("Seoul", "Daejeon"), type = "housing", year = 2015)
#'
#' # Aggregate to adm1 level tax (province-level) using sum
#' anycensus(
#'   codes = c(11, 23, 31),
#'   type = "tax",
#'   year = 2020,
#'   level = "adm1",
#'   aggregator = sum,
#'   na.rm = TRUE
#' )
#' @importFrom dplyr filter mutate
#' @importFrom tidyr pivot_wider
#' @importFrom utils data
#' @export
anycensus <- function(
  year  = 2020,
  codes = NULL,
  type  = c(
    "population", "housing", "tax", "mortality", "economy",
    "medicine", "migration", "environment", "welfare"
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
  suppressWarnings(try_code_integer <- as.integer(codes))
  try_code_all_alpha <- all(grepl("[A-Za-z]+", codes))
  if (!is_int_code) {
    if (sum(is.na(try_code_integer)) > 0 && !try_code_all_alpha) {
      stop("Mixed types in 'codes' are not allowed.")
    }
    if (all(!is.na(try_code_integer))) {
      message(
        "Using character codes that are convertible to integers. ",
        "Automatically converting to integers..."
      )
      codes <- try_code_integer
      is_int_code <- TRUE
    }
  }

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
