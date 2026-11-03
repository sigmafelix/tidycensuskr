# Load district boundaries for a specific year

Load district boundaries for a specific year

## Usage

``` r
load_districts(year = 2020, level = "adm2")
```

## Arguments

- year:

  The year for which to load district boundaries (2010, 2015, 2020, or
  2025)

- level:

  The administrative level, one of "adm2" and "adm3"

## Value

An `sf` object containing district boundaries for the specified year

## Note

Other ADM2 years and ADM3 boundaries require the `tidycensuskr.sf`
package to be installed. No explicit dependency is defind; but users
should install the package following the instructions at
vignette('v01_intro') or more succinctly:
`install.packages('tidycensuskr.sf', repos = 'https://sigmafelix.r-universe.dev')`
