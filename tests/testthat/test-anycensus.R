
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
    expected <- anycensus(
      codes = "Gyeonggi-do",
      type = "population",
      year = 2020,
      level = "adm2"
    ) |>
      detect_adm2_type(mode = "atn")

    testthat::expect_equal(res, expected)
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
