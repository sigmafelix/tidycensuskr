library(stringi)
library(dplyr)

sgg_lookup <- read.csv("inst/extdata/lookup_district_code.csv", fileEncoding = "utf-8")
sgg_lookup_abr <-
  sgg_lookup |>
  dplyr::select(
    sido_kr, sigungu_kr, sido_en, sigungu_2_en,
    base_year, adm2_code
  ) |>
  dplyr::mutate(
    sido_kr = gsub("강원특별자치도", "강원도", sido_kr)
  )
joinby <- dplyr::join_by(adm1kr == sido_kr, adm2kr == sigungu_kr, year <= base_year)

## Living Security ####
wf_living <- read.csv("tools/basic_living_security.csv") |>
  dplyr::mutate(
    adm2kr = gsub("세종특별자치시", "세종시", adm2kr)
  ) |>
  dplyr::left_join(sgg_lookup_abr, by = joinby) |>
  dplyr::select(-1, -2, -3, -4, -5, -base_year) |>
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_2_en,
    class2 = sex) |>
  dplyr::mutate(
    class2 = ifelse(class2 == "남성", "male", "female"),
    unit = "persons",
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::group_by(year, adm1, adm1_code, adm2, adm2_code, type, class1, class2, unit) |>
  dplyr::summarise(
    value = sum(value)
  ) |>
  dplyr::ungroup()

# wf_living |>
#   dplyr::filter(is.na(adm2_code)) |>
#   _[, c("adm1kr", "adm2kr")] |>
#   distinct()


## Basic Pension ####
wf_pension <- read.csv("tools/basic_pension.csv") |>
  dplyr::mutate(
    adm2kr = gsub("세종특별자치시", "세종시", adm2kr)
  ) |>
  dplyr::left_join(sgg_lookup_abr, by = joinby) |>
  # dplyr::select(-1, -2, -3, -4, -5, -base_year) |>
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_2_en,
    class2 = sex_type) |>
  dplyr::mutate(
    class2 = ifelse(class2 == "남성", "male", "female"),
    unit = "persons",
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::select(
    year, adm1, adm1_code, adm2, adm2_code,
    type, class1, class2, value, unit
  )


## Facilities ####
wf_fac <- read.csv("tools/welfare_facilities.csv") |>
  dplyr::mutate(
    adm2kr = gsub("세종특별자치시", "세종시", adm2kr)
  ) |>
  dplyr::left_join(sgg_lookup_abr, by = joinby) |>
  # dplyr::select(-1, -2, -3, -4, -5, -base_year) |>
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_2_en,
    class2 = facility_type) |>
  dplyr::mutate(
    class2 = dplyr::case_when(
      class2 == "생활시설" ~ "residential facility",
      class2 == "이용시설" ~ "service facility",
      class2 == "기타" ~ "other facility",
      TRUE ~ class2
    ),
    unit = "count",
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::select(
    year, adm1, adm1_code, adm2, adm2_code,
    type, class1, class2, value, unit
  ) |>
  dplyr::filter(!is.na(adm2_code))


## Physically and mentally challenged ####
wf_challenged <- read.csv("tools/registered_pm_challenged.csv") |>
  dplyr::mutate(
    adm2kr = gsub("세종특별자치시", "세종시", adm2kr)
  ) |>
  dplyr::left_join(sgg_lookup_abr, by = joinby) |>
  # dplyr::select(-1, -2, -3, -4, -5, -base_year) |>
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_2_en,
    class2_1 = sex,
    class2_2 = age_group) |>
  dplyr::mutate(
    class2_1 = dplyr::case_when(
      class2_1 == "여자" ~ "female",
      class2_1 == "남자" ~ "male",
      TRUE ~ class2_1
    ),
    class2_2 = cut(class2_2, breaks = c(-Inf, 19, 39, 64, 79, Inf),
                    labels = c("0-19", "20-39", "40-64", "65-79", "80+")),
    class2 = paste(class2_1, class2_2, sep = "_"),
    unit = "persons",
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::group_by(year, adm1, adm1_code, adm2, adm2_code, type, class1, class2, unit) |>
  dplyr::summarise(
    value = sum(value)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    year, adm1, adm1_code, adm2, adm2_code,
    type, class1, class2, value, unit
  )

## Physically and Mentally Challenged by Severity ####
wf_challenged_severity <- read.csv("tools/registered_pm_challenged_severity.csv") |>
  dplyr::mutate(
    adm2kr = gsub("세종특별자치시", "세종시", adm2kr)
  ) |>
  dplyr::left_join(sgg_lookup_abr, by = joinby) |>
  # dplyr::select(-1, -2, -3, -4, -5, -base_year) |>
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_2_en,
    class2_1 = severity_level,
    class2_2 = age_group
  ) |>
  dplyr::mutate(
    class2_1 = dplyr::case_when(
      class2_1 == "심한 장애" ~ "severely impaired",
      class2_1 == "심하지 않은 장애" ~ "less severely impaired",
      TRUE ~ class2_1
    ),
    class2_2 = cut(class2_2, breaks = c(-Inf, 19, 39, 64, 79, Inf),
                    labels = c("0-19", "20-39", "40-64", "65-79", "80+")),
    class2 = paste(class2_1, class2_2, sep = "_"),
    unit = "persons",
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::group_by(year, adm1, adm1_code, adm2, adm2_code, type, class1, class2, unit) |>
  dplyr::summarise(
    value = sum(value)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    year, adm1, adm1_code, adm2, adm2_code,
    type, class1, class2, value, unit
  )


## combine all welfare data ####
welfare_data <-
  list(
    wf_living,
    wf_pension,
    wf_fac,
    wf_challenged,
    wf_challenged_severity
  ) |>
  collapse::rowbind(fill = TRUE)
