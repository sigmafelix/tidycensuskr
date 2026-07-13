################################################################################
# adm3.R
# Processing Eupmyeondong-level data from Statistics Korea (KOSTAT)
# - Vital statistics (vital), Population Census (census), and Census of Establishments (business)
# - Consolidate and clean data for the years 2010, 2015, and 2020
################################################################################

library(tidyverse)
library(openxlsx)

# ==============================================================================
# (2) Read CSV files and combine identical statistics using rbind
# ==============================================================================
# Note: KOSIS CSV files have a trailing comma, which appends an empty column. This is removed below.

# --- Vital Statistics (vital statistics: births/deaths/marriages/divorces) ---
# 2010: cols = region_code, region_name, sex_code, sex, item_code, item, unit, value(2010), [empty_column]
# 2015+2020: cols = region_code, region_name, sex_code, sex, item_code, item, unit, value(2015), value(2020), [empty_column]

vital_2010_raw <- read.csv("vital_2010.csv", fileEncoding = "euc-kr",
                           header = FALSE, skip = 1, stringsAsFactors = FALSE)
vital_2010 <- vital_2010_raw[, 1:8]
names(vital_2010) <- c("region_code", "region_name", "sex_code", "sex",
                        "item_code", "item", "unit", "value")
vital_2010$value <- as.character(vital_2010$value)
vital_2010$year <- 2010

vital_1520_raw <- read.csv("vital_2015_2020.csv", fileEncoding = "euc-kr",
                           header = FALSE, skip = 1, stringsAsFactors = FALSE)
vital_1520 <- vital_1520_raw[, 1:9]
names(vital_1520) <- c("region_code", "region_name", "sex_code", "sex",
                        "item_code", "item", "unit", "value_2015", "value_2020")

vital_1520 <- vital_1520 %>%
  mutate(value_2015 = as.character(value_2015),
         value_2020 = as.character(value_2020))

vital_15 <- vital_1520 %>%
  select(region_code, region_name, sex_code, sex, item_code, item, unit, value = value_2015) %>%
  mutate(year = 2015)

vital_20 <- vital_1520 %>%
  select(region_code, region_name, sex_code, sex, item_code, item, unit, value = value_2020) %>%
  mutate(year = 2020)

vital <- bind_rows(vital_2010, vital_15, vital_20)

# --- Population Census (census: population/housing) ---
# 2010: cols = region_code, region_name, item_code, item, unit, value(2010), [empty_column]
# 2015+2020: cols = region_code, region_name, item_code, item, unit, value(2015), value(2020), [empty_column]

census_2010_raw <- read.csv("census_2010.csv", fileEncoding = "euc-kr",
                            header = FALSE, skip = 1, stringsAsFactors = FALSE)
census_2010 <- census_2010_raw[, 1:6]
names(census_2010) <- c("region_code", "region_name", "item_code", "item",
                         "unit", "value")
census_2010$value <- as.character(census_2010$value)
census_2010$year <- 2010

census_1520_raw <- read.csv("census_2015_2020.csv", fileEncoding = "euc-kr",
                            header = FALSE, skip = 1, stringsAsFactors = FALSE)
census_1520 <- census_1520_raw[, 1:7]
names(census_1520) <- c("region_code", "region_name", "item_code", "item",
                         "unit", "value_2015", "value_2020")

census_1520 <- census_1520 %>%
  mutate(value_2015 = as.character(value_2015),
         value_2020 = as.character(value_2020))

census_15 <- census_1520 %>%
  select(region_code, region_name, item_code, item, unit, value = value_2015) %>%
  mutate(year = 2015)

census_20 <- census_1520 %>%
  select(region_code, region_name, item_code, item, unit, value = value_2020) %>%
  mutate(year = 2020)

census <- bind_rows(census_2010, census_15, census_20)

# --- Census of Establishments (business survey: number of establishments by industry) ---
# 2010: cols = region_code, region_name, industry_code, industry, item_code, item, unit, value, [empty_column]
# 2015: cols = industry_code, industry, region_code, region_name, item_code, item, unit, value, [empty_column]
# 2020: cols = region_code, region_name, industry_code, industry, item_code, item, unit, value, [empty_column]

business_2010_raw <- read.csv("business_2010.csv", fileEncoding = "euc-kr",
                              header = FALSE, skip = 1, stringsAsFactors = FALSE)
business_2010 <- business_2010_raw[, 1:8]
names(business_2010) <- c("region_code", "region_name",
                           "industry_code", "industry",
                           "item_code", "item", "unit", "value")
business_2010$value <- as.character(business_2010$value)
business_2010$year <- 2010

business_2015_raw <- read.csv("business_2015.csv", fileEncoding = "euc-kr",
                              header = FALSE, skip = 1, stringsAsFactors = FALSE)
business_2015 <- business_2015_raw[, 1:8]
# 2015: Industry classification comes first, administrative region comes second
names(business_2015) <- c("industry_code", "industry",
                           "region_code", "region_name",
                           "item_code", "item", "unit", "value")
business_2015$value <- as.character(business_2015$value)
business_2015$year <- 2015

business_2020_raw <- read.csv("business_2020.csv", fileEncoding = "euc-kr",
                              header = FALSE, skip = 1, stringsAsFactors = FALSE)
business_2020 <- business_2020_raw[, 1:8]
names(business_2020) <- c("region_code", "region_name",
                           "industry_code", "industry",
                           "item_code", "item", "unit", "value")
business_2020$value <- as.character(business_2020$value)
business_2020$year <- 2020

business <- bind_rows(business_2010, business_2015, business_2020)


# ==============================================================================
# (3) Standardize column names to English + Clean item values
# ==============================================================================

# Convert region_code to character for consistency
vital$region_code <- as.character(vital$region_code)
census$region_code <- as.character(census$region_code)
business$region_code <- as.character(business$region_code)

# census: Remove square bracket tags from item_code, and remove unit tags and prefixes from item
census <- census %>%
  mutate(
    item_code = gsub("\\[.*\\]", "", item_code),    # "T100[14STD04553]" -> "T100"
    item = gsub("\\[.*\\]", "", item),               # "총인구[명]" -> "총인구"
    item = gsub("^주택[-_]", "", item)                # "주택_계" -> "계"
  )

# Convert value to numeric (handling empty strings and NAs)
vital$value <- suppressWarnings(as.numeric(gsub(",", "", vital$value)))
census$value <- suppressWarnings(as.numeric(gsub(",", "", census$value)))
business$value <- suppressWarnings(as.numeric(gsub(",", "", business$value)))

# vital: Map item_code to English name
vital <- vital %>%
  mutate(item_en = case_when(
    item_code == "T10" ~ "births",
    item_code == "T20" ~ "deaths",
    item_code == "T30" ~ "natural_increase",
    item_code == "T40" ~ "marriages",
    item_code == "T50" ~ "divorces",
    TRUE ~ item_code
  ))

# vital: Translate sex to English
vital <- vital %>%
  mutate(sex_en = case_when(
    sex_code == "0" | sex == "계" ~ "total",
    sex_code == "1" | sex == "남자" ~ "male",
    sex_code == "2" | sex == "여자" ~ "female",
    TRUE ~ sex
  ))

# census: Map item_code to English name
census <- census %>%
  mutate(item_en = case_when(
    item_code == "T100" ~ "pop_total",
    item_code == "T110" ~ "pop_male",
    item_code == "T120" ~ "pop_female",
    item_code == "T310" ~ "housing_total",
    item_code == "T311" ~ "housing_detached",
    item_code == "T312" ~ "housing_apartment",
    item_code == "T313" ~ "housing_rowhouse",
    item_code == "T314" ~ "housing_multiplex",
    item_code == "T315" ~ "housing_nonresidential",
    item_code == "T320" ~ "housing_other",
    TRUE ~ item_code
  ))


# ==============================================================================
# (4) Keep Eupmyeondong-level data only
# ==============================================================================
# vital: Eupmyeondong code = 8 digits, Sido = 2, Sigungu = 5, remove "Unknown" (미상)
# census: 2010 = 7 digits, 2015/2020 = 8 digits, Sido = 2, Sigungu = 5, remove Eup/Myeon/Dong areas (읍부/면부/동부)
# business: Eupmyeondong code = 7 digits, Sido = 2, Sigungu = 5

vital_emd <- vital %>%
  filter(nchar(region_code) == 8,
         !grepl("미\\s*상", region_name),
         item == '사망건수',
         is.na(value) == FALSE) %>%
  mutate(type = 'mortality', class1 = 'All causes', unit = 'per 100k population') %>%
  select(year, adm3 = region_name, adm3_code = region_code, type, class1, class2 = sex_en, unit, value)


population_emd <- census %>%
  filter(nchar(region_code) %in% c(7, 8),
         !region_code %in% c("03", "04", "05"),
         startsWith(item_en, "pop"),
         is.na(value) == FALSE) %>%
  mutate(type = 'population', class1 = 'all households', class2 = str_remove(item_en, "^pop_"), unit = 'persons') %>%
  select(year, adm3 = region_name, adm3_code = region_code, type, class1, class2, unit, value)

housing_emd <- census %>%
  filter(nchar(region_code) %in% c(7, 8),
         !region_code %in% c("03", "04", "05"),
         startsWith(item_en, "housing"),
         is.na(value) == FALSE) %>%
  mutate(type = 'housing', class1 = 'housing types', class2 = str_remove(item_en, "^housing_"), unit = 'count') %>%
  select(year, adm3 = region_name, adm3_code = region_code, type, class1, class2, unit, value)


business_emd <- business %>%
  filter(nchar(region_code) == 7,
         industry == '전산업',
         is.na(value) == FALSE) %>%
  mutate(type = 'economy', class1 = 'company', class2 = 'total', unit = 'count') %>%
  select(year, adm3 = region_name, adm3_code = region_code, type, class1, class2, unit, value)














# ==============================================================================
# (5) Compare datasets at the Year-Eupmyeondong-Eupmyeondong_code level
# ==============================================================================

# Standardize all codes to 7 digits for comparison
# vital: 8 digits -> first 7 digits (removing trailing 0)
# census 2010: already 7 digits / 2015+2020: 8 digits -> first 7 digits
# business: already 7 digits

vital_regions <- vital_emd %>%
  mutate(region_code_7 = substr(adm3_code, 1, 7)) %>%
  distinct(year, region_code_7, adm3) %>%
  rename(adm3_code = region_code_7)

census_regions <- population_emd %>%
  mutate(region_code_7 = ifelse(nchar(adm3_code) == 8,
                                 substr(adm3_code, 1, 7),
                                adm3_code)) %>%
  distinct(year, region_code_7, adm3) %>%
  rename(adm3_code = region_code_7)

business_regions <- business_emd %>%
  distinct(year, adm3_code, adm3)



# --- Year-by-Year Comparison ---
for (yr in c(2010, 2015, 2020)) {
  v <- vital_regions %>% filter(year == yr)
  c_ <- census_regions %>% filter(year == yr)
  b <- business_regions %>% filter(year == yr)

  cat(sprintf("\n\n=== %d년 비교 ===\n", yr))

  # vital vs census
  if (nrow(v) > 0 & nrow(c_) > 0) {
    vc_only_v <- anti_join(v, c_, by = "adm3_code")
    vc_only_c <- anti_join(c_, v, by = "adm3_code")
    cat(sprintf("\n[Vital vs Census] vital에만 %d개, census에만 %d개\n",
                nrow(vc_only_v), nrow(vc_only_c)))
    if (nrow(vc_only_v) > 0) {
      cat("  vital에만:\n")
      print(as.data.frame(vc_only_v %>% select(adm3_code, adm3)))
    }
    if (nrow(vc_only_c) > 0) {
      cat("  census에만:\n")
      print(as.data.frame(vc_only_c %>% select(adm3_code, adm3)))
    }
    vc_name_diff <- inner_join(v, c_, by = c("adm3_code", "year"),
                                suffix = c("_vital", "_census")) %>%
      filter(adm3_vital != adm3_census)
    if (nrow(vc_name_diff) > 0) {
      cat(sprintf("  동일 코드 다른 이름: %d건\n", nrow(vc_name_diff)))
      print(as.data.frame(vc_name_diff %>% select(adm3_code, adm3_vital, adm3_census)))
    }
  }

  # vital vs business
  if (nrow(v) > 0 & nrow(b) > 0) {
    vb_only_v <- anti_join(v, b, by = "adm3_code")
    vb_only_b <- anti_join(b, v, by = "adm3_code")
    cat(sprintf("\n[Vital vs Business] vital에만 %d개, business에만 %d개\n",
                nrow(vb_only_v), nrow(vb_only_b)))
    if (nrow(vb_only_v) > 0) {
      cat("  vital에만:\n")
      print(as.data.frame(vb_only_v %>% select(adm3_code, adm3)))
    }
    if (nrow(vb_only_b) > 0) {
      cat("  business에만:\n")
      print(as.data.frame(vb_only_b %>% select(adm3_code, adm3)))
    }
    vb_name_diff <- inner_join(v, b, by = c("adm3_code", "year"),
                                suffix = c("_vital", "_business")) %>%
      filter(adm3_vital != adm3_business)
    if (nrow(vb_name_diff) > 0) {
      cat(sprintf("  동일 코드 다른 이름: %d건\n", nrow(vb_name_diff)))
      print(as.data.frame(vb_name_diff %>% select(adm3_code, adm3_vital, adm3_business)))
    }
  }

  # census vs business
  if (nrow(c_) > 0 & nrow(b) > 0) {
    cb_only_c <- anti_join(c_, b, by = "adm3_code")
    cb_only_b <- anti_join(b, c_, by = "adm3_code")
    cat(sprintf("\n[Census vs Business] census에만 %d개, business에만 %d개\n",
                nrow(cb_only_c), nrow(cb_only_b)))
    if (nrow(cb_only_c) > 0) {
      cat("  census에만:\n")
      print(as.data.frame(cb_only_c %>% select(adm3_code, adm3)))
    }
    if (nrow(cb_only_b) > 0) {
      cat("  business에만:\n")
      print(as.data.frame(cb_only_b %>% select(adm3_code, adm3)))
    }
    cb_name_diff <- inner_join(c_, b, by = c("adm3_code", "year"),
                                suffix = c("_census", "_business")) %>%
      filter(adm3_census != adm3_business)
    if (nrow(cb_name_diff) > 0) {
      cat(sprintf("  동일 코드 다른 이름: %d건\n", nrow(cb_name_diff)))
      print(as.data.frame(cb_name_diff %>% select(adm3_code, adm3_census, adm3_business)))
    }
  }
}


# ==============================================================================
# (6) Generate Conversion Map based on name (adm3) and code similarity (2020 only)
# ==============================================================================
# Generate clean Korean names by removing spaces, middle dots (·), periods (.), and commas (,)
clean_name <- function(x) {
  str_replace_all(x, "[\\s\\.\\,\\·]+", "")
}

v_map <- vital_regions %>% filter(year == 2020) %>%
  mutate(adm3_clean = clean_name(adm3), sido_code = substr(adm3_code, 1, 2)) %>%
  select(sido_code, adm3_clean, adm3_vital = adm3, code_vital = adm3_code) %>% distinct()

c_map <- census_regions %>% filter(year == 2020) %>%
  mutate(adm3_clean = clean_name(adm3), sido_code = substr(adm3_code, 1, 2)) %>%
  select(sido_code, adm3_clean, adm3_census = adm3, code_census = adm3_code) %>% distinct()

b_map <- business_regions %>% filter(year == 2020) %>%
  mutate(adm3_clean = clean_name(adm3), sido_code = substr(adm3_code, 1, 2)) %>%
  select(sido_code, adm3_clean, adm3_business = adm3, code_business = adm3_code) %>% distinct()

# Generate all unique (Sido, clean_name) key combinations
all_keys <- bind_rows(
  v_map %>% select(sido_code, adm3_clean),
  c_map %>% select(sido_code, adm3_clean),
  b_map %>% select(sido_code, adm3_clean)
) %>% distinct()



# Greedy match: group by key and pair up entries with the closest codes (minimum numerical difference)
mapped_list <- lapply(1:nrow(all_keys), function(i) {
  key_sido <- all_keys$sido_code[i]
  key_name <- all_keys$adm3_clean[i]

  vs <- v_map %>% filter(sido_code == key_sido, adm3_clean == key_name)
  cs <- c_map %>% filter(sido_code == key_sido, adm3_clean == key_name)
  bs <- b_map %>% filter(sido_code == key_sido, adm3_clean == key_name)

  # If there is at most 1 row in each statistics, no complex matching is needed
  if (nrow(vs) <= 1 && nrow(cs) <= 1 && nrow(bs) <= 1) {
    res <- tibble(sido_code = key_sido, adm3_clean = key_name)
    if (nrow(vs)==1) res <- bind_cols(res, vs %>% select(-sido_code, -adm3_clean)) else res <- bind_cols(res, tibble(adm3_vital=NA_character_, code_vital=NA_character_))
    if (nrow(cs)==1) res <- bind_cols(res, cs %>% select(-sido_code, -adm3_clean)) else res <- bind_cols(res, tibble(adm3_census=NA_character_, code_census=NA_character_))
    if (nrow(bs)==1) res <- bind_cols(res, bs %>% select(-sido_code, -adm3_clean)) else res <- bind_cols(res, tibble(adm3_business=NA_character_, code_business=NA_character_))
    return(res)
  }

  # If there are 2 or more rows, generate all combinations
  grid <- expand_grid(
    idx_v = if(nrow(vs)>0) 1:nrow(vs) else NA,
    idx_c = if(nrow(cs)>0) 1:nrow(cs) else NA,
    idx_b = if(nrow(bs)>0) 1:nrow(bs) else NA
  )

  # Calculate distance between codes
  grid <- grid %>%
    mutate(
      cv = if_else(!is.na(idx_v), as.numeric(vs$code_vital[idx_v]), NA_real_),
      cc = if_else(!is.na(idx_c), as.numeric(cs$code_census[idx_c]), NA_real_),
      cb = if_else(!is.na(idx_b), as.numeric(bs$code_business[idx_b]), NA_real_),

      dist_vc = if_else(!is.na(cv) & !is.na(cc), abs(cv - cc), 0),
      dist_vb = if_else(!is.na(cv) & !is.na(cb), abs(cv - cb), 0),
      dist_cb = if_else(!is.na(cc) & !is.na(cb), abs(cc - cb), 0),

      total_dist = dist_vc + dist_vb + dist_cb
    ) %>% arrange(total_dist)

  result <- list()
  used_v <- c()
  used_c <- c()
  used_b <- c()

  for (j in 1:nrow(grid)) {
    r <- grid[j, ]
    conflict <- FALSE
    if (!is.na(r$idx_v) && r$idx_v %in% used_v) conflict <- TRUE
    if (!is.na(r$idx_c) && r$idx_c %in% used_c) conflict <- TRUE
    if (!is.na(r$idx_b) && r$idx_b %in% used_b) conflict <- TRUE

    if (!conflict) {
      if (!is.na(r$idx_v)) used_v <- c(used_v, r$idx_v)
      if (!is.na(r$idx_c)) used_c <- c(used_c, r$idx_c)
      if (!is.na(r$idx_b)) used_b <- c(used_b, r$idx_b)

      row_res <- tibble(sido_code = key_sido, adm3_clean = key_name)
      if (!is.na(r$idx_v)) row_res <- bind_cols(row_res, vs[r$idx_v, c("adm3_vital", "code_vital")]) else row_res <- bind_cols(row_res, tibble(adm3_vital=NA_character_, code_vital=NA_character_))
      if (!is.na(r$idx_c)) row_res <- bind_cols(row_res, cs[r$idx_c, c("adm3_census", "code_census")]) else row_res <- bind_cols(row_res, tibble(adm3_census=NA_character_, code_census=NA_character_))
      if (!is.na(r$idx_b)) row_res <- bind_cols(row_res, bs[r$idx_b, c("adm3_business", "code_business")]) else row_res <- bind_cols(row_res, tibble(adm3_business=NA_character_, code_business=NA_character_))

      result[[length(result) + 1]] <- row_res
    }
  }

  # Merge remaining unmatched items
  leftover_v <- setdiff(1:nrow(vs), used_v)
  for (idx in leftover_v) {
    row_res <- tibble(sido_code = key_sido, adm3_clean = key_name)
    row_res <- bind_cols(row_res, vs[idx, c("adm3_vital", "code_vital")])
    row_res <- bind_cols(row_res, tibble(adm3_census=NA_character_, code_census=NA_character_))
    row_res <- bind_cols(row_res, tibble(adm3_business=NA_character_, code_business=NA_character_))
    result[[length(result) + 1]] <- row_res
  }

  leftover_c <- setdiff(1:nrow(cs), used_c)
  for (idx in leftover_c) {
    row_res <- tibble(sido_code = key_sido, adm3_clean = key_name)
    row_res <- bind_cols(row_res, tibble(adm3_vital=NA_character_, code_vital=NA_character_))
    row_res <- bind_cols(row_res, cs[idx, c("adm3_census", "code_census")])
    row_res <- bind_cols(row_res, tibble(adm3_business=NA_character_, code_business=NA_character_))
    result[[length(result) + 1]] <- row_res
  }

  leftover_b <- setdiff(1:nrow(bs), used_b)
  for (idx in leftover_b) {
    row_res <- tibble(sido_code = key_sido, adm3_clean = key_name)
    row_res <- bind_cols(row_res, tibble(adm3_vital=NA_character_, code_vital=NA_character_))
    row_res <- bind_cols(row_res, tibble(adm3_census=NA_character_, code_census=NA_character_))
    row_res <- bind_cols(row_res, bs[idx, c("adm3_business", "code_business")])
    result[[length(result) + 1]] <- row_res
  }

  bind_rows(result)
})

conversion_map_2020 <- bind_rows(mapped_list)

# Identify whether all codes match or if there is a mismatch
conversion_map_2020 <- conversion_map_2020 %>%
  mutate(year = 2020) %>%
  select(year, everything()) %>%
  mutate(
    is_code_matched = if_else(
      (is.na(code_vital) | is.na(code_census) | code_vital == code_census) &
      (is.na(code_vital) | is.na(code_business) | code_vital == code_business) &
      (is.na(code_census) | is.na(code_business) | code_census == code_business),
      TRUE, FALSE
    )
  )

# Save as CSV (or Excel)
write.xlsx(conversion_map_2020, "conversion_map_2020.xlsx")

# -------------
library(dplyr)

censuskor <- read.csv(
  "censuskor.csv") %>%
  mutate(adm3=NA, adm3_en=NA, adm3_code=NA) %>%
  dplyr::select(
    year,
    adm1, adm1_code,
    adm2, adm2_code,
    adm3, adm3_en, adm3_code,
    type, class1, class2, unit, value
  )

# Administrative region code-to-name lookup table
adm_lookup <- censuskor %>%
  select(adm1, adm1_code, adm2, adm2_code, year) %>%
  filter(
    year == 2020,
    !is.na(adm1_code),
    !is.na(adm2_code),
    adm1_code != "",
    adm2_code != ""
  ) %>%
  select(-year) %>%
  distinct()

censuskor_adm3_2020 <- bind_rows(
  vital_emd,
  population_emd,
  housing_emd,
  business_emd
) %>%
  filter(year == 2020) %>%
  mutate(
    adm3_code = as.integer(adm3_code),
    adm1_code = as.integer(substr(adm3_code, 1, 2)),
    adm2_code = as.integer(substr(adm3_code, 1, 5))
  ) %>%
  left_join(
    adm_lookup,
    by = c("adm1_code", "adm2_code")
  )





# --- Administrative Dong English Translation ---
# 1. Read the English translation file (EUC-KR encoding)
sgis_en <- read.csv("국가데이터처_SGIS_행정동영문_20241231.csv", fileEncoding = "euc-kr", stringsAsFactors = FALSE)
names(sgis_en) <- c("sido_ko", "sigungu_ko", "adm3_ko", "sido_en", "sigungu_en", "adm3_en", "address_en")

# 2. Define helper functions
clean_sigungu <- function(x) {
  x <- tolower(x)
  # Replace hyphens and punctuation with spaces to separate words
  x <- gsub("[[:punct:]]+", " ", x)
  # Extract the first word
  first_token <- sapply(strsplit(x, "\\s+"), function(tokens) tokens[1])
  # Remove common administrative suffixes
  first_token <- gsub("si$", "", first_token)
  first_token <- gsub("gu$", "", first_token)
  first_token <- gsub("gun$", "", first_token)
  first_token <- gsub("city$", "", first_token)
  # Fix spelling variations
  first_token <- gsub("^sebuk$", "seobuk", first_token)
  # For Bucheon-si, consolidate Wonmi-gu, Sosa-gu, and Ojeong-gu into "bucheon"
  first_token <- ifelse(grepl("bucheon", x), "bucheon", first_token)
  return(first_token)
}

clean_dong <- function(x) {
  x <- gsub("[[:space:][:punct:]·?]+", "", x)
  x <- gsub("제([0-9]+)동$", "\\1동", x)
  x <- gsub("룡", "용", x)
  x <- gsub("능", "릉", x)
  x <- gsub("여의도", "여의", x)
  return(x)
}

root_dong <- function(x) {
  x <- clean_dong(x)
  x <- gsub("(동|읍|면)$", "", x)
  x <- gsub("[0-9]+$", "", x)
  return(x)
}

# SGIS data preprocessing
sgis_prep <- sgis_en %>%
  mutate(
    sido_en_mapped = case_when(
      sido_en == "Gangwon State" ~ "Gangwon-do",
      sido_en == "Jeju" ~ "Jeju-do",
      sido_en == "Jeonbuk-State" ~ "Jeollabuk-do",
      sido_en == "Sejong City" ~ "Sejong",
      TRUE ~ sido_en
    ),
    sido_clean = sido_en_mapped,
    sigungu_clean = clean_sigungu(sigungu_en),
    adm3_clean = clean_dong(adm3_ko),
    adm3_root = root_dong(adm3_ko)
  ) %>%
  distinct(sido_clean, sigungu_clean, sigungu_en, adm3_clean, adm3_root, adm3_en)

# 3. Fill in missing administrative names (for counties, etc.)
sido_code_map <- c(
  "11" = "Seoul", "21" = "Busan", "22" = "Daegu", "23" = "Incheon",
  "24" = "Gwangju", "25" = "Daejeon", "26" = "Ulsan", "29" = "Sejong",
  "31" = "Gyeonggi-do", "32" = "Gangwon-do", "33" = "Chungcheongbuk-do",
  "34" = "Chungcheongnam-do", "35" = "Jeollabuk-do", "36" = "Jeollanam-do",
  "37" = "Gyeongsangbuk-do", "38" = "Gyeongsangnam-do", "39" = "Jeju-do"
)

# Fill missing Sido names (adm1)
censuskor_adm3_2020 <- censuskor_adm3_2020 %>%
  mutate(
    adm1 = ifelse(is.na(adm1), sido_code_map[as.character(adm1_code)], adm1)
  )

# Fill missing Sigungu names (adm2) via SGIS lookup
sigungu_lookup <- sgis_prep %>%
  select(sido_clean, adm3_root, sigungu_en) %>%
  distinct(sido_clean, adm3_root, .keep_all = TRUE)

census_with_missing_adm2 <- censuskor_adm3_2020 %>%
  filter(is.na(adm2)) %>%
  mutate(
    sido_clean = adm1,
    # Gunwi-gun (37510/37310) was transferred to Daegu in 2023. Map it to Daegu for SGIS lookup.
    sido_clean = ifelse(adm2_code %in% c(37310, 37510), "Daegu", sido_clean),
    adm3_root = root_dong(adm3)
  ) %>%
  left_join(sigungu_lookup, by = c("sido_clean", "adm3_root")) %>%
  mutate(adm2 = sigungu_en) %>%
  select(-sido_clean, -adm3_root, -sigungu_en)

census_ok <- censuskor_adm3_2020 %>%
  filter(!is.na(adm2))

censuskor_adm3_2020 <- bind_rows(census_ok, census_with_missing_adm2)

# Fallback exception handling for remaining missing Sigungus (due to renames like Yeongwol-gun and Gunwi-gun)
sigungu_fallback_map <- c(
  "32530" = "Yeongwol-gun",
  "37510" = "Gunwi-gun"
)
censuskor_adm3_2020 <- censuskor_adm3_2020 %>%
  mutate(
    adm2 = ifelse(is.na(adm2), sigungu_fallback_map[as.character(adm2_code)], adm2)
  )

# 4. Perform Eupmyeondong English matching (Stage 1, 3, and Fallback)
census_to_match <- censuskor_adm3_2020 %>%
  mutate(
    sido_clean = adm1,
    sido_clean = ifelse(tolower(adm2) == "gunwi-gun", "Daegu", sido_clean),
    sigungu_clean = clean_sigungu(adm2),
    adm3_clean = clean_dong(adm3),
    adm3_root = root_dong(adm3)
  )

# Stage 1: Exact Clean Join
matched_s1 <- census_to_match %>%
  left_join(sgis_prep %>% select(-adm3_root), by = c("sido_clean", "sigungu_clean", "adm3_clean"))

# Stage 3: Root-based Join (for split/merged dongs)
unmatched_s1 <- matched_s1 %>% filter(is.na(adm3_en)) %>% select(-adm3_en)
matched_s1_ok <- matched_s1 %>% filter(!is.na(adm3_en))

matched_s3 <- unmatched_s1 %>%
  left_join(sgis_prep %>% select(-adm3_clean), by = c("sido_clean", "sigungu_clean", "adm3_root"))

# Correction function for English number representations in Stage 3
clean_english_number <- function(en_name, orig_dong) {
  orig_num <- regmatches(orig_dong, regexpr("[0-9]+", orig_dong))
  matched_num <- regmatches(en_name, regexpr("[0-9]+", en_name))

  en_name <- gsub("Opp", "Opo", en_name)
  en_name <- gsub("opp", "opo", en_name)

  if (length(orig_num) > 0 && length(matched_num) == 0) {
    num_word <- case_when(
      orig_num == "1" ~ "1(il)", orig_num == "2" ~ "2(i)", orig_num == "3" ~ "3(sam)",
      orig_num == "4" ~ "4(sa)", orig_num == "5" ~ "5(o)", orig_num == "6" ~ "6(yuk)",
      orig_num == "7" ~ "7(chil)", orig_num == "8" ~ "8(pal)", orig_num == "9" ~ "9(gu)",
      orig_num == "10" ~ "10(sip)", TRUE ~ orig_num
    )
    en_name <- gsub("-dong$", paste0(" ", num_word, "-dong"), en_name)
  } else if (length(orig_num) == 0 && length(matched_num) > 0) {
    en_name <- gsub(" ?[0-9]+\\([a-z]+\\)-", "-", en_name)
  }
  return(en_name)
}

clean_en_vector <- function(en_names, orig_dongs) {
  mapply(clean_english_number, en_names, orig_dongs, USE.NAMES = FALSE)
}

matched_s3 <- matched_s3 %>%
  mutate(
    adm3_en = clean_en_vector(adm3_en, adm3)
  )

# Fallback Dictionary (mapping remaining unmatched dongs due to complete name changes or splits)
translate_fallback <- function(adm3) {
  name_stripped <- gsub("[[:space:][:punct:]·?]+", "", adm3)
  dict <- c(
    "북성동" = "Bukseong-dong", "송월동" = "Songwol-dong", "부천동" = "Bucheon-dong",
    "신중동" = "Sinjung-dong", "대산동" = "Daesan-dong", "범안동" = "Beoman-dong",
    "송산동" = "Songsan-dong", "풍산동" = "Pungsan-dong", "역삼동" = "Yeoksam-dong",
    "진동면" = "Jindong-myeon", "군내면" = "Gunnae-myeon", "능서면" = "Neungseo-myeon",
    "동면" = "Dong-myeon", "중동면" = "Jungdong-myeon", "남면" = "Nam-myeon",
    "양북면" = "Yangbuk-myeon", "고로면" = "Goro-myeon", "용지동" = "Yongji-dong",
    "군위읍" = "Gunwi-eup", "소보면" = "Sobo-myeon", "효령면" = "Horyeong-myeon",
    "부계면" = "Bugye-myeon", "우보면" = "Ubo-myeon", "의흥면" = "Uiheung-myeon",
    "산성면" = "Sanseong-myeon"
  )
  res <- dict[name_stripped]
  return(ifelse(is.na(res), NA_character_, res))
}

matched_s3 <- matched_s3 %>%
  mutate(
    adm3_en = ifelse(is.na(adm3_en), translate_fallback(adm3), adm3_en)
  ) %>% select(-adm3)

# Final combination and column selection
censuskor_adm3_2020 <- bind_rows(
  matched_s1_ok,
  matched_s3
) %>%
  dplyr::select(
    year,
    adm1, adm1_code,
    adm2, adm2_code,
    adm3=adm3_en, adm3_code,
    type, class1, class2, unit, value
  )

write.xlsx(censuskor_adm3_2020, "censuskor_adm3_2020.xlsx")
write.csv(censuskor_adm3_2020, "censuskor_adm3_2020.csv", row.names = FALSE)

censuskor <- rbind(censuskor, censuskor_adm3_2020)
write.csv(censuskor, "censuskor.csv", row.names = FALSE)
