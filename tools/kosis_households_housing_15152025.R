# Retrieve 읍면동 household and housing census data from KOSIS and stage it.
# Run from the repository root with: Rscript tools/kosis_households_housing_15152025.R

required_packages <- c("DBI", "duckdb", "dplyr", "httr", "jsonlite", "readr", "stringr")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Install required R packages: ", paste(missing_packages, collapse = ", "))
}

library(dplyr)

api_key_file <- path.expand(Sys.getenv("KOSIS_KEY_FILE", "~/.kosiskey"))
if (!file.exists(api_key_file)) {
  stop("KOSIS key file not found. Set KOSIS_KEY_FILE or create ~/.kosiskey.")
}
api_key <- readLines(api_key_file, warn = FALSE)[1]
if (is.na(api_key) || !nzchar(api_key)) stop("KOSIS key file is empty.")

tables <- c("DT_1JC1501", "DT_1JC1502", "DT_1JC1503", "DT_1JU1501", "DT_1IN1502")
years <- c(2015L, 2020L, 2025L)
api_data_url <- "https://kosis.kr/openapi/Param/statisticsParameterData.do"
api_meta_url <- "https://kosis.kr/openapi/statisticsData.do"

repair_kosis_json <- function(x) {
  # The KOSIS item-metadata response sometimes omits quotes around JSON keys.
  gsub("([{,])\\s*([A-Za-z][A-Za-z0-9_]*):", '\\1"\\2":', x, perl = TRUE)
}

request_text <- function(url, query) {
  response <- httr::GET(url, query = query, httr::timeout(120))
  httr::stop_for_status(response)
  httr::content(response, as = "text", encoding = "UTF-8")
}

get_items <- function(tbl_id) {
  body <- request_text(
    api_meta_url,
    list(
      method = "getMeta", type = "ITM", apiKey = api_key, format = "json",
      orgId = "101", tblId = tbl_id
    )
  )
  metadata <- jsonlite::fromJSON(repair_kosis_json(body), simplifyVector = TRUE)
  items <- metadata |>
    dplyr::filter(OBJ_ID == "ITEM", !is.na(ITM_ID), ITM_ID != "") |>
    dplyr::distinct(ITM_ID) |>
    dplyr::pull(ITM_ID)
  if (!length(items)) stop("No item metadata returned for ", tbl_id, ".")
  items
}

get_batch <- function(tbl_id, year, item_ids) {
  body <- request_text(
    api_data_url,
    list(
      method = "getList", apiKey = api_key, format = "json", jsonVD = "Y",
      orgId = "101", tblId = tbl_id,
      itmId = paste(item_ids, collapse = "+"), objL1 = "ALL", prdSe = "Y",
      startPrdDe = as.character(year), endPrdDe = as.character(year)
    )
  )

  if (grepl("^\\s*\\{\\s*err:", body)) {
    error <- jsonlite::fromJSON(repair_kosis_json(body), simplifyVector = TRUE)
    if (identical(as.character(error$err), "31") && length(item_ids) > 1L) {
      middle <- ceiling(length(item_ids) / 2)
      return(dplyr::bind_rows(
        get_batch(tbl_id, year, item_ids[seq_len(middle)]),
        get_batch(tbl_id, year, item_ids[(middle + 1L):length(item_ids)])
      ))
    }
    stop("KOSIS API error for ", tbl_id, " / ", year, ": ", error$errMsg)
  }

  result <- jsonlite::fromJSON(body, simplifyVector = TRUE)
  if (!is.data.frame(result) || !nrow(result)) {
    stop("KOSIS returned no data for ", tbl_id, " / ", year, ".")
  }
  result
}

get_table_year <- function(tbl_id, year) {
  item_ids <- get_items(tbl_id)
  batches <- split(item_ids, ceiling(seq_along(item_ids) / 6L))
  result <- dplyr::bind_rows(lapply(batches, function(ids) get_batch(tbl_id, year, ids)))
  if (any(as.integer(result$PRD_DE) != year, na.rm = TRUE)) {
    stop("KOSIS returned a reference period other than ", year, " for ", tbl_id, ".")
  }
  result
}

raw_cache_path <- Sys.getenv("KOSIS_RAW_CACHE_PATH", "")
reuse_raw_cache <- identical(Sys.getenv("KOSIS_REUSE_RAW_CACHE"), "TRUE")
metadata_rows <- list()
if (reuse_raw_cache && nzchar(raw_cache_path) && file.exists(raw_cache_path)) {
  raw_data <- readRDS(raw_cache_path)
  metadata_rows <- attr(raw_data, "kosis_metadata_rows")
  raw_data <- dplyr::as_tibble(raw_data)
  if (is.null(metadata_rows) || length(metadata_rows) != length(tables) * length(years)) {
    stop("Cached raw data is missing its expected KOSIS request metadata.")
  }
} else {
  raw_data <- list()
  for (tbl_id in tables) {
    for (year in years) {
      message("Retrieving ", tbl_id, " / ", year)
      raw <- get_table_year(tbl_id, year)
      raw_data[[paste(tbl_id, year, sep = "_")]] <- raw
      metadata_rows[[length(metadata_rows) + 1L]] <- tibble::tibble(
        org_id = "101", tbl_id = tbl_id, year = year,
        provider = "KOSIS / Ministry of Data and Statistics",
        endpoint = api_data_url,
        request_parameters = paste0(
          "method=getList; format=json; jsonVD=Y; objL1=ALL; itmId=all items in batches; ",
          "prdSe=Y; startPrdDe=endPrdDe=", year
        ),
        retrieval_date = format(Sys.Date(), "%Y-%m-%d"),
        raw_rows = nrow(raw),
        source_geographies = dplyr::n_distinct(raw$C1),
        latest_source_update = paste(sort(unique(raw$LST_CHN_DE)), collapse = ";")
      )
      Sys.sleep(0.25)
    }
  }
  raw_data <- dplyr::bind_rows(raw_data)
  attr(raw_data, "kosis_metadata_rows") <- metadata_rows
  if (nzchar(raw_cache_path)) saveRDS(raw_data, raw_cache_path, compress = "xz")
}

# Load the repository's geographic lookup and the existing package names.
lookup <- readr::read_csv(
  "tools/adm_sgis_lookup_2024.csv",
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
)
data_env <- new.env(parent = globalenv())
load("data/censuskor.rda", envir = data_env)
censuskor <- data_env$censuskor

adm1_lookup <- censuskor |>
  dplyr::distinct(adm1_code = as.character(adm1_code), adm1) |>
  dplyr::filter(!is.na(adm1_code), !is.na(adm1))
if (anyDuplicated(adm1_lookup$adm1_code)) stop("Existing data has ambiguous ADM1 names.")

code_field <- c(`2015` = "sgis_2015", `2020` = "sgis_2020", `2025` = "sgis_2024")
target_vintage <- c(`2015` = "SGIS 2015", `2020` = "SGIS 2020", `2025` = "SGIS 2024 lookup (latest available)")

legacy_adm3_code <- function(code) {
  if (nchar(code) != 8L) return(NA_character_)
  third_digit <- as.integer(substr(code, 3L, 3L))
  if (third_digit >= 5L) {
    paste0(substr(code, 1L, 2L), third_digit - 2L, substr(code, 4L, 7L))
  } else {
    paste0(substr(code, 1L, 2L), substr(code, 3L, 7L))
  }
}

raw_data <- raw_data |>
  dplyr::mutate(
    year = as.integer(PRD_DE),
    source_area_code = as.character(C1),
    target_adm3_code = dplyr::if_else(
      year %in% c(2015L, 2020L),
      vapply(source_area_code, legacy_adm3_code, character(1)),
      source_area_code
    ),
    code_field = unname(code_field[as.character(year)]),
    target_code_vintage = unname(target_vintage[as.character(year)])
  )

geo_rows <- raw_data |>
  dplyr::filter(
    grepl("^[0-9]{8}$", source_area_code),
    grepl("읍면동", C1_OBJ_NM)
  ) |>
  dplyr::distinct(year, source_area_code, C1_NM, C1_NM_ENG, target_adm3_code, code_field, target_code_vintage)

geo_labels <- geo_rows |>
  dplyr::group_by(year, source_area_code, target_adm3_code, code_field, target_code_vintage) |>
  dplyr::summarise(
    C1_NM = if (dplyr::n_distinct(C1_NM) == 1L) dplyr::first(C1_NM) else NA_character_,
    C1_NM_ENG = if (dplyr::n_distinct(C1_NM_ENG, na.rm = TRUE) == 1L) {
      dplyr::first(stats::na.omit(C1_NM_ENG))
    } else {
      NA_character_
    },
    source_name_ambiguous = dplyr::n_distinct(C1_NM) > 1L,
    source_english_ambiguous = dplyr::n_distinct(C1_NM_ENG, na.rm = TRUE) > 1L,
    .groups = "drop"
  )
if (any(geo_labels$source_name_ambiguous)) {
  stop("KOSIS returned conflicting Korean names for the same area code.")
}

translation_file <- list.files("tools", pattern = "SGIS_.*20241231\\.csv$", full.names = TRUE)
if (length(translation_file) != 1L) stop("Expected one 2024 SGIS English translation file in tools/.")
sgis_translation <- read.csv(
  translation_file, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
  colClasses = "character"
)
names(sgis_translation) <- c(
  "sido_ko", "sigungu_ko", "adm3_ko", "sido_en", "sigungu_en", "adm3_en", "address_en"
)
sgis_translation <- tibble::as_tibble(sgis_translation) |>
  dplyr::mutate(
    sido_en = dplyr::case_when(
      sido_en == "Gangwon State" ~ "Gangwon-do",
      sido_en == "Jeju" ~ "Jeju-do",
      sido_en == "Jeonbuk-State" ~ "Jeollabuk-do",
      sido_en == "Sejong City" ~ "Sejong",
      TRUE ~ sido_en
    )
  ) |>
  dplyr::select(sido_en, sigungu_ko, adm3_ko, adm3_en) |>
  dplyr::distinct()
if (anyDuplicated(sgis_translation[c("sido_en", "sigungu_ko", "adm3_ko")])) {
  stop("The SGIS English translation table has ambiguous province/district/name keys.")
}

# Use only exact year-field code matches. Do not guess among name collisions.
adm3_maps <- lapply(unique(geo_rows$code_field), function(field) {
  lookup |>
    dplyr::filter(level == "Neighborhood", !is.na(.data[[field]]), .data[[field]] != "") |>
    dplyr::transmute(
      code_field = field, target_adm3_code = .data[[field]],
      adm3 = name_eng, adm3_ko = name, adm1 = name_sido,
      lookup_code_matched = TRUE
    ) |>
    dplyr::distinct()
}) |>
  dplyr::bind_rows()
if (anyDuplicated(adm3_maps[c("code_field", "target_adm3_code")])) {
  stop("The year-specific ADM3 lookup has duplicate code keys; resolve before staging.")
}

adm2_maps <- lapply(unique(geo_rows$code_field), function(field) {
  candidates <- lookup |>
    dplyr::filter(level %in% c("District", "District_Nonauto"), !is.na(.data[[field]]), .data[[field]] != "") |>
    dplyr::transmute(
      code_field = field, adm2_code = substr(.data[[field]], 1L, 5L),
      adm2 = name_eng, adm2_ko = name, adm1 = name_sido,
      priority = as.integer(level == "District_Nonauto")
    ) |>
    dplyr::distinct()
  best_matches <- candidates |>
    dplyr::group_by(code_field, adm2_code) |>
    dplyr::filter(priority == max(priority)) |>
    dplyr::ungroup()
  ambiguous <- best_matches |>
    dplyr::count(code_field, adm2_code, name = "n") |>
    dplyr::filter(n > 1L)
  if (nrow(ambiguous)) {
    stop("The year-specific ADM2 lookup has unresolved duplicate code prefixes.")
  }
  best_matches |>
    dplyr::select(-priority)
}) |>
  dplyr::bind_rows()
if (anyDuplicated(adm2_maps[c("code_field", "adm2_code")])) {
  stop("The year-specific ADM2 lookup still has duplicate code keys.")
}

source_geo <- geo_labels |>
  dplyr::left_join(adm3_maps, by = c("code_field", "target_adm3_code")) |>
  dplyr::mutate(
    adm2_code = substr(target_adm3_code, 1L, 5L),
    adm1_code = substr(target_adm3_code, 1L, 2L)
  ) |>
  dplyr::left_join(adm2_maps, by = c("code_field", "adm2_code"), suffix = c("", "_district")) |>
  dplyr::mutate(adm1 = dplyr::coalesce(adm1, adm1_district)) |>
  dplyr::left_join(adm1_lookup, by = "adm1_code", suffix = c("", "_package")) |>
  dplyr::mutate(adm1 = dplyr::coalesce(adm1, adm1_package)) |>
  dplyr::left_join(
    sgis_translation,
    by = c("adm1" = "sido_en", "adm2_ko" = "sigungu_ko", "C1_NM" = "adm3_ko")
  ) |>
  dplyr::mutate(
    adm3_name_source = dplyr::case_when(
      is.na(lookup_code_matched) ~ NA_character_,
      !is.na(adm3) ~ "repository ADM3 lookup",
      !is.na(adm3_en) ~ "2024 SGIS English translation",
      !is.na(C1_NM_ENG) ~ "KOSIS C1_NM_ENG (single source label)",
      TRUE ~ NA_character_
    ),
    adm3 = dplyr::if_else(
      !is.na(lookup_code_matched), dplyr::coalesce(adm3, adm3_en, C1_NM_ENG), NA_character_
    )
  )

map_diagnostics <- source_geo |>
  dplyr::mutate(
    mapping_status = dplyr::case_when(
      is.na(lookup_code_matched) ~ "ADM3 code not present in selected vintage crosswalk",
      is.na(adm3) ~ "ADM3 English label unavailable in crosswalk and KOSIS",
      is.na(adm2) ~ "ADM2 parent code not present in selected vintage crosswalk",
      is.na(adm1) ~ "ADM1 name not present in package lookup",
      TRUE ~ "matched"
    )
  )

source_geo_for_join <- map_diagnostics |>
  dplyr::select(
    year, source_area_code, target_adm3_code, adm1, adm1_code, adm2,
    adm2_code, adm3, adm3_name_source, mapping_status
  ) |>
  dplyr::distinct()
if (anyDuplicated(source_geo_for_join[c("year", "source_area_code")])) {
  stop("Geographic join would be many-to-many.")
}

clean_class2 <- function(x) {
  x |>
    stringr::str_replace_all("_+", " ") |>
    stringr::str_squish() |>
    stringr::str_to_lower()
}

cleaned <- raw_data |>
  dplyr::filter(
    grepl("^[0-9]{8}$", source_area_code),
    grepl("읍면동", C1_OBJ_NM)
  ) |>
  dplyr::left_join(source_geo_for_join, by = c("year", "source_area_code", "target_adm3_code")) |>
  dplyr::mutate(
    .source_class = clean_class2(ITM_NM_ENG),
    type = dplyr::case_when(
      TBL_ID == "DT_1IN1502" & grepl("^T1", ITM_ID) ~ "population",
      TRUE ~ "housing"
    ),
    class1 = dplyr::case_when(
      TBL_ID == "DT_1JC1501" ~ "household composition",
      TBL_ID == "DT_1JC1502" ~ "household size",
      TBL_ID == "DT_1JC1503" ~ "households by dwelling type",
      TBL_ID == "DT_1JU1501" ~ "housing types",
      TBL_ID == "DT_1IN1502" & ITM_ID %in% c("T100", "T110", "T120") ~ "all households",
      TBL_ID == "DT_1IN1502" & grepl("^T13", ITM_ID) ~ "domestic population",
      TBL_ID == "DT_1IN1502" & grepl("^T14", ITM_ID) ~ "foreign population",
      TBL_ID == "DT_1IN1502" & grepl("^T2", ITM_ID) ~ "census household totals",
      TBL_ID == "DT_1IN1502" & grepl("^T3", ITM_ID) ~ "census housing totals",
      TRUE ~ NA_character_
    ),
    class2 = dplyr::case_when(
      TBL_ID == "DT_1IN1502" & ITM_ID %in% c("T100", "T130", "T140") ~ "total",
      TBL_ID == "DT_1IN1502" & ITM_ID %in% c("T110", "T131", "T141") ~ "male",
      TBL_ID == "DT_1IN1502" & ITM_ID %in% c("T120", "T132", "T142") ~ "female",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T200" ~ "total households",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T210" ~ "general households",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T220" ~ "group households",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T230" ~ "foreign households",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T310" ~ "total housing units",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T311" ~ "detached dwellings",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T312" ~ "apartments",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T313" ~ "row houses",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T314" ~ "multi-family house units",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T315" ~ "homes in non-residential buildings",
      TBL_ID == "DT_1IN1502" & ITM_ID == "T320" ~ "other living quarters",
      TRUE ~ .source_class
    ),
    unit = dplyr::case_when(
      TBL_ID == "DT_1JU1501" ~ "count",
      TBL_ID == "DT_1JC1503" ~ "households",
      TBL_ID == "DT_1IN1502" & grepl("^T1", ITM_ID) ~ "persons",
      TBL_ID == "DT_1IN1502" & grepl("^T2", ITM_ID) ~ "households",
      TBL_ID == "DT_1IN1502" & grepl("^T3", ITM_ID) ~ "count",
      TBL_ID == "DT_1JC1502" ~ "households",
      TBL_ID == "DT_1JC1501" & grepl("person", UNIT_NM_ENG, ignore.case = TRUE) ~ "persons",
      TBL_ID == "DT_1JC1501" ~ "households",
      TRUE ~ NA_character_
    ),
    .value_text = stringr::str_remove_all(as.character(DT), ","),
    .special_value = !is.na(.value_text) & !grepl("^[+-]?[0-9]+(\\.[0-9]+)?$", .value_text),
    value = suppressWarnings(as.numeric(dplyr::if_else(
      tolower(.value_text) %in% c("x", "-", ""), NA_character_, .value_text
    )))
  )

unknown_values <- cleaned |>
  dplyr::filter(.special_value, !tolower(.value_text) %in% c("x", "-", "")) |>
  dplyr::distinct(TBL_ID, year, .value_text)
if (nrow(unknown_values)) {
  stop("Unexpected nonnumeric KOSIS values found; inspect before cleaning.")
}

append_ready <- cleaned |>
  dplyr::transmute(
    year = as.numeric(year), adm1, adm1_code = as.numeric(adm1_code),
    adm2, adm2_code = as.numeric(adm2_code), type, class1, class2, unit, value,
    adm3, adm3_code = as.numeric(target_adm3_code)
  ) |>
  dplyr::select(
    year, adm1, adm1_code, adm2, adm2_code, type, class1, class2, unit,
    value, adm3, adm3_code
  )

if (
  anyNA(cleaned$class1) || anyNA(cleaned$class2) || anyNA(cleaned$unit) ||
  any(!nzchar(cleaned$class1)) || any(!nzchar(cleaned$class2)) || any(!nzchar(cleaned$unit))
) {
  stop("One or more source categories or units lack a cleaning mapping.")
}
if (any(!grepl("^[0-9]{7,8}$", as.character(cleaned$target_adm3_code)))) {
  stop("Standardized ADM3 code length check failed.")
}

provenance <- cleaned |>
  dplyr::transmute(
    year, org_id = ORG_ID, tbl_id = TBL_ID,
    source_area_code, source_area_name_ko = C1_NM,
    source_area_name_en = C1_NM_ENG,
    source_item_id = ITM_ID, source_item_name_ko = ITM_NM,
    source_item_name_en = ITM_NM_ENG,
    source_unit = UNIT_NM, source_unit_english = UNIT_NM_ENG,
    source_value = DT, target_code_vintage, target_adm3_code,
    adm3_name_source,
    mapping_status = dplyr::coalesce(mapping_status, "unmatched")
  )

unmatched_geographies <- map_diagnostics |>
  dplyr::filter(mapping_status != "matched") |>
  dplyr::select(
    year, source_area_code, source_area_name_ko = C1_NM,
    source_area_name_en = C1_NM_ENG, target_adm3_code,
    target_code_vintage, mapping_status
  ) |>
  dplyr::distinct()

row_keys <- cleaned |>
  dplyr::count(year, source_area_code, type, class1, class2, unit, name = "n") |>
  dplyr::filter(n > 1L)
package_keys <- append_ready |>
  dplyr::count(year, adm3_code, type, class1, class2, unit, name = "n") |>
  dplyr::filter(n > 1L)

metadata <- dplyr::bind_rows(metadata_rows) |>
  dplyr::left_join(
    cleaned |>
      dplyr::count(TBL_ID, year, name = "cleaned_adm3_rows") |>
      dplyr::rename(tbl_id = TBL_ID),
    by = c("tbl_id", "year")
  ) |>
  dplyr::left_join(
    unmatched_geographies |>
      dplyr::count(year, name = "unmatched_area_codes") |>
      dplyr::right_join(tibble::tibble(year = years), by = "year"),
    by = "year"
  ) |>
  dplyr::mutate(
    geography_vintage = unname(target_vintage[as.character(year)]),
    suppressed_values = vapply(seq_len(length(metadata_rows)), function(i) {
      sum(tolower(cleaned$.value_text[cleaned$TBL_ID == metadata_rows[[i]]$tbl_id &
        cleaned$year == metadata_rows[[i]]$year]) == "x", na.rm = TRUE)
    }, integer(1))
  )

readr::write_csv(append_ready, "tools/kosis_households_housing_15152025.csv", na = "")
readr::write_csv(provenance, "tools/kosis_households_housing_15152025_provenance.csv", na = "")
readr::write_csv(unmatched_geographies, "tools/kosis_households_housing_15152025_unmatched_geographies.csv", na = "")
readr::write_csv(metadata, "tools/kosis_households_housing_15152025_metadata.csv", na = "")

connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(connection, "kosis_staged", append_ready, overwrite = TRUE)
DBI::dbExecute(
  connection,
  "COPY kosis_staged TO 'tools/kosis_households_housing_15152025.parquet' (FORMAT PARQUET)"
)
DBI::dbDisconnect(connection, shutdown = TRUE)

cat("Staged rows:", nrow(append_ready), "\n")
cat("Suppressed/source-not-published values (x or -):", sum(is.na(append_ready$value)), "\n")
cat("Unmatched ADM3 areas:", nrow(unmatched_geographies), "\n")
cat("Duplicate source observation keys:", nrow(row_keys), "\n")
cat("Duplicate standardized observation keys:", nrow(package_keys), "\n")
cat("Output fields:", paste(names(append_ready), collapse = ", "), "\n")
