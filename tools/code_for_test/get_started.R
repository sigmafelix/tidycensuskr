library(dplyr)
library(ggplot2)
library(scales)

# Filter only total population values
seoul_total <- censuskor |>
  filter(type == "population",
         year == 2020,
         class2 == "total",
         adm1 == "Seoul") |>
  mutate(adm2 = str_replace(adm2, "-gu$", ""))  # remove '-gu' at the end

# Plot with ggplot2
ggplot(seoul_total, aes(x = reorder(adm2, value), y = value)) +
  geom_col(fill = "skyblue", colour = "black") +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Seoul 2020 Census Total Population by District",
    x = "District",
    y = "Population"
  ) +
  coord_flip() +
  theme_minimal(base_size = 14)
