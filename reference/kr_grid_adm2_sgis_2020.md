# geofacet Grid for South Korea Administrative Districts (SGIS Standard, 2020)

A geofacet grid for South Korea administrative districts (*Si-Gun-Gu*)
based on the Statistical Geographic Information Service (SGIS) standard
in 2020. Non-autonomous districts in cities are retained as separate
entities. This grid can be used with the
[geofacet](https://CRAN.R-project.org/package=geofacet) package to
create faceted visualizations based on geographic layout.

## Usage

``` r
kr_grid_adm2_sgis_2020
```

## Format

A data.frame with 250 rows and 6 variables

## Source

- Statistical Geographic Information Service (SGIS)

- GitHub username chichead in [GitHub geofacet issue
  page](https://github.com/hafen/geofacet/issues/358)

## Details

- name Name of the district/municipal-level (Si-Gun-Gu) administrative
  unit

- code SGIS code of the district/municipal-level (Si-Gun-Gu)
  administrative unit

- row Row position in the geofacet grid

- col Column position in the geofacet grid
