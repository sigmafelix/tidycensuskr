# `tidycensuskr`
Harmonizing census geographic boundaries and data tables in Korea


## Installation

```r
rlang::check_installed("remotes")
remotes::install_github("sigmafelix/habit")
```

- After cloning the repository, you can also install the package using:

```r
devtools::install(quick = TRUE)
```

## Usage

```r
library(habit)
library(kosis)
# register KOSIS API Key if necessary
kosis::kosis.setKey("_YOUR_API_KEY_")

sgg2020 <- load_districts()
pop <- load_population(year = 2020)

pop_total <- pop %>%
  filter(C3_NM == "합계") %>%
  select()
```
