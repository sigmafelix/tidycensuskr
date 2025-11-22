# Query Korean census data by admin code (province or municipality) and year

The function queries a long format census data frame
([`censuskor`](https://sigmafelix.github.io/tidycensuskr/reference/censuskor.md))
for specific administrative codes (if provided)

## Usage

``` r
anycensus(
  year = 2020,
  codes = NULL,
  type = c("population", "housing", "tax", "mortality", "economy", "medicine",
    "migration", "environment", "welfare"),
  level = c("adm2", "adm1"),
  aggregator = sum,
  geometry = FALSE,
  ...
)
```

## Arguments

- year:

  integer(1). One of 2010, 2015, or 2020.

- codes:

  integer vector of admin codes (e.g. `c(11, 26)`) or character
  administrative area names (e.g. `c("Seoul", "Daejeon")`).

- type:

  character(1). "population", "housing", "tax", "economy", "medicine",
  "migration", "environment" or "mortality" Defaults to "population".

- level:

  character(1). "adm1" for province-level or "adm2" for municipal-level.
  Defaults to "adm2".

- aggregator:

  function to aggregate values when `level = "adm1"`.

- geometry:

  logical(1). If `TRUE`, returns an `sf` object with geometries
  attached. Defaults to `FALSE`.

- ...:

  additional arguments passed to the `aggregator` function. (e.g.,
  `na.rm = TRUE`).

## Value

A data.frame object containing census data for the specified codes and
year.

## Note

Using characters in `codes` has a side effect of returning all rows in
the dataset that match year and type. The 'wide' table is returned with
separate columns for each `class1` and `class2` and `unit` (abbreviated
whereof) combination.

## Examples

``` r
# Query mortality data for adm2_code 21 (Busan)
anycensus(codes = 21, type = "mortality")
#> # A tibble: 16 × 9
#>     year adm1  adm1_code adm2         adm2_code type      `all causes_total_p1p`
#>    <dbl> <chr>     <dbl> <chr>            <dbl> <chr>                      <dbl>
#>  1  2020 Busan        21 Buk-gu           21080 mortality                   319.
#>  2  2020 Busan        21 Busanjin-gu      21050 mortality                   332.
#>  3  2020 Busan        21 Dong-gu          21030 mortality                   372.
#>  4  2020 Busan        21 Dongnae-gu       21060 mortality                   297.
#>  5  2020 Busan        21 Gangseo-gu       21120 mortality                   290.
#>  6  2020 Busan        21 Geumjeong-gu     21110 mortality                   322.
#>  7  2020 Busan        21 Gijang-gun       21310 mortality                   329.
#>  8  2020 Busan        21 Haeundae-gu      21090 mortality                   302.
#>  9  2020 Busan        21 Jung-gu          21010 mortality                   398.
#> 10  2020 Busan        21 Nam-gu           21070 mortality                   311.
#> 11  2020 Busan        21 Saha-gu          21100 mortality                   342.
#> 12  2020 Busan        21 Sasang-gu        21150 mortality                   363.
#> 13  2020 Busan        21 Seo-gu           21020 mortality                   395.
#> 14  2020 Busan        21 Suyeong-gu       21140 mortality                   294.
#> 15  2020 Busan        21 Yeongdo-gu       21040 mortality                   404.
#> 16  2020 Busan        21 Yeonje-gu        21130 mortality                   297.
#> # ℹ 2 more variables: `all causes_male_p1p` <dbl>,
#> #   `all causes_female_p1p` <dbl>

# Query population data for adm1 "Seoul" or "Daejeon"
anycensus(codes = c("Seoul", "Daejeon"), type = "housing", year = 2015)
#> # A tibble: 30 × 15
#>     year adm1    adm1_code adm2          adm2_code type   housing types_total_…¹
#>    <dbl> <chr>       <dbl> <chr>             <dbl> <chr>                   <dbl>
#>  1  2015 Daejeon        25 Daedeok-gu        25050 housi…                  58548
#>  2  2015 Seoul          11 Dobong-gu         11100 housi…                 100589
#>  3  2015 Daejeon        25 Dong-gu           25010 housi…                  73731
#>  4  2015 Seoul          11 Dongdaemun-gu     11060 housi…                  94464
#>  5  2015 Seoul          11 Dongjak-gu        11200 housi…                 107968
#>  6  2015 Seoul          11 Eunpyeong-gu      11120 housi…                 136848
#>  7  2015 Seoul          11 Gangbuk-gu        11090 housi…                  89911
#>  8  2015 Seoul          11 Gangdong-gu       11250 housi…                 114424
#>  9  2015 Seoul          11 Gangnam-gu        11230 housi…                 164864
#> 10  2015 Seoul          11 Gangseo-gu        11160 housi…                 173366
#> # ℹ 20 more rows
#> # ℹ abbreviated name: ¹​`housing types_total_cnt`
#> # ℹ 8 more variables: `housing types_detached housing_cnt` <dbl>,
#> #   `housing types_apartment_cnt` <dbl>, `housing types_row house_cnt` <dbl>,
#> #   `housing types_multiplex_cnt` <dbl>,
#> #   `housing types_non-residential_cnt` <dbl>,
#> #   `vacant housing_fraction_prc` <dbl>, …

# Aggregate to adm1 level tax (province-level) using sum
anycensus(
  codes = c(11, 23, 31),
  type = "tax",
  year = 2020,
  level = "adm1",
  aggregator = sum,
  na.rm = TRUE
)
#> # A tibble: 3 × 6
#> # Groups:   year, type, adm1, adm1_code [3]
#>    year type  adm1        adm1_code income_general_mkr income_labor_mkr
#>   <dbl> <chr> <chr>           <dbl>              <dbl>            <dbl>
#> 1  2020 tax   Gyeonggi-do        31           12367363         14767906
#> 2  2020 tax   Incheon            23            1994065          2111882
#> 3  2020 tax   Seoul              11           20923255         24311772
```
