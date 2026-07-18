# version 0.3.0 patch
# 8-digit ADM3 code cleaning
# rule: drop the trailing 0 in the adm3 code + Gun-level code (the third digit) subtracted by 2

library(tidycensuskr)
library(dplyr)


data(censuskor)

censuskordf <-
  censuskor |>
  dplyr::mutate(
    adm3_code = ifelse(
      nchar(adm3_code) == 8,
      ifelse(
        as.integer(substr(adm3_code, 3, 3)) >= 5L,
        paste0(substr(adm3_code, 1, 2), as.integer(substr(adm3_code, 3, 3)) - 2L, substr(adm3_code, 4, 7)),
        paste0(substr(adm3_code, 1, 2), substr(adm3_code, 3, 7))
      ),
      adm3_code
    )
  )

unique(censuskordf$adm3_code)
duplicated(unique(censuskordf$adm3_code))

censuskor <- censuskordf
usethis::use_data(censuskor, overwrite = TRUE)

## conversion table inspection
library(readxl)
cm20 <- read_excel("tools/conversion_map_2020.xlsx")

names(cm20)
cm20x <- cm20 |>
  dplyr::mutate(
    dplyr::across(
      dplyr::starts_with("code_"),
      ~ 
        ifelse(
          nchar(.x) == 8,
          ifelse(
            as.integer(substr(.x, 3, 3)) >= 5L,
            paste0(substr(.x, 1, 2), as.integer(substr(.x, 3, 3)) - 2L, substr(.x, 4, 7)),
            paste0(substr(.x, 1, 2), substr(.x, 3, 7))
          ),
          .x
        )
    )
   )
cm20xx <- cm20x |>
  dplyr::rowwise() |>
  dplyr::mutate(
    test_code = list(c(code_vital, code_census, code_business)),
    is_code_equal = length(unique(test_code)) == 1
  )

cm20xx |>
  dplyr::filter(!is_code_equal) |>
  as.data.frame()
