# `tidycensuskr`
Harmonizing census geographic boundaries and data tables in Korea


## Installation
- The package is in a private GitHub repository, so you need to have a GitHub account and generate a personal access token with `repo` permissions.

```r
rlang::check_installed("remotes")
remotes::install_github("sigmafelix/tidycensuskr", auth_token = "__YOUR_GITHUB_TOKEN__")
```

- After cloning the repository, you can also install the package using:

```r
devtools::install(quick = TRUE)
```

## Usage

```r
library(tidycensuskr)
library(kosis)
library(sf)
options(sf_use_s2 = FALSE)

# 1. Load raw tables from KOSIS
# register KOSIS API Key if necessary
tidycensuskr::set_kosis_key("__your_api_key_file__")
# The line above is equivalent to:
# kosis::kosis.setKey("_YOUR_API_KEY_")

sgg2020 <- load_districts()
pop <- load_population(year = 2020)

pop_total <- pop %>%
  filter(C3_NM == "합계")
```

## `anycensusk()`
- The package loads an attached dataset `censuskor` that contains the census data for 2020. This dataset is automatically loaded upon loading the package
- The function `anycensusk()` allows you to query census data for specific district or province codes and types of data (population, tax, mortality) for the year 2020.


```r
library(tidycensuskr)

# loading Seoul population data
tidycensuskr::anycensusk(codes = "Seoul", type = "population")
```


## Note
- Some district codes follow a revised standard, where rural districts (군) get the third digit from 5, changed from 3 in the previous standard.