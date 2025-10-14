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

census_pop_2020 <- df_pop |>
  rename(population_total = `all households_total_prs`)
census_housing_2020 <- anycensus(year = 2020, codes = NULL, type = "housing")
census_housing_2020 <- df_hou |>
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
  dplyr::mutate(adm2_code_ = paste0(substr(adm2_code, 1, 4), "0")) |>
  dplyr::group_by(adm2_code_) |>
  dplyr::summarize(
    dplyr::across(
      dplyr::matches("households|income|housing"),
      sum
    ),
    dplyr::across(
      dplyr::matches("causes"),
      mean
    )
  ) |>
  transmute(
    adm2_code_ = adm2_code_,
    persons_per_housing = `all households_total_prs` / `housing types_total_cnt`,
    tax_income_per_capita = `income_general_mkr` / `all households_total_prs`,
    tax_labor_per_capita = `income_labor_mkr` / `all households_total_prs`,
    tax_income = `income_general_mkr`,
    tax_labor = `income_labor_mkr`,
    sex_ratio = 100 * `all households_male_prs` / `all households_female_prs`,
    mortality_rate = `all causes_total_p1p`
  )

prc_df <-
  prcomp(df_wide_re[,c(-1, -5, -6)], scale = TRUE)
prc_df$rotation |> as.data.frame() |> round(3) |> write.csv("tools/loading.csv")
prc_df$scale
prc_df$x
biplot(prc_df)

pca_rot <- as.data.frame(prc_df$x) |>
  dplyr::rename(pc1_rurality = PC1, pc2_health = PC2, pc5_asset = PC5, pc7_tax = PC7)
df_wide_pca <- df_wide_re |>
  dplyr::bind_cols(pca_rot)


adm2_2020 <- load_districts(2020) |>
  dplyr::mutate(adm2_code_ = paste0(substr(adm2_code, 1, 4), "0")) |>
  dplyr::group_by(adm2_code_) |>
  dplyr::summarize(adm2_code = first(adm2_code)) |>
  dplyr::ungroup()
gg_pc1_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, pc1_rurality, pc2_health, pc5_asset),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = pc1_rurality), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based rurality index",
    subtitle = "Principal Component 1 from multiple census variables",
    fill = "PC1 (rurality)"
  )
gg_pc5_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, pc1_rurality, pc2_health, pc5_asset),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = pc5_asset), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based asset index",
    subtitle = "Principal Component 5 from multiple census variables",
    fill = "PC5 (assets)"
  )
gg_pc7_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, pc1_rurality, pc2_health, pc5_asset, pc7_tax),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = pc7_tax), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based tax index",
    subtitle = "Principal Component 7 from multiple census variables",
    fill = "PC7 (tax)"
  )
gg_pc4_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, pc1_rurality, pc2_health, PC4),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = PC4), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based asset index",
    subtitle = "Principal Component 4 from multiple census variables",
    fill = "PC4 (?)"
  )

library(factoextra)
factoextra::fviz_pca(prc_df)
factoextra::fviz_pca_var(prc_df)
