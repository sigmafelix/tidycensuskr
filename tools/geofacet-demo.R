# Geofacets custom grid demonstration

# load packages
library(tidycensuskr)
library(sf)
library(ggplot2)
library(geofacet)

# load data
data(censuskor)
data(adm2_sf_2020)
data(kr_grid_adm2_sgis_2020)

# prepare geofacet grid data
# Use the newest adm2_code and name if one got its name changed or promoted
pop <- censuskor |>
  dplyr::filter(
    type == "population"
  ) |>
  dplyr::rename(code = adm2_code) |>
  dplyr::filter(class2 != "total") |>
  dplyr::mutate(
    value = value / 1000,
    code = dplyr::case_when(
      # Michuhol (23030 to 23090)
      code == 23030 ~ 23090,
      # Yeoju
      code == 31320 ~ 31280,
      # Dangjin
      code == 34390 ~ 34080,
      TRUE ~ code
    )
  ) |>
  dplyr::arrange(code, class2, -year) |>
  dplyr::group_by(code) |>
  dplyr::mutate(adm2 = adm2[which.max(year)]) |>
  dplyr::ungroup()

# geofacet plot
# map codes to district names for facet labels
pop_name_map <- pop %>%
  dplyr::distinct(code, adm2) %>%
  { setNames(.$adm2, .$code) }

pop_labels <- pop %>% dplyr::distinct(code, adm2)

# Adjust for the identical names in different provinces
kr_grid_adm2_sgis_2020 <-
  kr_grid_adm2_sgis_2020 |>
  dplyr::mutate(
    name = dplyr::case_when(
      grepl("^32", code) & name == "Goseong-gun" ~ "Goseong-gun (GW)",
      grepl("^38", code) & name == "Goseong-gun" ~ "Goseong-gun (GN)",
      grepl("^11", code) & name == "Jung-gu" ~ "Jung-gu (SE)",
      grepl("^21", code) & name == "Jung-gu" ~ "Jung-gu (BU)",
      grepl("^22", code) & name == "Jung-gu" ~ "Jung-gu (DG)",
      grepl("^23", code) & name == "Jung-gu" ~ "Jung-gu (IC)",
      grepl("^25", code) & name == "Jung-gu" ~ "Jung-gu (DJ)",
      grepl("^26", code) & name == "Jung-gu" ~ "Jung-gu (UL)",
      grepl("^21", code) & name == "Seo-gu" ~ "Seo-gu (BU)",
      grepl("^22", code) & name == "Seo-gu" ~ "Seo-gu (DG)",
      grepl("^23", code) & name == "Seo-gu" ~ "Seo-gu (IC)",
      grepl("^24", code) & name == "Seo-gu" ~ "Seo-gu (GJ)",
      grepl("^25", code) & name == "Seo-gu" ~ "Seo-gu (DJ)",
      grepl("^26", code) & name == "Seo-gu" ~ "Seo-gu (UL)",
      grepl("^21", code) & name == "Nam-gu" ~ "Nam-gu (BU)",
      grepl("^22", code) & name == "Nam-gu" ~ "Nam-gu (DG)",
      grepl("^24", code) & name == "Nam-gu" ~ "Nam-gu (GJ)",
      grepl("^26", code) & name == "Nam-gu" ~ "Nam-gu (UL)",
      grepl("^21", code) & name == "Dong-gu" ~ "Dong-gu (BU)",
      grepl("^22", code) & name == "Dong-gu" ~ "Dong-gu (DG)",
      grepl("^23", code) & name == "Dong-gu" ~ "Dong-gu (IC)",
      grepl("^24", code) & name == "Dong-gu" ~ "Dong-gu (GJ)",
      grepl("^25", code) & name == "Dong-gu" ~ "Dong-gu (DJ)",
      grepl("^26", code) & name == "Dong-gu" ~ "Dong-gu (UL)",
      grepl("^21", code) & name == "Buk-gu" ~ "Buk-gu (BU)",
      grepl("^22", code) & name == "Buk-gu" ~ "Buk-gu (DG)",
      grepl("^24", code) & name == "Buk-gu" ~ "Buk-gu (GJ)",
      grepl("^26", code) & name == "Buk-gu" ~ "Buk-gu (UL)",
      grepl("^11", code) & name == "Gangseo-gu" ~ "Gangseo-gu (SE)",
      grepl("^21", code) & name == "Gangseo-gu" ~ "Gangseo-gu (BU)",
      TRUE ~ name
    )
  )

pop_gfgg <-
  ggplot(data = pop) +
  geom_line(
    aes(x = year, y = value, group = interaction(adm2, class2), color = class2),
    alpha = 0.5,
    linewidth = 2.5
  ) +
  facet_geo(~ code, grid = kr_grid_adm2_sgis_2020, label = "name", scale = "free_y") +
  labs(
    title = "Population Trends in South Korea by Municipalities/Counties/Districts and Sex",
    x = "Year",
    y = "",
    color = "District and Population Class",
    caption = "Y-axis values are not commensurate with the original scale"
  ) +
  scale_color_manual(values = c(female = "#F44336", male = "#2196F3")) +
  theme_void() +
  scale_x_continuous(
    breaks = sort(unique(pop$year)),
    labels = function(x) sprintf("%d", as.integer(x))
  ) +
  theme(
    strip.text = element_text(size = 5, margin = margin(0.05, 0.05, 0.05, 0.05, "cm")),
    strip.background = element_blank(),
    axis.text.x = element_text(size = 6, angle = 90, hjust = 1),
    axis.text.y = element_blank(),
    # axis.text.y = element_text(size = 8),
    panel.spacing = grid::unit(1, "pt"),       # very tight spacing between facets
    plot.margin = margin(1, 1, 1, 1, "mm")     # small outer margins
  )

# pop_gfgg
ggsave("tools/geofacet_demo.png", pop_gfgg, width = 14, height = 15, dpi = 300)
