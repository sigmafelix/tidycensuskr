#' South Korea Census Data
#'
#' District and neighborhood level data including tax, population, business
#' entities, housing, economy, medicine and mortality in South Korea in 2010,
#' 2015, 2020, and 2025. The available years and variables depend on the type
#' and geographic level of data.
#'
#' @format A data.frame with 836,707 rows and 12 columns,
#'   out of which 103,572 rows for adm2, and 733,135 rows for adm3 data.
#' @details
#' * year Year of the census data, e.g., 2010, 2015, 2020, or 2025
#' * adm1 Name of the province-level (Si-Do) administrative unit
#' * adm1_code Code of the province-level (Si-Do) administrative unit
#' * adm2 Name of the district/municipal-level (Si-Gun-Gu) administrative unit
#' * adm2_code  Code of the district/municipal-level (Si-Gun-Gu) administrative unit
#' * type Type of variable,
#'   e.g., "population", "tax", "mortality", "housing", "medicine", "migration", "environment", "welfare", or "economy"
#' * adm3 Name of neighborhood/town-level (Eup-Myeon-Dong) administrative unit
#' * adm3_code  Code of the neighborhood/town-level (Eup-Myeon-Dong) administrative unit
#' * class1 First-level classification of the variable depending on the type
#' * class2 Second-level classification of the variable depending on the type
#' * unit Unit of measurement for the variable
#' * value  Value of the variable
#'
#' @note
#' NA values in the value field indicate that the data was omitted
#' or suppressed. We kept these NA values as-is to reflect the
#' original data from the source.
#' For temporal comparison, province names in adm1 field are
#' standardized to the common names with no suffix in metropolitan cities
#' and "-do" suffix in provinces.
#' For example, "Seoul" instead of "Seoul Metropolitan City",
#' and "Jeollabuk-do" instead of "Jeonbuk State".
#' "KRW" in the unit field stands for South Korean Won.
#' Values are as-is unless otherwise noted in the unit field
#' (e.g., "per 100k population" or "million KRW").
#' @source
#' * KOSIS (Korean Statistical Information Service)
#' @keywords datasets
"censuskor"

#' South Korea Census Boundary in 2020
#'
#' District level boundary data in 2020, repaired using 2015 historical adjacency
#' evidence and 2020 geometry only. Original attributes and row order are retained.
#' Polygon overlaps are removed and the Guro/Yeongdeungpo/Dongjak/Gwanak junction
#' is one shared point. Eight unresolved historical reference pairs and two
#' historically unconfirmed contacts remain documented for review.
#' @format An sf object with 250 rows and three fields: `year`, `adm2_code`,
#'   and `geometry`. Coordinates use EPSG:5179.
#' @details Validated 2010, 2015 and 2025 boundaries are registered datasets in
#'   the companion `tidycensuskr.sf` package; [load_districts()] selects their
#'   package automatically. Codes can be used to join [anycensus()] output.
#' @source Statistical Geographic Information Service (SGIS).
#' @keywords datasets
"adm2_sf_2020"

#' geofacet Grid for South Korea Administrative Districts (SGIS Standard, 2020)
#'
#' A geofacet grid for South Korea administrative districts (_Si-Gun-Gu_) based on
#' the Statistical Geographic Information Service (SGIS) standard in 2020.
#' Non-autonomous districts in cities are retained as separate entities.
#' This grid can be used with the [geofacet](https://CRAN.R-project.org/package=geofacet)
#' package to create faceted visualizations based on geographic layout.
#'
#' @format A data.frame with 250 rows and 6 variables
#' @details
#' * name Name of the district/municipal-level (Si-Gun-Gu) administrative unit
#' * code SGIS code of the district/municipal-level (Si-Gun-Gu) administrative unit
#' * row Row position in the geofacet grid
#' * col Column position in the geofacet grid
#'
#' @source
#' * Statistical Geographic Information Service (SGIS)
#' * GitHub username chichead in [GitHub geofacet issue page](https://github.com/hafen/geofacet/issues/358)
#' @keywords datasets
"kr_grid_adm2_sgis_2020"

#' Binary district spatial-weight matrices
#'
#' Symmetric, unstandardized integer matrices for 2020.
#' `w_mat_YYYY` combines exact Queen adjacency with documented marine road
#' bridges and subsea tunnels open by December 31 of that year.
#' `w_mat_o_YYYY` contains exact Queen adjacency alone.
#'
#' @format Square 250 by 250 integer matrices. Values are 0 or 1, the
#'   diagonal is zero, and dimnames are five-digit SGIS ADM2 codes.
#' @details
#' Rows follow [adm2_sf_2020], not sorted code order. Align observations by
#' code before analysis. The 2010, 2015 and 2025 versions are registered in
#' `tidycensuskr.sf`, with their corresponding boundaries.
#'
#' Parallel facilities between the same districts contribute one edge.
#' Within-district facilities contribute no diagonal entries. Ordinary inland
#' river bridges, dykes, railway tunnels and facilities opening after the
#' cutoff are not added. Marine bay and estuary crossings are included.
#' Islands may have zero neighbors; row standardization is left to the user.
#'
#' Exact Queen adjacency uses `sf::st_touches()` with no snapping tolerance.
#' The 2020 coverage has no polygon overlaps. Unresolved historical contacts
#' are documented with the repair artifacts.
#' These matrices represent the supplied geometry plus the researched transport
#' inventory, rather than a guarantee of complete real-world connectivity.
#'
#' The connection inventory and code-order metadata are distributed under
#' `system.file("extdata", "spatial_weights", package = "tidycensuskr.sf")`.
#' @source SGIS/KOSTAT boundaries; Ministry of Land, Infrastructure and
#'   Transport, local government and National Archives facility records.
#'   Reproducible scripts and the source-linked inventory are in the source
#'   repository's `tools/sgg_connection_list.md` and `tools/create_w_mat.R`.
#' @examples
#' data(w_mat_2020)
#' data(adm2_sf_2020)
#' stopifnot(identical(rownames(w_mat_2020), as.character(adm2_sf_2020$adm2_code)))
#' @name spatial_weights
#' @keywords datasets
NULL

#' @rdname spatial_weights
"w_mat_2020"

#' @rdname spatial_weights
"w_mat_o_2020"
