# KOSIS census tables: 2015, 2020, 2025

Staged candidate assembled from KOSIS (organization 101) tables `DT_1JC1501`, `DT_1JC1502`, `DT_1JC1503`, `DT_1JU1501`, and `DT_1IN1502` for reference years 2015, 2020, and 2025. The reusable acquisition and cleaning workflow is `kosis_households_housing_15152025.R`; request-level metadata and row counts are in the accompanying `*_metadata.csv`, while row-level source provenance is in `*_provenance.csv`.

The cleaned long table follows the 12-column `censuskor` field order and is staged in Parquet and UTF-8 CSV. Geographic records are neighborhood level (eup/myeon/dong, ADM3). Source codes and names are retained in provenance. 2015 and 2020 source codes are normalized to the project's 7-digit pre-2021 ADM3 convention; 2025 codes remain 8-digit. English geography names use the SGIS lookup for the matching vintage, or the latest available 2024 lookup for 2025, with the KOSIS English label used only where it is unambiguous.

| Year | Cleaned rows | Missing values | ADM3 rows missing a mapped name |
| --- | ---: | ---: | ---: |
| 2015 | 226,980 | 28,996 | 585 |
| 2020 | 226,842 | 30,104 | 195 |
| 2025 | 227,648 | 27,367 | 768 |

Source suppression marker `X` is represented as missing (`NA`); no suppressed values were converted to zero. There are 24 distinct source geography cases requiring review: 9 in 2015, 3 in 2020, and 12 in 2025. Details and mapping status are in `*_unmatched_geographies.csv`. These rows remain staged with their source geography and code; the standardized ADM3 name is missing when the crosswalk or English label could not be resolved.

`class1` mappings are provisional pending review against the exact KOSIS item definitions: `DT_1JC1501` → `household composition`; `DT_1JC1502` → `household size`; `DT_1JC1503` → `households by dwelling type`; `DT_1JU1501` → `housing types`; and `DT_1IN1502` → `all households`, `domestic population`, `foreign population`, `census household totals`, or `census housing totals` according to its item. The first four table-level labels preserve the separate table concepts and prevent otherwise overlapping keys from collapsing; they are candidates, not approved additions to package nomenclature. `type` is `population` for population items and `housing` for housing/household items.

This is a review candidate, not an append to `data/censuskor.rda`. Check unmatched geography mappings and approve category labels before appending.
