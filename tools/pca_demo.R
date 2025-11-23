# PCA demonstration with multiple variables
library(tidycensuskr)
library(dplyr)
library(ggplot2)
library(janitor)

# Load data
sf_2020 <- load_districts(year = 2020)

#
df_hou <- anycensus(year = 2020, type = "housing", level = "adm2")
df_pop <- anycensus(year = 2020, type = "population", level = "adm2")
df_mort <- anycensus(year = 2020, type = "mortality", level = "adm2")
df_eco <- anycensus(year = 2020, type = "economy", level = "adm2")
df_tax <- anycensus(year = 2020, type = "tax", level = "adm2")
df_ss <- anycensus(year = 2020, type = "social security", level = "adm2")

df_eco_x <- df_eco |>
  janitor::clean_names() |>
  dplyr::select(-8:-10) |>
  # fill NA values with 0
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), 0, .)))

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
    df_eco_x,
    df_ss
  )
) |>
  dplyr::select(-type)
# df_wide <- df_wide |>
#   dplyr::select(-dplyr::starts_with("type")) |>
#   dplyr::mutate(
#     adm2_code = paste0(substr(adm2_code, 1, 4), "0")
#   ) |>
#   dplyr::select(-adm2) |>
  # dplyr::group_by(year, adm1, adm1_code, adm2_code) |>
  # dplyr::summarize(
  #   dplyr::across(
  #     .cols = where(is.numeric),
  #     .fns = sum,
  #     .names = "{.col}"
  #   )
  # ) |>
  # dplyr::ungroup()
df_wide <- df_wide |>
  dplyr::mutate(adm2_code = as.integer(adm2_code)) |>
  dplyr::left_join(df_tax)
df_wide_re <-
  df_wide |>
  dplyr::mutate(adm2_code_ = paste0(substr(adm2_code, 1, 4), "0")) |>
  dplyr::group_by(adm2_code_) |>
  dplyr::summarize(
    dplyr::across(
      dplyr::matches("households|income|housing|grdp"),
      sum
    ),
    dplyr::across(
      dplyr::matches("fertility|causes"),
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
    mortality_rate = `all causes_total_p1p`,
    fertility_rate = fertility_total_brt,
    security_rate = 
    dplyr::across(
      dplyr::matches("grdp"),
      ~ .x / `all households_total_prs`
    )
  )

prc_df <-
  prcomp(df_wide_re[,c(-1, -3, -4, -5, -6)], scale = TRUE)
prc_df$rotation |> as.data.frame() |> round(3) |> write.csv("tools/loading.csv")
prc_df$rotation |> as.data.frame() |> round(3) |> _[, 1:10]
prc_df$scale
prc_df$sdev / sum(prc_df$sdev)
prc_df$x
biplot(prc_df)

# PC1 sparse; low wholesale and retail
# PC2 high mortality and fertility, agriculture, mining, pubadm
# PC3 lower sex ratio, low manufacturing, all high activity
# PC4 electricity
# PC5 high transportation and storage, high mortality, mining and quarrying

pca_rot <- as.data.frame(prc_df$x)
  # dplyr::rename(pc1_rurality = PC1, pc2_health = PC2, pc5_asset = PC5)
df_wide_pca <- df_wide_re |>
  dplyr::bind_cols(pca_rot)


adm2_2020 <- load_districts(2020) |>
  dplyr::mutate(adm2_code_ = paste0(substr(adm2_code, 1, 4), "0")) |>
  dplyr::group_by(adm2_code_) |>
  dplyr::summarize(adm2_code = first(adm2_code)) |>
  dplyr::ungroup()


gen_gg <- function(sf, pca, pc_num = 1) {
  colname <- paste0("PC", pc_num)
  gg_pc1_2020 <- adm2_2020 |>
    dplyr::left_join(
      df_wide_pca |>
        dplyr::select(dplyr::all_of(c("adm2_code_", colname))),
      by = "adm2_code_"
    ) |>
    ggplot() +
    geom_sf(aes(fill = !!sym(colname)), color = NA) +
    scale_fill_viridis_c() +
    theme_minimal() +
    theme(
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank()
    ) +
    labs(
      title = "PCA-based index",
      subtitle = paste0("Principal Component ", pc_num, " from multiple census variables"),
      fill = paste0(colname, " (rurality)")
    )
  gg_pc1_2020
}

gen_gg(sf_2020, df_wide_pca, pc_num = 1)
gen_gg(sf_2020, df_wide_pca, pc_num = 2)
gen_gg(sf_2020, df_wide_pca, pc_num = 3)
gen_gg(sf_2020, df_wide_pca, pc_num = 4)
gen_gg(sf_2020, df_wide_pca, pc_num = 5)
gen_gg(sf_2020, df_wide_pca, pc_num = 6)
gen_gg(sf_2020, df_wide_pca, pc_num = 9)

gg_pc1_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, PC1),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = PC1), color = NA) +
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
      dplyr::select(adm2_code_, PC5),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = PC5), color = NA) +
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
gg_pc2_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, PC2),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = PC2), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based asset index",
    subtitle = "Principal Component 2 from multiple census variables",
    fill = "PC2 (?)"
  )
gg_pc3_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, PC3),
    by = "adm2_code_"
  ) |>
  ggplot() +
  geom_sf(aes(fill = PC3), color = NA) +
  scale_fill_viridis_c() +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) +
  labs(
    title = "PCA-based construction index",
    subtitle = "Principal Component 3 from multiple census variables",
    fill = "PC3 (?)"
  )
gg_pc4_2020 <- adm2_2020 |>
  dplyr::left_join(
    df_wide_pca |>
      dplyr::select(adm2_code_, PC4),
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
    title = "PCA-based financial index",
    subtitle = "Principal Component 4 from multiple census variables",
    fill = "PC5 (financial)"
  )

library(factoextra)
factoextra::fviz_pca(prc_df)
factoextra::fviz_pca_var(prc_df)



## dirichlet clustering
library(DIRECT)

# subset grdp
df_eco_frac <-
  df_eco_x |>
  dplyr::select(adm2_code, dplyr::matches("^grdp_")) |>
  dplyr::filter(grdp_human_health_and_social_work_activities_mkr != 0)
df_eco_frac_rs <- rowSums(df_eco_frac[,-1])
df_eco_frac <-
  df_eco_frac |>
  dplyr::mutate(rowsum = df_eco_frac_rs) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    dplyr::across(
      dplyr::matches("^grdp_"),
      ~ ifelse(is.na(.x), 0, .x)
    ),
    dplyr::across(
      dplyr::matches("^grdp_"),
      ~ .x / rowsum
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-rowsum)

init_assign <- sample(1:nrow(df_eco_frac), nrow(df_eco_frac), replace = FALSE)
df_eco_clust_in <- as.data.frame(df_eco_frac[, -1])

df_eco_clust <-
  DIRECT::DIRECT(
    df_eco_clust_in,
    nTime = 1L,
    nIter = 5000,
    seed.value = 202511,
    c.curr = init_assign,
    burn.in = 2000,
    nResample = 100L,
    step.size = 4L,
    PRINT = TRUE
  )


library(dirichletprocess)
mat_eco_clust <- as.matrix(df_eco_clust_in)
dpCluster <-  DirichletProcessMvnormal(y = mat_eco_clust)
# dpCluster <- DirichletProcessGaussian(as.matrix(df_eco_clust_in))
# dpCluster <-  DirichletProcessBeta(as.matrix(df_eco_clust_in), maxY = 229)
dpCluster <- Fit(dpCluster, 2500, updatePrior = FALSE, progressBar = FALSE)
plot(dpCluster)
AlphaPriorPosteriorPlot(dpCluster)
AlphaTraceplot(dpCluster)

kmc2 <- lares::clusterKmeans(df_eco_clust_in)
kmc <- kmeans(mat_eco_clust, centers = 9, nstart = 20, iter.max = 5000L)

adm2_2020_cl <- adm2_2020 |>
  dplyr::mutate(
    clust6 = factor(kmc$cluster)
  )
plot(adm2_2020_cl["clust6"])
