.collapse_weighted_adm2_to_atn <- function(
  df,
  weight_df,
  weight_column,
  aggregator,
  ...
) {
  adm2_code <- "adm2_code"
  value_columns <- setdiff(
    names(df),
    c("year", "adm1", "adm1_code", "adm2", "adm2_code", "type", weight_column)
  )

  atn_df <- detect_adm2_type(df, mode = "atn")
  atn_weight_df <- detect_adm2_type(weight_df, mode = "atn")

  code_chr <- as.character(df[[adm2_code]])
  parent_code <- paste0(substr(code_chr, 1, 4), "0")
  nonauto <- substr(code_chr, 5, 5) != "0"
  parent_has_atn <- parent_code %in% as.character(atn_df[[adm2_code]])
  nonauto_df <- df[nonauto & parent_has_atn, , drop = FALSE]

  if (nrow(nonauto_df) == 0) {
    return(list(data = atn_df, weights = atn_weight_df[, c(adm2_code, weight_column)]))
  }

  weight_values <- weight_df[, c(adm2_code, weight_column)]
  names(weight_values)[names(weight_values) == weight_column] <- ".aggregation_weight"
  nonauto_df <- dplyr::left_join(nonauto_df, weight_values, by = adm2_code)
  nonauto_df[[".parent_adm2_code"]] <-
    paste0(substr(as.character(nonauto_df[[adm2_code]]), 1, 4), "0")

  parent_codes <- unique(nonauto_df[[".parent_adm2_code"]])
  for (parent in parent_codes) {
    parent_rows <- nonauto_df[nonauto_df[[".parent_adm2_code"]] == parent, , drop = FALSE]
    parent_weights <- parent_rows[[".aggregation_weight"]]
    parent_idx <- match(parent, as.character(atn_df[[adm2_code]]))

    if (is.na(parent_idx)) {
      next
    }

    for (column in value_columns) {
      atn_df[[column]][parent_idx] <- aggregator(
        parent_rows[[column]],
        w = parent_weights,
        ...
      )
    }
  }

  weight_code_chr <- as.character(weight_df[[adm2_code]])
  weight_parent_code <- paste0(substr(weight_code_chr, 1, 4), "0")
  weight_nonauto <- substr(weight_code_chr, 5, 5) != "0"
  weight_parent_has_atn <- weight_parent_code %in% as.character(atn_weight_df[[adm2_code]])
  nonauto_weight_df <- weight_df[weight_nonauto & weight_parent_has_atn, , drop = FALSE]

  collapsed_weights <- atn_weight_df[, c(adm2_code, weight_column)]
  if (nrow(nonauto_weight_df) > 0) {
    nonauto_weight_df[[".parent_adm2_code"]] <-
      paste0(substr(as.character(nonauto_weight_df[[adm2_code]]), 1, 4), "0")

    for (parent in unique(nonauto_weight_df[[".parent_adm2_code"]])) {
      parent_rows <- nonauto_weight_df[
        nonauto_weight_df[[".parent_adm2_code"]] == parent,
        ,
        drop = FALSE
      ]
      parent_idx <- match(parent, as.character(collapsed_weights[[adm2_code]]))

      if (!is.na(parent_idx)) {
        collapsed_weights[[weight_column]][parent_idx] <-
          sum(parent_rows[[weight_column]], na.rm = TRUE)
      }
    }
  }

  list(data = atn_df, weights = collapsed_weights)
}

#' Query Korean census data by administrative code and year
#' @description The function queries a long format census data frame
#' ([`censuskor`]) for specific administrative codes (if provided)
#' @param codes integer vector of admin codes (e.g. `c(11, 26)`)
#'   or character administrative area names (e.g. `c("Seoul", "Daejeon")`).
#' @param type character vector. One or more of "population", "housing",
#'   "tax", "economy",
#'   "medicine", "migration", "environment", "mortality", "social security",
#'   or "landuse".
#'   Defaults to "population".
#' @param year  integer(1). One of 2010, 2015, or 2020.
#' @param level character(1). "adm1" for province-level, "adm2" for
#'   municipal-level, or "adm3" for neighborhood/town-level. Defaults to
#'   "adm2".
#' @param adm2_type character(1). Which municipal code type to keep before
#'   returning `adm2` results or aggregating to `adm1`. `"all"` keeps the
#'   current data, `"atn"` keeps autonomous/basic local government rows, and
#'   `"non"` keeps non-autonomous rows where they are available. For weighted
#'   aggregation with `"atn"`, autonomous/basic local government rate rows are
#'   recalculated from their non-autonomous component rows using the supplied
#'   weights before returning `adm2` or aggregating to `adm1`.
#' @param aggregator function to aggregate values when `level = "adm1"` or
#'   when weighted `adm2_type = "atn"` recalculates autonomous/basic local
#'   government rows.
#' @param weight_type character(1). Optional data type used to supply
#'   weights when aggregating. For example, rate variables in
#'   `type = "mortality"` can be aggregated with population weights from
#'   `weight_type = "population"`.
#' @param weight_column character(1). Optional column name used as weights
#'   when aggregating. If `weight_type = "population"` and
#'   `weight_column` is omitted, `"all households_total_prs"` is used.
#' @param geometry logical(1). If `TRUE`, returns an `sf` object
#'   with geometries attached. Defaults to `FALSE`.
#' @param ... additional arguments passed to the `aggregator` function.
#'   (e.g., `na.rm = TRUE`). When `weight_type` or `weight_column` is
#'   supplied, `aggregator` must accept a `w` argument such as
#'   [stats::weighted.mean()].
#' @note Character names are resolved to their administrative codes before
#'   filtering. The 'wide' table is returned with separate columns for each
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
#' # Query adm3 population data within Jongno-gu
#' anycensus(
#'   codes = 11010,
#'   type = "population",
#'   year = 2020,
#'   level = "adm3"
#' )
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
#'
#' # Aggregate mortality rates to adm1 using population weights
#' anycensus(
#'   codes = "Seoul",
#'   type = "mortality",
#'   year = 2020,
#'   level = "adm1",
#'   aggregator = stats::weighted.mean,
#'   weight_type = "population",
#'   weight_column = "all households_total_prs",
#'   na.rm = TRUE
#' )
#'
#' # Aggregate rates to adm1 after cleaning to autonomous/basic local governments
#' anycensus(
#'   codes = "Gyeonggi-do",
#'   type = "mortality",
#'   year = 2020,
#'   level = "adm1",
#'   adm2_type = "atn",
#'   aggregator = stats::weighted.mean,
#'   weight_type = "population",
#'   weight_column = "all households_total_prs",
#'   na.rm = TRUE
#' )
#'
#' # Recalculate adm2 rates after cleaning to autonomous/basic local governments
#' anycensus(
#'   codes = "Gyeonggi-do",
#'   type = "mortality",
#'   year = 2020,
#'   level = "adm2",
#'   adm2_type = "atn",
#'   aggregator = stats::weighted.mean,
#'   weight_type = "population",
#'   weight_column = "all households_total_prs",
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
    "medicine", "migration", "environment", "welfare",
    "social security", "landuse"
  ),
  level = c("adm2", "adm3", "adm1"),
  adm2_type = c("all", "atn", "non"),
  aggregator = sum,
  weight_type = NULL,
  weight_column = NULL,
  geometry = FALSE,
  ...
) {
  censuskor <- NULL
  .data <- NULL
  data("censuskor", package = "tidycensuskr", envir = environment())
  type_choices <- c(
    "population", "housing", "tax", "mortality", "economy",
    "medicine", "migration", "environment", "welfare",
    "social security", "landuse"
  )
  if (missing(type)) {
    type <- type_choices[[1]]
  } else {
    type <- unique(vapply(
      type,
      match.arg,
      choices = type_choices,
      FUN.VALUE = character(1)
    ))
  }
  level    <- match.arg(level)
  adm2_type <- match.arg(adm2_type)
  if (!is.null(weight_type)) {
    weight_type <- match.arg(
      weight_type,
      choices = type_choices
    )
  }
  df       <- censuskor

  has_weighting <- !is.null(weight_type) || !is.null(weight_column)

  if (length(type) > 1 && has_weighting) {
    stop("Weighted computation requires a single `type` value.")
  }

  if (level == "adm2" && has_weighting && !identical(adm2_type, "atn")) {
    stop("Weighted adm2 computation is only available when `adm2_type = 'atn'`.")
  }

  unit <- NULL
  is_int_code <- is.null(codes) || all(is.numeric(codes))
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

  # adm1 is aggregated from adm2 rows. Explicitly separating adm2 and adm3
  # rows prevents child observations from being mixed with their parents.
  source_level <- if (level == "adm3") "adm3" else "adm2"
  admN_code <- paste0(level, "_code")
  source_code <- paste0(source_level, "_code")
  source_rows <- if (source_level == "adm3") {
    !is.na(df[[source_code]])
  } else {
    is.na(df[["adm3_code"]])
  }
  df <- df[source_rows, , drop = FALSE]

  # Resolve names to codes first so admN_code is the standard reference for
  # both numeric and character queries.
  if (!is.null(codes) && !is_int_code) {
    requested_names <- gsub(" ", "", codes)
    name_levels <- switch(
      level,
      adm1 = "adm1",
      adm2 = c("adm1", "adm2"),
      adm3 = c("adm1", "adm2", "adm3")
    )
    resolved_codes <- unlist(
      lapply(name_levels, function(name_level) {
        matches <- grepl(
          sprintf("^(%s)", paste(requested_names, collapse = "|")),
          gsub(" ", "", df[[name_level]])
        )
        df[[paste0(name_level, "_code")]][matches]
      }),
      use.names = FALSE
    )
    codes <- unique(resolved_codes[!is.na(resolved_codes)])
  }

  dfe <- df[
    df[["year"]] == year & df[["type"]] %in% type,
    ,
    drop = FALSE
  ]
  if (!is.null(codes)) {
    if (length(codes) == 0) {
      dfe <- dfe[FALSE, , drop = FALSE]
    } else {
      code_pattern <- sprintf("^(%s)", paste(codes, collapse = "|"))
      dfe <- dfe[
        grepl(code_pattern, as.character(dfe[[admN_code]])),
        ,
        drop = FALSE
      ]
    }
  }
  dfe <- dfe[!duplicated(dfe), , drop = FALSE]
  if (source_level == "adm2") {
    dfe[c("adm3", "adm3_code")] <- NULL
  }
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
  if (adm2_type == "non" || (adm2_type == "atn" && !has_weighting)) {
    dfe <- detect_adm2_type(dfe, year = year, mode = adm2_type)
  }

  if (level == "adm2" && has_weighting) {
    if (is.null(weight_column)) {
      if (identical(weight_type, "population")) {
        weight_column <- "all households_total_prs"
      } else {
        stop("`weight_column` must be supplied when weighted aggregation is requested.")
      }
    }

    if (!is.null(weight_type) && !identical(weight_type, type)) {
      weight_df <- anycensus(
        year = year,
        codes = codes,
        type = weight_type,
        level = "adm2",
        adm2_type = "all",
        geometry = FALSE
      )
    } else {
      weight_df <- dfe
    }

    if (!weight_column %in% names(weight_df)) {
      stop(sprintf("Weight column '%s' was not found in the '%s' query output.", weight_column, ifelse(is.null(weight_type), type, weight_type)))
    }

    collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
      df = dfe,
      weight_df = weight_df,
      weight_column = weight_column,
      aggregator = aggregator,
      ...
    )
    dfe <- collapsed_adm2[["data"]]
    weight_values <- collapsed_adm2[["weights"]]
    if (weight_column %in% names(dfe)) {
      dfe[[weight_column]] <- NULL
    }
    dfe <- dplyr::left_join(dfe, weight_values, by = "adm2_code")
  }
  # if level is adm1, aggregate adm2 to adm1
  if (level == "adm1") {
    if (has_weighting) {
      if (is.null(weight_column)) {
        if (identical(weight_type, "population")) {
          weight_column <- "all households_total_prs"
        } else {
          stop("`weight_column` must be supplied when weighted aggregation is requested.")
        }
      }

      if (!is.null(weight_type) && !identical(weight_type, type)) {
        weight_df <- anycensus(
          year = year,
          codes = codes,
          type = weight_type,
          level = "adm2",
          adm2_type = if (identical(adm2_type, "atn")) "all" else adm2_type,
          geometry = FALSE
        )
        if (!weight_column %in% names(weight_df)) {
          stop(sprintf("Weight column '%s' was not found in the '%s' query output.", weight_column, weight_type))
        }
        if (identical(adm2_type, "atn")) {
          collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
            df = dfe,
            weight_df = weight_df,
            weight_column = weight_column,
            aggregator = aggregator,
            ...
          )
          dfe <- collapsed_adm2[["data"]]
          weight_values <- collapsed_adm2[["weights"]]
          names(weight_values)[names(weight_values) == weight_column] <- ".aggregation_weight"
        } else {
          weight_values <- weight_df[, c("adm2_code", weight_column)]
          names(weight_values)[names(weight_values) == weight_column] <- ".aggregation_weight"
        }
        dfe <- dplyr::left_join(dfe, weight_values, by = "adm2_code")
      } else {
        if (!weight_column %in% names(dfe)) {
          stop(sprintf("Weight column '%s' was not found in the '%s' query output.", weight_column, type))
        }
        if (identical(adm2_type, "atn")) {
          collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
            df = dfe,
            weight_df = dfe,
            weight_column = weight_column,
            aggregator = aggregator,
            ...
          )
          dfe <- collapsed_adm2[["data"]]
          weight_values <- collapsed_adm2[["weights"]]
          names(weight_values)[names(weight_values) == weight_column] <- ".aggregation_weight"
          if (weight_column %in% names(dfe)) {
            dfe[[weight_column]] <- NULL
          }
          dfe <- dplyr::left_join(dfe, weight_values, by = "adm2_code")
        } else {
          dfe[[".aggregation_weight"]] <- dfe[[weight_column]]
        }
      }

      dfe <- dfe |>
        dplyr::group_by(
          .data[["year"]], .data[["type"]], .data[["adm1"]], .data[["adm1_code"]]
        ) |>
        dplyr::group_modify(
          ~ {
            weight_values <- .x[[".aggregation_weight"]]
            summary_values <- lapply(
              .x[
                setdiff(
                  names(.x),
                  c("adm2", "adm2_code", weight_column, ".aggregation_weight")
                )
              ],
              function(column_values) {
                aggregator(column_values, w = weight_values, ...)
              }
            )
            summary_values[[weight_column]] <- sum(weight_values, na.rm = TRUE)
            as.data.frame(summary_values, check.names = FALSE)
          }
        ) |>
        dplyr::ungroup()
    } else {
      if (identical(adm2_type, "atn")) {
        dfe <- detect_adm2_type(dfe, year = year, mode = adm2_type)
      }
      dfe <- dfe |>
        dplyr::group_by(
          .data[["year"]], .data[["type"]], .data[["adm1"]], .data[["adm1_code"]]
        ) |>
        dplyr::summarise(
          dplyr::across(
            .cols = -c("adm2", "adm2_code"),
            .fns = ~ aggregator(.x, ...)
          ),
          .groups = "keep"
        )
    }
  }

  if (geometry) {
    stopifnot(level == "adm2")
    boundaries <- load_districts(year = year)
    boundaries <-
      dplyr::left_join(
        dfe,
        boundaries,
        by = c("adm2_code" = "adm2_code")
      )
    dfe <-
      sf::st_as_sf(boundaries, sf_column_name = "geometry")
  }
  dfe
}
