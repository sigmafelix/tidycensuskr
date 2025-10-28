## Korea geofacet grid at province level
library(ggplot2)
library(geofacet)

grid_kor_province <- data.frame(
  name = c(
    "Seoul", "Incheon", "Gyeonggi",
    "Gangwon",
    "Chungbuk", "Daejeon", "Chungnam",
    "Jeonbuk", "Gwangju", "Jeonnam",
    "Daegu", "Gyeongbuk",
    "Busan", "Ulsan", "Gyeongnam",
    "Jeju"
  ),
  code = c(
    "11", "28", "41",
    "42",
    "43", "30", "44",
    "45", "29", "46",
    "27", "47",
    "26", "31", "48",
    "50"
  ),
  row = c(
    1, 1, 2,
    1,
    3, 3, 4,
    5, 4, 6,
    2, 3,
    2, 3, 4,
    5
  ),
  col = c(
    3, 2, 3,
    5,
    3, 2, 4,
    2, 1, 2,
    5, 6,
    6, 7, 7,
    1
  )
)


## Create the geofacet grid at district level
grid_seoul_district <- data.frame(
  name = c(
    "Jongno-gu", "Jung-gu", "Yongsan-gu", "Seongdong-gu", "Gwangjin-gu", "Dongdaemun-gu", "Jungnang-gu",
    "Seongbuk-gu", "Gangbuk-gu", "Dobong-gu", "Nowon-gu", "Eunpyeong-gu", "Seodaemun-gu", "Mapo-gu", "Yangcheon-gu", "Gangseo-gu",
    "Guro-gu", "Geumcheon-gu", "Yeongdeungpo-gu", "Dongjak-gu", "Gwanak-gu", "Seocho-gu", "Gangnam-gu", "Songpa-gu", "Gangdong-gu"
  ),
  # adm2_code stored in censuskor dataset
  code = c(
    11010, 11020, 11030, 11040, 11050, 11060, 11070,
    11080, 11090, 11100, 11110, 11120, 11130, 11140, 11150, 11160,
    11200, 11210, 11220, 11230, 11240, 11250, 11260, 11270, 11280
  ),
  row = c(
    1, 2, 2, 3, 3, 4, 4,
    5, 5, 6, 6, 7, 7, 8, 8, 9,
    10, 10, 11, 11, 12, 12, 13, 13
  ),
  col = c(
    4, 4, 5, 5, 6, 6, 7,
    4, 5, 4, 5, 4, 5, 4, 5, 4,
    4, 5, 4, 5, 4, 5, 4, 5
  )
)


library(geofacet)
data(kr_counties_districts_cities_grid1)
kr_counties_districts_cities_grid1
geofacet::ar_buenos_aires_prov_electoral_dist_grid1

krcg <- kr_counties_districts_cities_grid1
krcg

# read lookup table
lookup <- readr::read_csv("tools/adm_sgis_lookup_2024.csv", col_select = c("sgis_2010", "sgis_2015", "sgis_2020", "adm10", "level", "name_eng"), col_types = "cccccc")

# Gangwon: 42 to 51, Jeonbuk: 45 to 52
# lookup table workflow
# erroneous data type resolution in read_csv
# adm10 is converted to oldcode
# Backward conversion from "State" codes to "Province" codes
#  in Gangwon and Jeonbuk only
lookup10 <- lookup |>
  dplyr::filter(grepl("District", level)) |>
  dplyr::rename(code = sgis_2010) |>
  dplyr::transmute(
    name = name_eng,
    code = substr(code, 1, 5),
    oldcode = as.character(adm10)
  ) |>
  dplyr::mutate(oldcode = gsub("e\\+08", "00", oldcode)) |>
  dplyr::mutate(oldcode = gsub("\\.", "", oldcode)) |>
  dplyr::mutate(oldcode = substr(oldcode, 1, 5)) |>
  dplyr::mutate(
    oldcode = dplyr::case_when(
      substr(oldcode, 1, 2) == "51" ~ paste0("42", substr(oldcode, 3, 5)),
      substr(oldcode, 1, 2) == "52" ~ paste0("45", substr(oldcode, 3, 5)),
      TRUE ~ oldcode
    )
  )

lookup15 <- lookup |>
  dplyr::filter(grepl("District", level)) |>
  dplyr::rename(code = sgis_2015) |>
  dplyr::transmute(
    name = name_eng,
    code = substr(code, 1, 5),
    oldcode = as.character(adm10)
  ) |>
  dplyr::mutate(oldcode = gsub("e\\+08", "00", oldcode)) |>
  dplyr::mutate(oldcode = gsub("\\.", "", oldcode)) |>
  dplyr::mutate(oldcode = substr(oldcode, 1, 5)) |>
  dplyr::mutate(
    # change only the first two digits for Gangwon and Jeonbuk
    oldcode = dplyr::case_when(
      substr(oldcode, 1, 2) == "51" ~ paste0("42", substr(oldcode, 3, 5)),
      substr(oldcode, 1, 2) == "52" ~ paste0("45", substr(oldcode, 3, 5)),
      TRUE ~ oldcode
    )
  )

lookup20 <- lookup |>
  dplyr::filter(grepl("District", level)) |>
  dplyr::rename(code = sgis_2020) |>
  dplyr::transmute(
    name = name_eng,
    code = substr(code, 1, 5),
    oldcode = as.character(adm10)
  ) |>
  dplyr::mutate(oldcode = gsub("e\\+08", "00", oldcode)) |>
  dplyr::mutate(oldcode = gsub("\\.", "", oldcode)) |>
  dplyr::mutate(oldcode = substr(oldcode, 1, 5)) |>
  dplyr::mutate(
    # change only the first two digits for Gangwon and Jeonbuk
    oldcode = dplyr::case_when(
      substr(oldcode, 1, 2) == "51" ~ paste0("42", substr(oldcode, 3, 5)),
      substr(oldcode, 1, 2) == "52" ~ paste0("45", substr(oldcode, 3, 5)),
      TRUE ~ oldcode
    )
  )


# target: two versions
# 1. SGIS standard (all nonautonomous districts in cities are retained)
# 2. MOIS standard (nonautonomous districts in cities are merged into the city)
#   - TODO: reorganize MOIS grids
class(krcg) <- "data.frame"
krcg2010 <- krcg |>
  dplyr::select(-name) |>
  dplyr::rename(oldcode = code) |>
  dplyr::mutate(oldcode = as.character(oldcode)) |>
  dplyr::left_join(lookup10, by = "oldcode")
message("NA SGIS codes (2010): ", sum(is.na(krcg2010$code)))
krcg2010 |>
  dplyr::filter(is.na(code)) |>
  dplyr::select(code, oldcode, name)
# Michuhol (MOIS: 28177) to Nam-gu (SGIS: 23030)
# Sejong-si (MOIS: 36110) to Yeongi-gun (SGIS: 34320)
# Yeoju-si (MOIS: 41670) to Yeoju-gun (SGIS: 31280)
# Seowon-gu (MOIS: 43112): Remove
# Cheongwon-gu (MOIS: 43114): Remove
# Add: Cheongwon-gun (SGIS: 33310); Requires manual modification in grids
# Dangjin-si (MOIS: 44270) to Dangjin-gun (SGIS: 34390)
krcg2010 <- krcg2010 |>
  dplyr::mutate(
    code = dplyr::case_when(
      oldcode == "28177" ~ "23030",
      oldcode == "36110" ~ "34320",
      oldcode == "41670" ~ "31280",
      oldcode == "44270" ~ "34390",
      TRUE ~ code
    ),
    name = dplyr::case_when(
      oldcode == "28177" ~ "Nam-gu",
      oldcode == "36110" ~ "Yeongi-gun",
      oldcode == "41670" ~ "Yeoju-gun",
      oldcode == "44270" ~ "Dangjin-gun",
      TRUE ~ name
    )
  )


krcg2010 <- krcg2010 |>
  dplyr::mutate(
    code = dplyr::case_when(
      oldcode == "28177" ~ "23030",
      TRUE ~ code
    ),
    name = dplyr::case_when(
      oldcode == "28177" ~ "Nam-gu",
      TRUE ~ name
    )
  )



krcg2015 <- krcg |>
  dplyr::select(-name) |>
  dplyr::rename(oldcode = code) |>
  dplyr::mutate(oldcode = as.character(oldcode)) |>
  dplyr::left_join(lookup15, by = "oldcode")
message("NA SGIS codes (2015): ", sum(is.na(krcg2015$code)))
krcg2015 |>
  dplyr::filter(is.na(code)) |>
  dplyr::select(code, oldcode, name)
# Michuhol (MOIS: 28177) to Nam-gu (SGIS: 23030)
krcg2015 <- krcg2015 |>
  dplyr::mutate(
    code = dplyr::case_when(
      oldcode == "28177" ~ "23030",
      TRUE ~ code
    ),
    name = dplyr::case_when(
      oldcode == "28177" ~ "Nam-gu",
      TRUE ~ name
    )
  )

krcg2020 <- krcg |>
  dplyr::select(-name) |>
  dplyr::rename(oldcode = code) |>
  dplyr::mutate(oldcode = as.character(oldcode)) |>
  dplyr::left_join(lookup20, by = "oldcode")
message("NA SGIS codes (2020): ", sum(is.na(krcg2020$code)))

