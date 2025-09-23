# PCA demonstration with multiple variables
library(tidycensuskr)
library(dplyr)
library(ggplot2)


# Load data
sf_2020 <- load_districts(year = 2020)

#
df_hou <- anycensus(year = 2020, type = "housing", level = "adm2")
df_pop <- anycensus(year = 2020, type = "population", level = "adm2")
df_mort <- anycensus(year = 2020, type = "mortality", level = "adm2")
df_eco <- anycensus(year = 2020, type = "economy", level = "adm2")
df_tax <- anycensus(year = 2020, type = "tax", level = "adm2")


census_housing_2020 <- anycensus(year = 2020, codes = NULL, type = "housing")
census_housing_2020 <- census_housing_2020 |>
  rename(housing_total_units = `housing types_total_cnt`)
census_pop_housing_2020 <- census_pop_2020 |>
  left_join(census_housing_2020 |>
              select(adm2_code, housing_total_units),
            by = "adm2_code") |>
  transmute(
    adm2_code = adm2_code,
    persons_per_housing = population_total / housing_total_units
  )

data(censuskor)

df_wide <- Reduce(
    function(x, y) left_join(
        x, y,
        by = c("adm1", "adm1_code", "adm2", "adm2_code", "year")
    ),
    list(
        df_hou,
        df_pop,
        df_mort,
        df_eco
    )
)
df_wide <- df_wide |>
  dplyr::select(-dplyr::starts_with("type")) |>
  dplyr::mutate(
    adm2_code = paste0(substr(adm2_code, 1, 4), "0")
  ) |>
  dplyr::select(-adm2) |>
  dplyr::group_by(year, adm1, adm1_code, adm2_code) |>
  dplyr::summarize(
    dplyr::across(
      .cols = where(is.numeric),
      .fns = sum,
      .names = "{.col}"
    )
  ) |>
  dplyr::ungroup()
df_wide <- df_wide |>
  dplyr::mutate(adm2_code = as.integer(adm2_code)) |>
  dplyr::left_join(df_tax)
df_wide_re <-
  df_wide |>
  mutate(
    persons_per_housing = `all households_total_prs` / `housing types_total_cnt`,
    tax_income_per_capita = `income_general_mkr` / `all households_total_prs`,
    tax_labor_per_capita = `income_labor_mkr` / `all households_total_prs`
  ) |>
  dplyr::select(-type, -adm2)

prc_df <-
  prcomp(df_wide_re[, -1:-4], center = TRUE, scale = TRUE)
biplot(prc_df)
