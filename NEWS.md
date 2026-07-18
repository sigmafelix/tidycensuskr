# NEWS
## 0.3
- Database update: Added 2020 adm3 level data to `censuskor` (155K+ rows)
- `anycensus()` update for adm3 query

## 0.2
- `anycensus()` update for aggregating nonautonomous district data rows into basic local government level
- Added license information in vignettes and citations
- `detect_adm2_type()`: autodetect non-autonomous adm2 and filter for data cleaning
- Database update (0.2.7): 103K+ rows in `censuskor`
  - Added new variable type: `landuse`
- Database update (0.2.4): 67K+ rows in `censuskor`
  - Added new variable types: `welfare`
  - Added vacant housing statistics
- Database update (0.2.3): 42K+ rows in `censuskor`
- Separate `tidycensuskr.sf` package for boundary data
- Default data in 2020 are provided in the package: `censuskor` and `adm2_sf_2020`

## 0.1
- `censuskor` layout has been updated to include `year` in the data frame.
