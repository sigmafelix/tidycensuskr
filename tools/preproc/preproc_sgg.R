library(sf)
library(dplyr)

sf_use_s2(FALSE)

sgg2010 <- st_read("/home/felix/Documents/census_boundaries/sgg2010.gpkg")
sf_sgg_2010 <- sgg2010 %>%
  transmute(
    year = as.character(BASE_YEAR),
    adm2_code = as.integer(SIGUNGU_CD)
  )
saveRDS(sf_sgg_2010, file = "inst/extdata/adm2_sf_2010.rds", compress = "xz")

sgg2015 <- st_read("/home/felix/Documents/census_boundaries/sgg2015.gpkg")
sf_sgg_2015 <- sgg2015 %>%
  transmute(
    year = as.character(BASE_YEAR),
    adm2_code = as.integer(SIGUNGU_CD)
  )
saveRDS(sf_sgg_2015, file = "inst/extdata/adm2_sf_2015.rds", compress = "xz")


load("inst/extdata/sgg2020.RData")
sf_sgg_2020 <-
  sf_sgg_2020 %>%
  transmute(
    year = 2020L,
    adm2_code = as.integer(SIGUNGU_CD)
  )
saveRDS(sf_sgg_2020, file = "inst/extdata/adm2_sf_2020.rds", compress = "xz")


# save(
#   sf_sgg_2010,
#   sf_sgg_2015,
#   sf_sgg_2020,
#   file = "inst/extdata/adm2_sf_korea.RData",
#   compress = "xz"
# )
