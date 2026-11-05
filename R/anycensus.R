# Units whose values are rates; every other unit is treated as an additive count
.rate_units <- c(
  "per 100k population", "births per 1000", "births per woman", "percent"
)

# Identify city count records for which the same indicator has Gu records.
.city_count_keys <- function(df) {
  codes <- as.character(df[["adm2_code"]])
  count <-
    !is.na(codes) & !is.na(df[["value"]]) & !df[["unit"]] %in% .rate_units
  child <- count & substr(codes, 5, 5) != "0"
  paste(df[["year"]][child], df[["type"]][child], df[["class1"]][child],
    df[["class2"]][child], df[["unit"]][child],
    paste0(substr(codes[child], 1, 4), "0"),
    sep = "\r"
  )
}

.city_count_record_keys <- function(df) {
  paste(df[["year"]], df[["type"]], df[["class1"]], df[["class2"]],
    df[["unit"]], as.character(df[["adm2_code"]]),
    sep = "\r"
  )
}

# Non-autonomous Gu codes of each city in `df` (all types),
# named "<year> <city code>"
.reference_gu <- function(df) {
  code_chr <- as.character(df[["adm2_code"]])
  is_gu <- !is.na(code_chr) & substr(code_chr, 5, 5) != "0"
  key <- paste(df[["year"]][is_gu], paste0(substr(code_chr[is_gu], 1, 4), "0"))
  lapply(split(code_chr[is_gu], key), unique)
}

# Values of a wide column as numbers. pivot_wider() leaves duplicated raw rows
# as list cells; they are summed, as pivot_table() does in pycensuskr.
.cell_values <- function(x) {
  if (!is.list(x)) {
    return(as.numeric(x))
  }
  vapply(
    x,
    function(e) if (all(is.na(e))) NA_real_ else sum(e, na.rm = TRUE),
    numeric(1)
  )
}

# Return autonomous/basic local government rows of `df`, resolving each city
# with non-autonomous Gu variable by variable within a year and type.
# * Count variables use the sum of the Gu when every Gu of that year
#   (`ref_gu`) has a value, since city rows can be missing, zero or averaged.
#   When only some Gu have values, their partial sum is used with a warning.
# * Rate variables (`rate_columns`) are recalculated from the Gu with
#   `aggregator` when `weights` (named by Gu code) are given. Otherwise the
#   city rate is kept, or the unweighted Gu mean is used when it is missing.
# Values built from an incomplete set of Gu are reported in one warning.
.collapse_to_atn <- function(
  df,
  ref_gu,
  rate_columns = character(0),
  weights = NULL,
  aggregator = NULL,
  ...
) {
  id_columns <-
    intersect(
      c("year", "type", "adm1", "adm1_code", "adm2", "adm2_code"),
      names(df)
    )
  value_columns <- setdiff(names(df), id_columns)
  code_chr <- as.character(df[["adm2_code"]])
  parent_code <- paste0(substr(code_chr, 1, 4), "0")
  is_gu <- code_chr != parent_code

  out <- df[!is_gu, , drop = FALSE]
  out_key <- paste(out[["year"]], out[["type"]], code_chr[!is_gu])
  gu_key <- paste(df[["year"]], df[["type"]], parent_code)
  partial <- character(0)

  for (key in unique(gu_key[is_gu])) {
    g <- df[is_gu & gu_key == key, , drop = FALSE]
    g_code <- as.character(g[["adm2_code"]])
    parent <- paste0(substr(g_code[1], 1, 4), "0")
    expected <- ref_gu[[paste(g[["year"]][1], parent)]]
    if (is.null(expected)) {
      expected <- g_code
    }

    i <- match(key, out_key)
    if (is.na(i)) {
      # The city row is missing: start from its first Gu row
      new_row <- g[1, , drop = FALSE]
      new_row[["adm2_code"]] <-
        if (is.numeric(df[["adm2_code"]])) as.numeric(parent) else parent
      # Gu names read "<gu> <city>", e.g. "Jangan-gu Suwon-si"
      new_row[["adm2"]] <- sub("^\\S+\\s+", "", new_row[["adm2"]])
      for (col in value_columns) {
        new_row[[col]] <-
          if (is.list(new_row[[col]])) list(NA_real_) else NA_real_
      }
      out <- dplyr::bind_rows(out, new_row)
      out_key <- c(out_key, key)
      i <- nrow(out)
    }
    w <- if (is.null(weights)) NULL else unname(weights[g_code])

    for (col in value_columns) {
      v <- .cell_values(g[[col]])
      ok <- !is.na(v)
      if (!any(ok)) {
        next
      }
      city <- .cell_values(out[[col]][i])
      complete <- all(expected %in% g_code[ok])
      if (col %in% rate_columns) {
        if (!is.null(w)) {
          value <- aggregator(v[ok], w = w[ok], ...)
        } else if (is.na(city)) {
          value <- mean(v[ok])
        } else {
          next
        }
      } else {
        value <- sum(v[ok])
      }
      if (!complete) {
        partial <-
          c(partial,
            sprintf("%s %s: %s", g[["year"]][1], out[["adm2"]][i], col)
          )
      }
      if (is.list(out[[col]])) {
        out[[col]][i] <- list(value)
      } else {
        out[[col]][i] <- value
      }
    }
  }

  if (length(partial) > 0) {
    warning(
      sprintf(
        paste(
          "adm2_type = 'atn' used an incomplete set of",
          "non-autonomous Gu for %d value(s), e.g. %s."
        ),
        length(partial), partial[1]
      ),
      call. = FALSE
    )
  }
  out
}

# Weighted adm2_type = "atn" collapse of `df` (see `.collapse_to_atn()`).
# Rate columns are recalculated from the Gu with weights from `weight_df`;
# the weight column itself is resolved as a count.
.collapse_weighted_adm2_to_atn <- function(
  df,
  weight_df,
  weight_column,
  aggregator,
  ref_gu,
  rate_columns,
  ...
) {
  weight_codes <- as.character(weight_df[["adm2_code"]])
  weights <-
    stats::setNames(.cell_values(weight_df[[weight_column]]), weight_codes)
  weights <- weights[!duplicated(weight_codes)]
  data <- .collapse_to_atn(
    df[setdiff(names(df), weight_column)],
    ref_gu, rate_columns, weights, aggregator, ...
  )
  id_columns <-
    intersect(
      c("year", "type", "adm1", "adm1_code", "adm2", "adm2_code"),
      names(weight_df)
    )
  collapsed_weights <-
    .collapse_to_atn(weight_df[c(id_columns, weight_column)], ref_gu)
  list(
    data = data,
    weights = collapsed_weights[, c("adm2_code", weight_column)]
  )
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
#' @param year integer(1). One of 2010, 2015, 2020, or 2025. 2025 data is
#'   currently available only for ADM3 population and housing.
#' @param level character(1). "adm1" for province-level, "adm2" for
#'   municipal-level, or "adm3" for neighborhood/town-level. ADM3 population
#'   and housing data is available for 2015, 2020, and 2025; ADM3 economy and
#'   mortality data is available for 2020. Defaults to "adm2".
#' @param adm2_type character(1). Municipal level to return or aggregate.
#'   For a city and its non-autonomous Gu with the same indicator, `"all"`
#'   removes the source city count when Gu values are available, but retains
#'   city and Gu rates; the city count is `NA` in a mixed wide row. `"atn"`
#'   returns city rows, summing available Gu counts and retaining the city rate;
#'   `"non"` returns Gu rows where they are available. Incomplete Gu sums emit
#'   a warning. When a city rate is missing, `"atn"` uses the Gu mean; with
#'   weights, it recalculates city rates from Gu values.
#'   Rates are identified by units per 100,000 population, births per 1,000,
#'   births per woman, and percent; other units are treated as additive counts.
#'   Selecting a city code with `"atn"` or `"non"` also selects its Gu.
#'   `"all"` retains both city and Gu rates, so choose the intended geographic
#'   level and a suitable aggregator when aggregating rates to `"adm1"`.
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
#' @param geometry logical(1). If `TRUE`, returns an `sf` object with ADM2
#'   geometries attached. Geometry is available for 2010, 2015, and 2020;
#'   2025 census data is tabular only. Defaults to `FALSE`.
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
#' # Query 2025 neighborhood-level housing data (without geometry)
#' \dontrun{
#' anycensus(
#'   codes = 11010,
#'   type = "housing",
#'   year = 2025,
#'   level = "adm3"
#' )
#' }
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
#' # Aggregate rates to adm1 after cleaning to autonomous/
#' # basic local governments
#' \dontrun{
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
#' }
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
  year = 2020,
  codes = NULL,
  type = c(
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
  level <- match.arg(level)
  adm2_type <- match.arg(adm2_type)
  if (!is.null(weight_type)) {
    weight_type <- match.arg(
      weight_type,
      choices = type_choices
    )
  }
  df <- censuskor

  has_weighting <- !is.null(weight_type) || !is.null(weight_column)

  if (length(type) > 1 && has_weighting) {
    stop("Weighted computation requires a single `type` value.")
  }

  if (level == "adm2" && has_weighting && !identical(adm2_type, "atn")) {
    stop(
      "Weighted adm2 computation is only available when",
      "`adm2_type = 'atn'`."
    )
  }

  unit <- NULL
  is_int_code <- is.null(codes) || all(is.numeric(codes))
  suppressWarnings(try_code_integer <- as.integer(codes))
  try_code_all_alpha <- all(grepl("[A-Za-z]+", codes))
  if (!is_int_code) {
    if (sum(is.na(try_code_integer)) > 0 && !try_code_all_alpha) {
      stop("Mixed types in 'codes' are not allowed.")
    }
    if (!any(is.na(try_code_integer))) {
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
  adm_code <- paste0(level, "_code")
  source_code <- paste0(source_level, "_code")
  source_rows <- if (source_level == "adm3") {
    !is.na(df[[source_code]])
  } else {
    is.na(df[["adm3_code"]])
  }
  df <- df[source_rows, , drop = FALSE]

  # Resolve names to codes first so adm_code is the standard reference for
  # both numeric and character queries.
  if (!is.null(codes) && !is_int_code) {
    requested_names <- gsub(" ", "", codes)
    name_levels <- switch(level,
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
    df[["year"]] == year & df[["type"]] %in% type, ,
    drop = FALSE
  ]
  count_keys <- if (source_level == "adm2" && adm2_type == "all") {
    .city_count_keys(dfe)
  } else {
    character(0)
  }
  if (!is.null(codes)) {
    if (length(codes) == 0) {
      dfe <- dfe[FALSE, , drop = FALSE]
    } else {
      code_pattern <- sprintf("^(%s)", paste(codes, collapse = "|"))
      selected <- grepl(code_pattern, as.character(dfe[[adm_code]]))
      if (level == "adm2" && adm2_type %in% c("atn", "non")) {
        ids <- as.character(dfe[["adm2_code"]])
        cities <- unique(substr(ids[selected & substr(ids, 5, 5) == "0"], 1, 4))
        selected <- selected |
          (substr(ids, 1, 4) %in% cities & substr(ids, 5, 5) != "0")
      }
      dfe <- dfe[selected, , drop = FALSE]
    }
  }
  dfe <- dfe[!duplicated(dfe), , drop = FALSE]
  excluded_counts <- dfe[FALSE, , drop = FALSE]
  if (length(count_keys)) {
    ids <- as.character(dfe[["adm2_code"]])
    excluded <- !is.na(ids) & substr(ids, 5, 5) == "0" &
      !dfe[["unit"]] %in% .rate_units &
      .city_count_record_keys(dfe) %in% count_keys
    excluded_counts <- dfe[excluded, , drop = FALSE]
    dfe <- dfe[!excluded, , drop = FALSE]
  }
  if (source_level == "adm2") {
    dfe[c("adm3", "adm3_code")] <- NULL
  }
  # Columns holding rates; abbreviate() is applied to the same vector as below
  rate_columns <- unique(gsub("_NA", "", tolower(paste(
    dfe[["class1"]], dfe[["class2"]], abbreviate(dfe[["unit"]], minlength = 3),
    sep = "_"
  ))[dfe[["unit"]] %in% .rate_units]))
  # Gu codes of each city in the requested year, taken from all types
  ref_gu <- .reference_gu(df[df[["year"]] == year, , drop = FALSE])
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
  excluded_count_cells <- if (nrow(excluded_counts)) {
    excluded_columns <- gsub("_NA", "", tolower(paste(
      excluded_counts[["class1"]], excluded_counts[["class2"]],
      abbreviate(excluded_counts[["unit"]], minlength = 3),
      sep = "_"
    )))
    paste(excluded_counts[["year"]], excluded_counts[["type"]],
      as.character(excluded_counts[["adm2_code"]]), excluded_columns,
      sep = "\r"
    )
  } else {
    character(0)
  }
  if (nrow(excluded_counts)) {
    for (column in setdiff(unique(excluded_columns), names(dfe))) {
      dfe[[column]] <- rep(NA_real_, nrow(dfe))
    }
  }
  # Non-weighted adm2_type handling (weighted "atn" is resolved below, since
  # rate variables are then recalculated with the supplied weights)
  if (adm2_type == "atn" && !has_weighting && source_level == "adm2") {
    dfe <- .collapse_to_atn(dfe, ref_gu, rate_columns)
  } else if (adm2_type == "non" || (adm2_type == "atn" && !has_weighting)) {
    dfe <- detect_adm2_type(dfe, year = year, mode = adm2_type)
  }

  if (level == "adm2" && has_weighting) {
    if (is.null(weight_column)) {
      if (identical(weight_type, "population")) {
        weight_column <- "all households_total_prs"
      } else {
        stop(paste0(
          "`weight_column` must be supplied when weighted ",
          "aggregation is requested."
        ))
      }
    }

    if (!is.null(weight_type) && !identical(weight_type, type)) {
      weight_codes <- if (!is.null(codes)) unique(dfe[["adm2_code"]]) else codes
      weight_df <- anycensus(
        year = year,
        codes = weight_codes,
        type = weight_type,
        level = "adm2",
        adm2_type = "all",
        geometry = FALSE
      )
    } else {
      weight_df <- dfe
    }

    if (!weight_column %in% names(weight_df)) {
      stop(sprintf(
        "Weight column '%s' was not found in the '%s' query output.",
        weight_column, ifelse(is.null(weight_type), type, weight_type)
      ))
    }

    collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
      df = dfe,
      weight_df = weight_df,
      weight_column = weight_column,
      aggregator = aggregator,
      ref_gu = ref_gu,
      rate_columns = rate_columns,
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
    aggregate_args <- list(...)
    if (has_weighting) {
      if (is.null(weight_column)) {
        if (identical(weight_type, "population")) {
          weight_column <- "all households_total_prs"
        } else {
          stop(paste0(
            "`weight_column` must be supplied when weighted ",
            "aggregation is requested."
          ))
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
          stop(sprintf(
            "Weight column '%s' was not found in the '%s' query output.",
            weight_column, weight_type
          ))
        }
        if (identical(adm2_type, "atn")) {
          collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
            df = dfe,
            weight_df = weight_df,
            weight_column = weight_column,
            aggregator = aggregator,
            ref_gu = ref_gu,
            rate_columns = rate_columns,
            ...
          )
          dfe <- collapsed_adm2[["data"]]
          weight_values <- collapsed_adm2[["weights"]]
          names(weight_values)[names(weight_values) == weight_column] <-
            ".aggregation_weight"
        } else {
          weight_values <- weight_df[, c("adm2_code", weight_column)]
          names(weight_values)[names(weight_values) == weight_column] <-
            ".aggregation_weight"
        }
        dfe <- dplyr::left_join(dfe, weight_values, by = "adm2_code")
      } else {
        if (!weight_column %in% names(dfe)) {
          stop(sprintf(
            "Weight column '%s' was not found in the '%s' query output.",
            weight_column, type
          ))
        }
        if (identical(adm2_type, "atn")) {
          collapsed_adm2 <- .collapse_weighted_adm2_to_atn(
            df = dfe,
            weight_df = dfe,
            weight_column = weight_column,
            aggregator = aggregator,
            ref_gu = ref_gu,
            rate_columns = rate_columns,
            ...
          )
          dfe <- collapsed_adm2[["data"]]
          weight_values <- collapsed_adm2[["weights"]]
          names(weight_values)[names(weight_values) == weight_column] <-
            ".aggregation_weight"
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
          .data[["year"]], .data[["type"]], .data[["adm1"]],
          .data[["adm1_code"]]
        ) |>
        dplyr::group_modify(
          function(.x, .y) {
            weight_values <- .x[[".aggregation_weight"]]
            value_names <- setdiff(
              names(.x),
              c("adm2", "adm2_code", weight_column, ".aggregation_weight")
            )
            ids <- as.character(.x[["adm2_code"]])
            parent <- paste0(substr(ids, 1, 4), "0")
            unweighted_parent <- is.na(weight_values) & ids == parent &
              parent %in% parent[ids != parent & !is.na(weight_values)]
            summary_values <- lapply(value_names, function(column) {
              cell <- paste(.y[["year"]], .y[["type"]], ids, column, sep = "\r")
              keep <- !unweighted_parent & !cell %in% excluded_count_cells
              do.call(aggregator, c(
                list(.cell_values(.x[[column]])[keep], w = weight_values[keep]),
                aggregate_args
              ))
            })
            names(summary_values) <- value_names
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
          .data[["year"]], .data[["type"]], .data[["adm1"]],
          .data[["adm1_code"]]
        ) |>
        dplyr::group_modify(function(.x, .y) {
          ids <- as.character(.x[["adm2_code"]])
          value_names <- setdiff(names(.x), c("adm2", "adm2_code"))
          values <- lapply(value_names, function(column) {
            cell <- paste(.y[["year"]], .y[["type"]], ids, column, sep = "\r")
            do.call(aggregator, c(list(.cell_values(.x[[column]])[
              !cell %in% excluded_count_cells
            ]), aggregate_args))
          })
          names(values) <- value_names
          as.data.frame(values, check.names = FALSE)
        }) |>
        dplyr::ungroup()
    }
  }

  if (geometry) {
    if (level != "adm2") {
      stop("Geometry is currently supported only for level = 'adm2'.")
    }
    if (!year %in% c(2010, 2015, 2020)) {
      stop("Boundary data is available only for 2010, 2015, and 2020.")
    }
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
