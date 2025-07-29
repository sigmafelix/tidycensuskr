# What is the package for?
The aim of creating the `tidycensuskr` package is to make the best use case of South Korean boundaries, population and socioeconomic information for R users.

![](pkgdown/man/figures/population.png)

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
    - The curated dataset contain 250 rows long and 8 variables. 



```r
head(census)
#> # A tibble: 253 x 6
#>   adm1_code adm1_name adm2_code adm2_name   pop2015_total pop2015_men pop2015_women pop2020_total pop2020_men pop2020_women
#>       <int> <chr>     <int>     <chr>               <int>       <int>         <int>         <int>       <int>         <int>
#> 1        11 Seoul     11010     Jongno-gu          161521       79510         82011        151291       73062         78229
#> 2        11 Seoul     11020     Jung-gu            128478       63218         65260        128744       62147         66597
#> 3        11 Seoul     11030     Yongsan-gu         227282      109980        117302        225882      109162        116720
#> 4        11 Seoul     11040     Seongdong-gu       295006      146332        148674        291918      142128        149790
#> 5        11 Seoul     11050     Gwangjin-gu        368199      180647        187552        353967      169925        184042
#> 6        11 Seoul     11060     Dongdaemun-gu      364787      181189        183598        351057      171484        179573
```

if you use the function `anycensus()`, you will get the information by census years and regions.

```r
# Say if you want to query Seoul's 2020 population
# You can type in Seoul's district code, then the census year
# You can retrieve the data using the simplify() function by changing the options to either a data frame or a list.
seoul <- anycensus(11, 2020, simplify = "df")

# Quick visualisation
plot_census_map(seoul, variable = "population_density")
```



## 2. Boundaries

* Boundaries for the three census years (2010, 2015, 2020)see ?`boundary_raw` for more info.
    


# Examples

You can find these and more code examples for exploring census in `vignette("examples")`


```r
library(tidyverse)
library(sf)

head(sgg)
#> Simple feature collection with 251 features and 6 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 746111 ymin: 1458603 xmax: 1387949 ymax: 2068444
#> Projected CRS: Korea 2000 / Unified CS
#> # A tibble: 251 × 7
#>   BASE_DATE SIGUNGU_CD SIGUNGU_NM                  geom             adm1_code adm1_name adm2_name
#>       <int>      <int> <chr>          <MULTIPOLYGON [m]>               <int> <chr>     <chr>    
#> 1  20201231      11010 종로구  (((953683.8 1959210, 953…                  11 Seoul     Jongno-gu
#> 2  20201231      11020 중구    (((957890.4 1952617, 957…                  11 Seoul     Jung-gu  
#> 3  20201231      11030 용산구  (((953114.2 1950747, 953…                  11 Seoul     Yongsan-gu
#> 4  20201231      11040 성동구  (((959381.8 1952724, 959…                  11 Seoul     Seongdong-gu
#> 5  20201231      11050 광진구  (((964825.1 1952633, 964…                  11 Seoul     Gwangjin-gu
#> 6  20201231      11060 동대문구 (((961991.8 1956626, 961…                  11 Seoul     Dongdaemun-gu

```
