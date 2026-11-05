
testthat::test_that(
  "anycensus returns correct data for adm2_code (numeric code)", {
  res <- anycensus(codes = 11, type = "population")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(all(grepl("^11", res$adm2_code)))
})

testthat::test_that(
  "anycensus returns correct data for adm1 (character name)", {
  res <- anycensus(codes = c("Seoul"), type = "tax")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(all(res$adm1 == "Seoul"))
})

testthat::test_that(
  "anycensus returns all data when codes is NULL", {
  res <- anycensus(codes = NULL, type = "mortality")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(nrow(res) >= 2)
})


testthat::test_that(
  "anycensus cleans up column names", {
  res <- anycensus(codes = "11", type = "population")
  testthat::expect_false(any(grepl("_NA", names(res))))
})


testthat::test_that(
  "anycensus() with mixed type codes will fail", {
  testthat::expect_error(
    anycensus(codes = c("21", "Gyeongsang"), type = "population"),
    "Mixed types in 'codes' are not allowed."
  )
})


testthat::test_that(
  "anycensus() with integer-convertible codes will pass", {
  testthat::expect_message(
    anycensus(codes = c("21", "38"), type = "population"),
    "Using character codes that are convertible to integers. Automatically converting to integers..."
  )
})


testthat::test_that(
  "anycensus() returns a summarized adm1 data.frame",
  {
    res <- anycensus(codes = "Seoul", type = "population", level = "adm1")
    testthat::expect_true(is.data.frame(res))
    testthat::expect_true(all(res$adm1 == "Seoul"))
    testthat::expect_true(all(nchar(res$adm1_code) == 2))
  }
)

testthat::test_that(
  "anycensus() can compute population-weighted adm1 rates",
  {
    adm2_mortality <- anycensus(
      codes = "Seoul",
      type = "mortality",
      year = 2020,
      level = "adm2"
    )
    adm2_population <- anycensus(
      codes = "Seoul",
      type = "population",
      year = 2020,
      level = "adm2"
    )
    expected_rate <- stats::weighted.mean(
      adm2_mortality[["all causes_total_p1p"]],
      adm2_population[["all households_total_prs"]],
      na.rm = TRUE
    )

    res <- anycensus(
      codes = "Seoul",
      type = "mortality",
      year = 2020,
      level = "adm1",
      aggregator = stats::weighted.mean,
      weight_type = "population",
      weight_column = "all households_total_prs",
      na.rm = TRUE
    )

    testthat::expect_equal(res[["all causes_total_p1p"]], expected_rate)
    testthat::expect_equal(
      res[["all households_total_prs"]],
      sum(adm2_population[["all households_total_prs"]], na.rm = TRUE)
    )
  }
)

testthat::test_that(
  "anycensus() can keep autonomous/basic local government adm2 rows",
  {
    res <- anycensus(
      codes = "Gyeonggi-do",
      type = "population",
      year = 2020,
      level = "adm2",
      adm2_type = "atn"
    )
    districts <- anycensus(
      codes = "Gyeonggi-do",
      type = "population",
      year = 2020,
      level = "adm2",
      adm2_type = "non"
    )

    testthat::expect_equal(
      res[["all households_total_prs"]][res$adm2_code == 31010],
      sum(districts[["all households_total_prs"]][districts$adm2_code %in% 31011:31014])
    )
    testthat::expect_false(any(substr(res$adm2_code, 5, 5) != "0"))
  }
)

testthat::test_that(
  "anycensus() can compute autonomous-only weighted adm1 rates",
  {
    adm2_mortality <- anycensus(
      codes = "Gyeonggi-do",
      type = "mortality",
      year = 2020,
      level = "adm2"
    ) |>
      detect_adm2_type(mode = "non")
    adm2_population <- anycensus(
      codes = "Gyeonggi-do",
      type = "population",
      year = 2020,
      level = "adm2"
    ) |>
      detect_adm2_type(mode = "non")
    expected_rate <- stats::weighted.mean(
      adm2_mortality[["all causes_total_p1p"]],
      adm2_population[["all households_total_prs"]],
      na.rm = TRUE
    )

    res <- anycensus(
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

    testthat::expect_equal(res[["all causes_total_p1p"]], expected_rate)
    testthat::expect_equal(
      res[["all households_total_prs"]],
      sum(adm2_population[["all households_total_prs"]], na.rm = TRUE)
    )
  }
)

testthat::test_that(
  "anycensus() can compute autonomous-only weighted adm2 rates",
  {
    adm2_mortality <- anycensus(
      codes = "Gyeonggi-do",
      type = "mortality",
      year = 2020,
      level = "adm2"
    )
    adm2_population <- anycensus(
      codes = "Gyeonggi-do",
      type = "population",
      year = 2020,
      level = "adm2"
    )
    seongnam_component_codes <- c(31021, 31022, 31023)
    expected_rate <- stats::weighted.mean(
      adm2_mortality[
        adm2_mortality$adm2_code %in% seongnam_component_codes,
        "all causes_total_p1p",
        drop = TRUE
      ],
      adm2_population[
        adm2_population$adm2_code %in% seongnam_component_codes,
        "all households_total_prs",
        drop = TRUE
      ],
      na.rm = TRUE
    )
    expected_population <- sum(
      adm2_population[
        adm2_population$adm2_code %in% seongnam_component_codes,
        "all households_total_prs",
        drop = TRUE
      ],
      na.rm = TRUE
    )

    res <- anycensus(
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
    seongnam <- res[res$adm2_code == 31020, ]

    testthat::expect_false(any(substr(res$adm2_code, 5, 5) != "0"))
    testthat::expect_equal(seongnam[["all causes_total_p1p"]], expected_rate)
    testthat::expect_equal(seongnam[["all households_total_prs"]], expected_population)
  }
)

testthat::test_that(
  "anycensus() rejects weighted adm2 computation without atn cleaning",
  {
    testthat::expect_error(
      anycensus(
        codes = "Gyeonggi-do",
        type = "mortality",
        year = 2020,
        level = "adm2",
        aggregator = stats::weighted.mean,
        weight_type = "population",
        weight_column = "all households_total_prs",
        na.rm = TRUE
      ),
      "Weighted adm2 computation is only available"
    )
  }
)

testthat::test_that("anycensus keeps adm2 and adm3 observations separate", {
  adm2 <- anycensus(codes = 11, type = "population", level = "adm2")
  adm3 <- anycensus(codes = 11010, type = "population", level = "adm3")

  testthat::expect_true(all(grepl("^11", adm2$adm2_code)))
  testthat::expect_false("adm3_code" %in% names(adm2))
  testthat::expect_false(any(vapply(adm2, is.list, logical(1))))

  testthat::expect_true(all(grepl("^11010", adm3$adm3_code)))
  testthat::expect_true(all(!is.na(adm3$adm3_code)))
  testthat::expect_false(any(vapply(adm3, is.list, logical(1))))
})

testthat::test_that("anycensus resolves parent names for adm3 queries", {
  by_code <- anycensus(codes = 11010, type = "population", level = "adm3")
  by_name <- anycensus(
    codes = "Jongno-gu",
    type = "population",
    level = "adm3"
  )

  testthat::expect_equal(sort(by_name$adm3_code), sort(by_code$adm3_code))
})

testthat::test_that("anycensus supports NULL codes at adm3 level", {
  res <- anycensus(codes = NULL, type = "population", level = "adm3")

  testthat::expect_gt(nrow(res), 0)
  testthat::expect_true(all(!is.na(res$adm3_code)))
})

testthat::test_that("anycensus supports multiple codes", {
  by_code <- anycensus(
    codes = c(11, 26),
    type = "population",
    level = "adm2"
  )
  by_name <- anycensus(
    codes = c("Seoul", "Busan"),
    type = "population",
    level = "adm2"
  )

  testthat::expect_setequal(unique(by_code$adm1_code), c(11, 26))
  testthat::expect_true(all(grepl("^(11|26)", by_code$adm2_code)))
  testthat::expect_setequal(unique(by_name$adm1_code), c(11, 21))
})

testthat::test_that("anycensus supports multiple type values", {
  res <- anycensus(
    codes = c(11, 26),
    type = c("population", "housing"),
    level = "adm2"
  )

  testthat::expect_setequal(unique(res$adm1_code), c(11, 26))
  testthat::expect_setequal(unique(res$type), c("population", "housing"))
  testthat::expect_true(all(grepl("^(11|26)", res$adm2_code)))
})

testthat::test_that("anycensus rejects multiple weighted type values", {
  testthat::expect_error(
    anycensus(
      codes = 11,
      type = c("mortality", "population"),
      level = "adm1",
      weight_type = "population"
    ),
    "requires a single `type`"
  )
})

# testthat::test_that(
#   "load_districts() returns correct sf object",
#   {
#     withr::local_package("sf")
#     res2020 <- load_districts(year = 2020)
#     res2015 <- load_districts(year = 2015)
#     res2010 <- load_districts(year = 2010)
#     testthat::expect_s3_class(res2020, "sf")
#     testthat::expect_s3_class(res2015, "sf")
#     testthat::expect_s3_class(res2010, "sf")
#     testthat::expect_true(all(res2020[["year"]] == 2020))
#     testthat::expect_true(all(res2015[["year"]] == 2015))
#     testthat::expect_true(all(res2010[["year"]] == 2010))
#   }
# )

testthat::test_that(
  "anycensus() rebuilds cities that only report non-autonomous Gu rows",
  {
    # medicine reports only the Gu of cities such as Suwon-si (31011-31014)
    col <- "doctors_anesthesiology and pain medicine_prs"
    res <- anycensus(2020, type = "medicine", level = "adm2", adm2_type = "atn")
    suwon <- res[res$adm2_code == 31010, ]
    testthat::expect_equal(nrow(suwon), 1)
    testthat::expect_equal(suwon$adm2, "Suwon-si")
    testthat::expect_equal(suwon[[col]], 16 + 11 + 45 + 44)
    testthat::expect_false(any(res$adm2_code %in% 31011:31019))

    atn <- anycensus(2020, type = "medicine", level = "adm1", adm2_type = "atn")
    testthat::expect_warning(
      non <- anycensus(2020, type = "medicine", level = "adm1", adm2_type = "non"),
      "Inconsistent codes"
    )
    testthat::expect_equal(atn[[col]][atn$adm1_code == 31], 998)
    testthat::expect_equal(non[[col]][non$adm1_code == 31], 998)

    weighted <- anycensus(
      2020, type = "medicine", level = "adm2", adm2_type = "atn",
      aggregator = weighted.mean, weight_type = "population",
      weight_col = "all households_total_prs"
    )
    testthat::expect_true(31010 %in% weighted$adm2_code)
  }
)

testthat::test_that(
  "adm2_type = 'atn' resolves cities with Gu variable by variable",
  {
    value <- function(d, code, col) unlist(d[[col]][d$adm2_code == code])

    # landuse city rows hold the mean of their Gu (Suwon-si: 89 = 356 / 4)
    landuse <- anycensus(2020, type = "landuse", adm2_type = "atn")
    testthat::expect_equal(value(landuse, 31010, "park_neighborhood_parks_cnt"), 356)

    # Bucheon-si 2015 medicine city row is all zeros
    medicine <- anycensus(2015, type = "medicine", adm2_type = "atn")
    testthat::expect_equal(
      value(medicine, 31050, "doctors_anesthesiology and pain medicine_prs"), 48 + 19 + 2
    )

    # Seongnam-si 2015: population only in its Gu, fertility rate in the city row
    population <- anycensus(2015, type = "population", adm2_type = "atn")
    testthat::expect_equal(value(population, 31020, "all households_total_prs"), 918710)
    testthat::expect_equal(value(population, 31020, "fertility_total_bpw"), 1.159)

    # Cheongju-si 2015 environment has 2 of its 4 Gu
    # (environment also raises the pivot_wider() list-column warning)
    warnings <- testthat::capture_warnings(
      environment <- anycensus(2015, type = "environment", adm2_type = "atn")
    )
    testthat::expect_true(any(grepl("incomplete set of non-autonomous Gu", warnings)))
    testthat::expect_equal(value(environment, 33040, "organic_matter_discharge_kg_"), 892)

    # Weighted queries sum counts and recalculate rates from the Gu
    weighted <- anycensus(
      2020, type = "population", adm2_type = "atn",
      aggregator = weighted.mean, weight_type = "population",
      weight_column = "all households_total_prs"
    )
    testthat::expect_equal(value(weighted, 31010, "all households_male_prs"), 576792)
    testthat::expect_equal(value(weighted, 31010, "fertility_total_bpw"), 0.787, tolerance = 1e-3)
  }
)
