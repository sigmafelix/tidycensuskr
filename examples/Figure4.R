## ---------------------------------------------------------------
## R (tidycensuskr >= 0.3.0; tidycensuskr.sf optional)
## ---------------------------------------------------------------
library(tidycensuskr)
library(dplyr)
library(sf)
library(tmap)
library(ggplot2)
library(geofacet)

## ---- Case 1a: choropleth map of the 2020 total population ----
pop2020 <- anycensus(year = 2020, type = "population", level = "adm2")
data(adm2_sf_2020)                 # 2020 ADM2 boundaries bundled in tidycensuskr

map2020 <- adm2_sf_2020 |>
  left_join(pop2020, by = "adm2_code")

tm_shape(map2020) +
  tm_polygons(
    "all households_total_prs",
    style = "quantile", n = 7, palette = "Blues",
    title = "Total population, 2020",
    border.col = "grey60", lwd = 0.2
  ) +
  tm_layout(frame = FALSE, legend.outside = TRUE)

## ---- Case 1b: small multiples of population by sex, 2010-2020 ----
data(censuskor)
data(kr_grid_adm2_sgis_2020)       # geofacet grid of the 2020 ADM2 units

# Population by sex at ADM2, with codes aligned to the 2020 unit set
pop <- censuskor |>
  filter(type == "population", class1 == "all households",
         class2 != "total", is.na(adm3_code)) |>
  rename(code = adm2_code) |>
  mutate(
    value = value / 1000,
    code = case_when(
      code == 23030 ~ 23090,      # Nam-gu -> Michuhol-gu (Incheon)
      code == 31320 ~ 31280,      # Yeoju-gun -> Yeoju-si
      code == 34390 ~ 34080,      # Dangjin-gun -> Dangjin-si
      TRUE ~ code
    )
  ) |>
  group_by(code) |>
  mutate(adm2 = adm2[which.max(year)]) |>   # keep the newest name
  ungroup() |>
  mutate(code = as.character(code))

# Disambiguate identical district names across provinces
prov_abbr <- c("11" = "SE", "21" = "BS", "22" = "DG", "23" = "IC", "24" = "GJ",
               "25" = "DJ", "26" = "UL", "29" = "SJ", "31" = "GG", "32" = "GW",
               "33" = "CB", "34" = "CN", "35" = "JB", "36" = "JN", "37" = "GB",
               "38" = "GN", "39" = "JJ")
grid2020 <- kr_grid_adm2_sgis_2020 |>
  mutate(code = as.character(code)) |>
  group_by(name) |>
  mutate(name = if (n() > 1)
           paste0(name, " (", prov_abbr[substr(code, 1, 2)], ")") else name) |>
  ungroup()

gf <- ggplot(pop) +
  geom_line(aes(x = year, y = value, group = interaction(adm2, class2),
                color = class2), alpha = 0.5, linewidth = 2) +
  facet_geo(~ code, grid = grid2020, label = "name", scale = "free_y") +
  scale_color_manual(values = c(female = "#F44336", male = "#2196F3")) +
  scale_x_continuous(breaks = c(2010, 2015, 2020)) +
  labs(title = "Population trends by district and sex, 2010-2020",
       x = NULL, y = NULL, color = "Sex") +
  theme_void() +
  theme(strip.text = element_text(size = 5),
        axis.text.x = element_text(size = 5, angle = 90),
        panel.spacing = grid::unit(1, "pt"))
grid::grid.draw(ggplot2::ggplotGrob(gf))   # avoids a geofacet/ggplot2 4.0 printing issue

## ---- Case 2: PCA of a five-variable socioeconomic profile, 2020 ----
# Each query returns a wide table; aggregated to basic local governments
# (adm2_type = "atn"), summing counts and population-weighting rates.
df_hou  <- anycensus(2020, type = "housing",    level = "adm2",
                     adm2_type = "atn", aggregator = sum)
df_pop  <- anycensus(2020, type = "population", level = "adm2",
                     adm2_type = "atn", aggregator = sum) |>
  select(adm1, adm1_code, adm2, adm2_code, year, starts_with("all households"))
df_fert <- anycensus(2020, type = "population", level = "adm2",
                     adm2_type = "atn", aggregator = mean,
                     weight_type = "population",
                     weight_col = "all households_total_prs") |>
  select(matches("(adm|year|fertility)"))
df_mort <- anycensus(2020, type = "mortality",  level = "adm2",
                     adm2_type = "atn", aggregator = mean,
                     weight_type = "population",
                     weight_col = "all households_total_prs") |>
  select(-`all households_total_prs`)
df_ss   <- anycensus(2020, type = "social security", level = "adm2")

keys <- c("adm1", "adm1_code", "adm2", "adm2_code", "year")
df_wide <- Reduce(function(x, y) left_join(x, y, by = keys),
                  list(df_hou, df_pop, df_fert, df_mort, df_ss)) |>
  select(-starts_with("type"))

profile <- df_wide |>
  mutate(blg_code = paste0(substr(adm2_code, 1, 4), "0")) |>
  group_by(blg_code) |>
  summarize(
    across(matches("households|housing|security"), ~ sum(.x, na.rm = TRUE)),
    across(matches("fertility|causes"),            ~ mean(.x, na.rm = TRUE)),
    adm2 = first(adm2)
  ) |>
  transmute(
    blg_code, adm2,
    persons_per_housing = `all households_total_prs` / `housing types_total_cnt`,
    sex_ratio      = 100 * `all households_male_prs` / `all households_female_prs`,
    mortality_rate = `all causes_total_p1p`,
    fertility_rate = fertility_total_brt,
    security_rate  = 100 * (`basic living security_female_prs` +
                            `basic living security_male_prs`) /
                           `all households_total_prs`
  )

pca <- profile |>
  select(persons_per_housing:security_rate) |>
  prcomp(scale. = TRUE)
round(pca$rotation, 3)          # loadings reported in Table 4
summary(pca)
