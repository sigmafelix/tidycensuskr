# South Korea Census Data

District level data including tax, population, business entities,
housing, economy, medicine and mortality in South Korea in 2010, 2015,
and/or 2020. The availble years and variables depend on the type of
data.

## Usage

``` r
censuskor
```

## Format

A data.frame with 67232 rows and 10 variables:

## Source

- KOSIS (Korean Statistical Information Service)

## Details

- year Year of the census data, e.g., 2010, 2015, or 2020

- adm1 Name of the province-level (Sido) administrative unit

- adm1_code Code of the province-level (Sido) administrative unit

- adm2 Name of the district/municipal-level (Sigungu) administrative
  unit

- adm2_code Code of the district/municipal-level (Sigungu)
  administrative unit

- type Type of variable, e.g., "population", "tax", "mortality",
  "housing", "medicine", "migration", "environment", "welfare", or
  "economy"

- class1 First-level classification of the variable depending on the
  type

- class2 Second-level classification of the variable depending on the
  type

- unit Unit of measurement for the variable

- value Value of the variable

## Note

NA values in the value field indicate that the data was omitted or
suppressed. We kept these NA values as-is to reflect the original data
from the source. For temporal comparison, province names in adm1 field
are standardized to the common names with no suffix in metropolitan
cities and "-do" suffix in provinces. For example, "Seoul" instead of
"Seoul Metropolitan City", and "Jeollabuk-do" instead of "Jeonbuk
State". "KRW" in the unit field stands for South Korean Won. Values are
as-is unless otherwise noted in the unit field (e.g., "per 100k
population" or "million KRW").
