
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
