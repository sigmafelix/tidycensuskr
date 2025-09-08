# Who is the package for?
The aim of creating the `tidycensuskr` package is to make the best use case of South Korean boundaries, population and socioeconomic information for R users.

<a href='https://sigmafelix.github.io/tidycensuskr/'><img src='man/figures/seoul_ai.jpeg' align="center"  /></a>



# Installation
You can install the released version of palmerpenguins from CRAN with:

```r
install.packages("tidycensuskr")
```

To install the development version, you will need a GitHub account and generate a personal access token with `repo` permissions.


```r
rlang::check_installed("remotes")
remotes::install_github("sigmafelix/tidycensuskr", auth_token = "__YOUR_GITHUB_TOKEN__")
```

- After cloning the repository, you can also install the package using:

```r
devtools::install(quick = TRUE)
```



# About the data

As of July 2025, this package contains two datasets: Census and the corresponding geospatial data.


## 1. Census
* Sigungu dataset of three census years (2010, 2015, 2020)
    - The curated dataset is a **long** table (i.e., one row per district-year-variable)

## `anycensus()`
- The package loads an attached dataset `censuskor` that contains the census data for 2020. This dataset is automatically loaded upon loading the package
- The function `anycensus()` allows you to query census data for specific district or province codes and types of data (population, tax, mortality) for the year 2020.


```r
library(tidycensuskr)

# loading Seoul population data
tidycensuskr::anycensus(codes = "Seoul", type = "population")
```



## 2. Boundaries

* Boundaries for the three census years (2010, 2015, 2020)see `?load_districts` for more info.
    


# Examples

Package vignettes are the first place to look for detailed examples. Below are some quick examples to get you started.

```r
library(tidycensuskr)
library(ggplot2)
library(dplyr)
library(sf)
sf_use_s2(FALSE)

# load boundaries
adm2_2020 <- load_districts(year = 2020, level = "adm2")

# load census data
census_2020 <- anycensus(year = 2020, codes = NULL, type = "population")

# merge boundaries and census data
census_2020_sf <- adm2_2020 %>%
    left_join(census_2020, by = c("adm2_code" = "adm2_code"))

# plot population data
ggplot(census_2020_sf) +
    geom_sf(aes(fill = value)) +
    scale_fill_viridis_c() +
    theme_minimal() +
    labs(title = "Population by District in South Korea (2020)",
         fill = "Population")

```