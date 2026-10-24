# Catalog available census variables

Return the combinations of year, geographic level, `type`, `class1`, and
`class2` available in `censuskor`, with units and row counts.

## Usage

``` r
catalog()
```

## Value

A data frame with columns `year`, `level`, `type`, `class1`, `class2`,
`unit`, and `n`.

## Examples

``` r
catalog()
#> # A data frame: 621 × 7
#>     year level type    class1  class2                                unit      n
#>    <dbl> <chr> <chr>   <chr>   <chr>                                 <chr> <int>
#>  1  2010 adm2  economy company total                                 count   263
#>  2  2010 adm2  economy grdp    accommodation and food service activ… mill…   192
#>  3  2010 adm2  economy grdp    agriculture, forestry and fishing     mill…   192
#>  4  2010 adm2  economy grdp    arts, sports and recreation; members… mill…   192
#>  5  2010 adm2  economy grdp    construction                          mill…   192
#>  6  2010 adm2  economy grdp    education                             mill…   192
#>  7  2010 adm2  economy grdp    electricity, gas, steam and air cond… mill…   192
#>  8  2010 adm2  economy grdp    financial and insurance activities    mill…   192
#>  9  2010 adm2  economy grdp    gross regional domestic product at m… mill…   192
#> 10  2010 adm2  economy grdp    human health and social work activit… mill…   192
#> # ℹ 611 more rows
```
