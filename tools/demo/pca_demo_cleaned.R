## Date: 2025-11-30

# PCA demonstration with multiple variables
library(tidycensuskr)
library(dplyr)
library(ggplot2)
library(janitor)

# Load data
sf_2020 <- load_districts(year = 2020)

# housing
df_hou <- anycensus(year = 2020, type = "housing", level = "adm2")
df_hou <- df_hou |>
  dplyr::group_by(adm1_code, adm2_code, year, type) |>
  dplyr::mutate(dplyr::across(
    dplyr::everything(),
    ~ ifelse(is.na(.), .[which(!is.na(.))], .)
  )) |>
  dplyr::ungroup() |>
  dplyr::distinct()

# population
df_pop <- anycensus(year = 2020, type = "population", level = "adm2")

# mortality
df_mort <- anycensus(year = 2020, type = "mortality", level = "adm2")

# social security
df_ss <- anycensus(year = 2020, type = "social security", level = "adm2")


# Combine data frames
df_wide <- Reduce(
  function(x, y) left_join(
    x, y,
    by = c("adm1", "adm1_code", "adm2", "adm2_code", "year")
  ),
  list(
    df_hou,
    df_pop,
    df_mort,
    df_ss
  )
)# |>
 # dplyr::select(-type)


# reorganize the variables by basic local governments
df_wide_re <-
  df_wide |>
  dplyr::mutate(adm2_code_ = paste0(substr(adm2_code, 1, 4), "0")) |>
  dplyr::group_by(adm2_code_) |>
  dplyr::summarize(
    dplyr::across(
      dplyr::matches("households|income|housing|grdp|security"),
      ~ sum(.x, na.rm = TRUE)
    ),
    dplyr::across(
      dplyr::matches("fertility|causes"),
      ~ mean(.x, na.rm = TRUE)
    ),
    adm2 = dplyr::first(adm2)
  ) |>
  dplyr::ungroup() |>
  dplyr::transmute(
    adm2_code_ = adm2_code_,
    adm2 = adm2,
    persons_per_housing = `all households_total_prs` / `housing types_total_cnt`,
    sex_ratio = 100 * `all households_male_prs` / `all households_female_prs`,
    mortality_rate = `all causes_total_p1p`,
    fertility_rate = fertility_total_brt,
    security_rate = 100 * (`basic living security_female_prs` + `basic living security_male_prs`) /
      `all households_total_prs`
  )

# Run PCA
prc_df <-
  df_wide_re |>
  dplyr::select(3:7) |>
  as.data.frame() |>
  prcomp(scale = TRUE)

# Rotation by variables
prc_df$rotation |> as.data.frame() |> round(3)

# Proper labeling for biplot for BLGs
adm2labels <- paste0(df_wide_re$adm2, " (", df_wide_re$adm2_code_, ")")
rownames(prc_df$x) <- adm2labels

# Write a biplot using PC1 and PC3
png(
  "tools/pca_biplot.png",
  width = 2000, height = 1800,
  units = "px",
  pointsize = 6,
  res = 300
)
biplot(prc_df, choices = c(1, 3))
dev.off()
