library(tidyverse)
library(sf)

census <- read_csv("censuskr.csv")

census |>
  select(adm1_name, adm2_name, starts_with("pop2020")) |>
  mutate(adm1_name = as.factor(adm1_name),
         pop2020_total = as.integer(pop2020_total),
         pop2020_men = as.integer(pop2020_men),
         pop2020_women = as.integer(pop2020_women),
         gender_ratio = pop2020_men / pop2020_women) |>
  drop_na() -> census_tidy

census_tidy2 <- census_tidy %>%
  mutate(
    adm1_name = case_when(
      adm1_name == "Gyeonggi-do" & adm2_name %in% c(
        "Yeoncheon-gun",
        "Pochun-gun",
        "Gapyeong-gun",
        "Dongducheon-si",
        "Yangju-si",
        "Paju-si",
        "Goyang-si Deogyang-gu",
        "Goyang-si Ilsandong-gu",
        "Goyang-si Ilsanseo-gu",
        "Uijeongbu-si",
        "Namyangju-si",
        "Guri-si"
      ) ~ "Gyeonggi-do1",
      adm1_name == "Gyeonggi-do" ~ "Gyeonggi-do2",
      TRUE ~ adm1_name
    )
  )


census_tidy2 %>%
  group_by(adm1_name) %>%
  mutate(adm2_name = reorder(adm2_name, pop2020_total)) %>%  # Ascending within group
  ungroup() %>%
  ggplot(aes(x = adm2_name)) +
  geom_col(aes(y = pop2020_total, fill = adm1_name), alpha = 0.8, width = 0.7, show.legend = FALSE) +
  geom_point(aes(y = pop2020_total, colour = gender_ratio), size = 2) +
  scale_fill_viridis_d() +
  scale_colour_gradient2(low = "#d62728", mid = "#808080", high = "#17becf",
                         midpoint = 1, name = "Gender Ratio(M/F)") +
  coord_flip() +
  facet_wrap(~ adm1_name, scales = "free_y", ncol = 3) +
  labs(title = "Korean Cities by Region: Population and Gender Demographics",
       x = "City",
       y = "Total Population",
       caption = "Source: Census data") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.y = element_text(size = 7),
        strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        legend.position = "bottom")


ggsave("population.png", width = 10, height = 15, dpi = 600)




census_tidy |>
  filter(adm1_name == "Gyeonggi-do") -> df


# Reshape data and reorder by total population
df_long <- df %>%
  pivot_longer(cols = c(pop2020_men, pop2020_women),
               names_to = "gender",
               values_to = "population") %>%
  mutate(gender = case_when(
    gender == "pop2020_men" ~ "Men",
    gender == "pop2020_women" ~ "Women"
  )) %>%
  mutate(adm2_name = fct_reorder(adm2_name, pop2020_total, .desc = TRUE))

ggplot(df_long, aes(x = adm2_name, y = population, fill = gender)) +
  geom_col() +
  labs(title = "Population by Gender Across Administrative Areas",
       x = "Administrative Area",
       y = "Population",
       fill = "Gender") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c("Men" = "#3498db", "Women" = "#e74c3c"))

ggsave("gg.png", width = 10, height = 6)



