# Query Korean census data by administrative code and year

The function queries a long format census data frame
([`censuskor`](https://sigmafelix.github.io/tidycensuskr/ko/reference/censuskor.md))
for specific administrative codes (if provided)

## Usage

``` r
anycensus(
  year = 2020,
  codes = NULL,
  type = c("population", "housing", "tax", "mortality", "economy", "medicine",
    "migration", "environment", "welfare", "social security", "landuse"),
  level = c("adm2", "adm3", "adm1"),
  adm2_type = c("all", "atn", "non"),
  aggregator = sum,
  weight_type = NULL,
  weight_column = NULL,
  geometry = FALSE,
  ...
)
```

## Arguments

- year:

  integer(1). One of 2010, 2015, 2020, or 2025. 2025 data is currently
  available only for ADM3 population and housing.

- codes:

  integer vector of admin codes (e.g. `c(11, 26)`) or character
  administrative area names (e.g. `c("Seoul", "Daejeon")`).

- type:

  character vector. One or more of "population", "housing", "tax",
  "economy", "medicine", "migration", "environment", "mortality",
  "social security", or "landuse". Defaults to "population".

- level:

  character(1). "adm1" for province-level, "adm2" for municipal-level,
  or "adm3" for neighborhood/town-level. ADM3 population and housing
  data is available for 2015, 2020, and 2025; ADM3 economy and mortality
  data is available for 2020. Defaults to "adm2".

- adm2_type:

  character(1). Which municipal code type to keep before returning
  `adm2` results or aggregating to `adm1`. `"all"` keeps the current
  data, `"atn"` keeps autonomous/basic local government rows, and
  `"non"` keeps non-autonomous rows where they are available. For
  weighted aggregation with `"atn"`, autonomous/basic local government
  rate rows are recalculated from their non-autonomous component rows
  using the supplied weights before returning `adm2` or aggregating to
  `adm1`.

- aggregator:

  function to aggregate values when `level = "adm1"` or when weighted
  `adm2_type = "atn"` recalculates autonomous/basic local government
  rows.

- weight_type:

  character(1). Optional data type used to supply weights when
  aggregating. For example, rate variables in `type = "mortality"` can
  be aggregated with population weights from
  `weight_type = "population"`.

- weight_column:

  character(1). Optional column name used as weights when aggregating.
  If `weight_type = "population"` and `weight_column` is omitted,
  `"all households_total_prs"` is used.

- geometry:

  logical(1). If `TRUE`, returns an `sf` object with ADM2 geometries
  attached. Geometry is available for 2010, 2015, and 2020; 2025 census
  data is tabular only. Defaults to `FALSE`.

- ...:

  additional arguments passed to the `aggregator` function. (e.g.,
  `na.rm = TRUE`). When `weight_type` or `weight_column` is supplied,
  `aggregator` must accept a `w` argument such as
  [`stats::weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html).

## Value

A data.frame object containing census data for the specified codes and
year.

## Note

Character names are resolved to their administrative codes before
filtering. The 'wide' table is returned with separate columns for each
`class1` and `class2` and `unit` (abbreviated whereof) combination.

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

# Query adm3 population data within Jongno-gu
anycensus(
  codes = 11010,
  type = "population",
  year = 2020,
  level = "adm3"
)
#> # A tibble: 34 × 17
#>     year adm1  adm1_code adm2      adm2_code type       adm3           adm3_code
#>    <dbl> <chr>     <dbl> <chr>         <dbl> <chr>      <chr>              <dbl>
#>  1  2020 Seoul        11 Jongno-gu     11010 population Sajik-dong      11010530
#>  2  2020 Seoul        11 Jongno-gu     11010 population Samcheong-dong  11010540
#>  3  2020 Seoul        11 Jongno-gu     11010 population Buam-dong       11010550
#>  4  2020 Seoul        11 Jongno-gu     11010 population Pyeongchang-d…  11010560
#>  5  2020 Seoul        11 Jongno-gu     11010 population Muak-dong       11010570
#>  6  2020 Seoul        11 Jongno-gu     11010 population Gyonam-dong     11010580
#>  7  2020 Seoul        11 Jongno-gu     11010 population Gahoe-dong      11010600
#>  8  2020 Seoul        11 Jongno-gu     11010 population Jongno 1.2.3.…  11010610
#>  9  2020 Seoul        11 Jongno-gu     11010 population Jongno 5.6(or…  11010630
#> 10  2020 Seoul        11 Jongno-gu     11010 population Ihwa-dong       11010640
#> # ℹ 24 more rows
#> # ℹ 9 more variables: `all households_total_prs` <dbl>,
#> #   `all households_male_prs` <dbl>, `all households_female_prs` <dbl>,
#> #   `domestic population_total_prs` <dbl>,
#> #   `domestic population_male_prs` <dbl>,
#> #   `domestic population_female_prs` <dbl>,
#> #   `foreign population_total_prs` <dbl>, …

# Query 2025 neighborhood-level housing data (without geometry)
anycensus(
  codes = 11010,
  type = "housing",
  year = 2025,
  level = "adm3"
)
#> # A tibble: 17 × 63
#>     year adm1  adm1_code adm2      adm2_code type    adm3              adm3_code
#>    <dbl> <chr>     <dbl> <chr>         <dbl> <chr>   <chr>                 <dbl>
#>  1  2025 Seoul        11 Jongno-gu     11010 housing Sajik-dong         11010530
#>  2  2025 Seoul        11 Jongno-gu     11010 housing Samcheong-dong     11010540
#>  3  2025 Seoul        11 Jongno-gu     11010 housing Buam-dong          11010550
#>  4  2025 Seoul        11 Jongno-gu     11010 housing Pyeongchang-dong   11010560
#>  5  2025 Seoul        11 Jongno-gu     11010 housing Muak-dong          11010570
#>  6  2025 Seoul        11 Jongno-gu     11010 housing Gyonam-dong        11010580
#>  7  2025 Seoul        11 Jongno-gu     11010 housing Gahoe-dong         11010600
#>  8  2025 Seoul        11 Jongno-gu     11010 housing Jongno1.2.3.4ga-…  11010610
#>  9  2025 Seoul        11 Jongno-gu     11010 housing Jongno5.6ga-dong   11010630
#> 10  2025 Seoul        11 Jongno-gu     11010 housing Ewha-dong          11010640
#> 11  2025 Seoul        11 Jongno-gu     11010 housing Changsin1-dong     11010670
#> 12  2025 Seoul        11 Jongno-gu     11010 housing Changsin2-dong     11010680
#> 13  2025 Seoul        11 Jongno-gu     11010 housing Changsin3-dong     11010690
#> 14  2025 Seoul        11 Jongno-gu     11010 housing Soongin1-dong      11010700
#> 15  2025 Seoul        11 Jongno-gu     11010 housing Soongin2-dong      11010710
#> 16  2025 Seoul        11 Jongno-gu     11010 housing Cheongunhyoja-do…  11010720
#> 17  2025 Seoul        11 Jongno-gu     11010 housing Hyehwa-dong        11010730
#> # ℹ 55 more variables:
#> #   `household composition_total household households_hsh` <dbl>,
#> #   `household composition_total household household members total_prs` <dbl>,
#> #   `household composition_total household household members male_prs` <dbl>,
#> #   `household composition_total household household members female_prs` <dbl>,
#> #   `household composition_general housing households_hsh` <dbl>,
#> #   `household composition_general housing household members total_prs` <dbl>, …

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

# Aggregate mortality rates to adm1 using population weights
anycensus(
  codes = "Seoul",
  type = "mortality",
  year = 2020,
  level = "adm1",
  aggregator = stats::weighted.mean,
  weight_type = "population",
  weight_column = "all households_total_prs",
  na.rm = TRUE
)
#> # A tibble: 1 × 8
#>    year type      adm1  adm1_code `all causes_total_p1p` `all causes_male_p1p`
#>   <dbl> <chr>     <chr>     <dbl>                  <dbl>                 <dbl>
#> 1  2020 mortality Seoul        11                   256.                  347.
#> # ℹ 2 more variables: `all causes_female_p1p` <dbl>,
#> #   `all households_total_prs` <dbl>

# Aggregate rates to adm1 after cleaning to autonomous/basic local governments
anycensus(
  codes = "Gyeonggi-do",
  type = "mortality",
  year = 2020,
  level = "adm1",
  adm2_type = "atn",
  aggregator = stats::weighted.mean,
  weight_type = "population",
  weight_column = "all households_total_prs",
  na.rm = TRUE
)
#> # A tibble: 1 × 8
#>    year type      adm1    adm1_code `all causes_total_p1p` `all causes_male_p1p`
#>   <dbl> <chr>     <chr>       <dbl>                  <dbl>                 <dbl>
#> 1  2020 mortality Gyeong…        31                   286.                  379.
#> # ℹ 2 more variables: `all causes_female_p1p` <dbl>,
#> #   `all households_total_prs` <dbl>

# Recalculate adm2 rates after cleaning to autonomous/basic local governments
anycensus(
  codes = "Gyeonggi-do",
  type = "mortality",
  year = 2020,
  level = "adm2",
  adm2_type = "atn",
  aggregator = stats::weighted.mean,
  weight_type = "population",
  weight_column = "all households_total_prs",
  na.rm = TRUE
)
#> # A tibble: 31 × 10
#>     year adm1        adm1_code adm2       adm2_code type  `all causes_total_p1p`
#>    <dbl> <chr>           <dbl> <chr>          <dbl> <chr>                  <dbl>
#>  1  2020 Gyeonggi-do        31 Ansan-si       31090 mort…                   336.
#>  2  2020 Gyeonggi-do        31 Anseong-si     31220 mort…                   316.
#>  3  2020 Gyeonggi-do        31 Anyang-si      31040 mort…                   256.
#>  4  2020 Gyeonggi-do        31 Bucheon-si     31050 mort…                   296.
#>  5  2020 Gyeonggi-do        31 Dongduche…     31080 mort…                   368 
#>  6  2020 Gyeonggi-do        31 Gapyeong-…     31370 mort…                   353.
#>  7  2020 Gyeonggi-do        31 Gimpo-si       31230 mort…                   272 
#>  8  2020 Gyeonggi-do        31 Goyang-si      31100 mort…                   258.
#>  9  2020 Gyeonggi-do        31 Gunpo-si       31160 mort…                   277 
#> 10  2020 Gyeonggi-do        31 Guri-si        31120 mort…                   291.
#> # ℹ 21 more rows
#> # ℹ 3 more variables: `all causes_male_p1p` <dbl>,
#> #   `all causes_female_p1p` <dbl>, `all households_total_prs` <dbl>
```
