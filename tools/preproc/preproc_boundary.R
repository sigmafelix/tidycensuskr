library(sf)
library(janitor)
library(V8)
library(stringi)
sf_use_s2(F)

sf_sgg_2020 <-
  read_sf("/mnt/s/Korea/basemap/data/census/bnd_all_00_2020_4Q/bnd_sigungu_00_2020_4Q/bnd_sigungu_00_2020_4Q.shp") %>%
  st_transform(5179) %>%
  st_make_valid()

save(sf_sgg_2020, file = "inst/sgg2020.RData", compress = "xz")

# Transliterate Korean text to Latin script
# without considering pronunciation rules
stringi::stri_trans_general("학여울", "Hangul-Latin")
stringi::stri_trans_general("항녀울", "Hang-Latn")
stringi::stri_trans_general("종로구", "Hang-Latn")
grep("Hang", stringi::stri_trans_list(), value = TRUE)
