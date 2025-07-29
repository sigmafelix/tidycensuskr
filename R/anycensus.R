#' Query Korean census data by admin code (province or municipality) and year
#'
#' @param codes Integer or character vector of admin codes (e.g. 11, 26) or admin names (e.g. "Seoul").
#' @param year  Integer: one of 2015 or 2020.
#' @param level Character: "adm1" for province-level or "adm2" for municipal-level. Defaults to "adm2".
#' @return A named list of tibbles, one element per requested code.
#' @export
anycensus <- function(codes = NULL,
                      year  = 2020,
                      level = c("adm1", "adm2"),
                      simplify = c("auto", "list", "df")) {
  simplify <- match.arg(simplify)
  level    <- match.arg(level)
  df       <- census

  stopifnot(year %in% c(2015, 2020))

  code_col_str <- paste0(level, "_code")
  name_col_str <- paste0(level, "_name")
  pop_col_str  <- paste0("pop", year, "_total")

  df2 <- df |>
    dplyr::select(
      code       = .data[[code_col_str]],
      name       = .data[[name_col_str]],
      population = .data[[pop_col_str]]
    ) |>
    (\(d) {
      if (!is.null(codes))
        dplyr::filter(d, code %in% as.integer(codes) | name %in% codes)
      else
        d
    })()

  out_list <- split(df2, df2$code)

  # 여러 개도 단일 df로 합치기, or 원래대로 list, 한 개면 df, 여러 개면 list
  if (simplify == "df") {
    return(dplyr::bind_rows(out_list, .id = "code"))
  }
  if (simplify == "auto") {
    if (length(out_list) == 1) return(out_list[[1]])
    else                       return(out_list)
  }
  out_list
}



#' Query Korean census data by admin code (province or municipality) and year
#'
#' @param codes Integer or character vector of admin codes (e.g. 11, 26) or admin names (e.g. "Seoul").
#' @param type character: "population", "tax", or "mortality". Defaults to "population".
#' @param year  Integer: 2020.
#' @param level Character: "adm1" for province-level or "adm2" for municipal-level. Defaults to "adm2".
#' @return A data.frame object containing census data for the specified codes and year.
#' @examples
#' anycensusk(codes = "21", type = "mortality")
#' @importFrom dplyr filter mutate
#' @importFrom tidyr pivot_wider
#' @export
anycensusk <- function(codes = NULL,
                      type  = c("population", "tax", "mortality"),
                      year  = 2020,
                      level = c("adm1", "adm2")) {
  type     <- match.arg(type)
  level    <- match.arg(level)
  df       <- censuskor

  unit <- NULL

  stopifnot(year %in% c(2020))
  suppressWarnings(
    cond_chr <- all(is.na(as.integer(codes)))
  )

  if (cond_chr) {
    query_col <- "adm1"
  } else {
    query_col <- "adm2_code"
    stopifnot(nchar(codes) == 2)
  }

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
      grepl(sprintf("^(%s)", paste(codes, collapse = "|")), .data[[query_col]]) |
      .data[[query_col]] %in% codes
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

