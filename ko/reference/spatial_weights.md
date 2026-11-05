# Binary district spatial-weight matrices

Symmetric, unstandardized integer matrices for 2020. `w_mat_YYYY`
combines exact Queen adjacency with documented marine road bridges and
subsea tunnels open by December 31 of that year. `w_mat_o_YYYY` contains
exact Queen adjacency alone.

## Usage

``` r
w_mat_2020

w_mat_o_2020
```

## Format

Square 250 by 250 integer matrices. Values are 0 or 1, the diagonal is
zero, and dimnames are five-digit SGIS ADM2 codes.

An object of class `matrix` (inherits from `array`) with 250 rows and
250 columns.

An object of class `matrix` (inherits from `array`) with 250 rows and
250 columns.

## Source

SGIS/KOSTAT boundaries; Ministry of Land, Infrastructure and Transport,
local government and National Archives facility records.

## Details

Rows follow
[adm2_sf_2020](https://sigmafelix.github.io/tidycensuskr/ko/reference/adm2_sf_2020.md),
not sorted code order. Align observations by code before analysis. The
2010, 2015 and 2025 versions are registered in `tidycensuskr.sf`, with
their corresponding boundaries.

Parallel facilities between the same districts contribute one edge.
Within-district facilities contribute no diagonal entries. Ordinary
inland river bridges, dykes, railway tunnels and facilities opening
after the cutoff are not added. Marine bay and estuary crossings are
included. Islands may have zero neighbors; row standardization is left
to the user.

Exact Queen adjacency uses
[`sf::st_touches()`](https://r-spatial.github.io/sf/reference/geos_binary_pred.html)
with no snapping tolerance. The 2020 coverage has no polygon overlaps.
Unresolved historical contacts are documented with the repair artifacts.
These matrices represent the supplied geometry plus the researched
transport inventory, rather than a guarantee of complete real-world
connectivity.

The connection inventory and code-order metadata are distributed under
`system.file("extdata", "spatial_weights", package = "tidycensuskr.sf")`.

## Examples

``` r
data(w_mat_2020)
data(adm2_sf_2020)
stopifnot(identical(rownames(w_mat_2020), as.character(adm2_sf_2020$adm2_code)))
```
