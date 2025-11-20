# Load district boundaries for a specific year

Load district boundaries for a specific year

## Usage

``` r
load_districts(year = 2020)
```

## Arguments

- year:

  The year for which to load district boundaries (2010, 2015, or 2020)

## Value

An `sf` object containing district boundaries for the specified year

## Note

This function requires the `tidycensussfkr` package to be installed. No
explicit dependency is defind; but users should install the package
following the instructions at vignette('v01_intro') or more succinctly:
`install.packages('tidycensussfkr', repos = 'https://sigmafelix.r-universe.dev')`
