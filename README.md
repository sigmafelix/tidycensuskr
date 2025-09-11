# Who is the package for?
The `tidycensuskr` package is designed for R users who want to work with South Korean census and administrative boundary data. It aims to provide an easy-to-use interface for population, housing, and socioeconomic statistics linked with geospatial boundaries.

<a href='https://sigmafelix.github.io/tidycensuskr/'><img src='man/figures/seoul_ai.jpeg' align="center"  /></a>



# Installation
You can install the released version of `tidycensuskr` from CRAN with:

```r
# CRAN 
install.packages("tidycensuskr")
```

To install the development version, you will need a GitHub account and generate a personal access token with `repo` permissions.


```r
# Development version from GitHub
rlang::check_installed("remotes")
remotes::install_github("sigmafelix/tidycensuskr", auth_token = "__YOUR_GITHUB_TOKEN__")
```

After cloning the repository, you can also install the package using:

```r
devtools::install(quick = TRUE)
```  



# About the data

As of September 2025, this package contains two datasets: Census data (`censuskor`) and the corresponding geospatial data.


## 1. Census data
* Sigungu dataset of three census years (2010, 2015, 2020)
    - The curated dataset is a **long** table (i.e., one row per district-year-variable)

### `anycensus()`

- The function `anycensus()` allows you to query census data for specific district or province codes and types of data (population, tax, mortality, economy, housing) for three census years (2010, 2015, 2020).


```r
# loading Seoul population data
tidycensuskr::anycensus(codes = "Seoul", type = "population")
```

### `censuskor`
- The function `data(censuskor)` loads an attached dataset that contains the census data in long form. This dataset is automatically loaded upon loading the package.


## 2. Administrative boundaries

### `load_district()`

* The function `load_district()` allows you to get the _Si-Gun-Gu_ level `sf` files for the three census years (2010, 2015, 2020).

```r
# loading boundary sf file
tidycensuskr::load_districts(year = 2020)
```    


# Examples

Package vignettes are the first place to look for detailed examples. Below are some quick examples to get you started.

```r
library(tidycensuskr)
library(ggplot2)
library(dplyr)
library(sf)
sf_use_s2(FALSE) 


# load census data
census_2020 <- anycensus(year = 2020, codes = NULL, type = "population")

# load boundaries
adm2_2020 <- load_districts(year = 2020)

# merge boundaries and census data
census_2020_sf <- adm2_2020 %>%
    left_join(census_2020, by = c("adm2_code" = "adm2_code"))

# plot population data
ggplot(census_2020_sf) +
    geom_sf(aes(fill = `all households_total_prs`)) +
    scale_fill_viridis_c() +
    theme_minimal() +
    labs(title = "Population by District in South Korea (2020)",
         fill = "Population")

```
