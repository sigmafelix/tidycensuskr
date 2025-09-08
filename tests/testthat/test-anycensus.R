# Mock data for censuskor
# censuskor <- data.frame(
#   year = rep(2020, 6),
#   type = rep(c("population", "tax", "mortality"), each = 2),
#   adm1 = c("Seoul", "Busan", "Seoul", "Busan", "Seoul", "Busan"),
#   adm2_code = c("11", "26", "11", "26", "11", "26"),
#   class1 = c("A", "A", "B", "B", "C", "C"),
#   class2 = c("X", "Y", "X", "Y", "X", "Y"),
#   unit = c("명", "명", "원", "원", "명", "명"),
#   value = 1:6,
#   stringsAsFactors = FALSE
# )

testthat::test_that(
  "anycensus returns correct data for adm2_code (numeric code)", {
  res <- anycensus(codes = "11", type = "population")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(all(grepl("^11", res$adm2_code)))
})

testthat::test_that(
  "anycensus returns correct data for adm1 (character name)", {
  res <- anycensus(codes = "Seoul", type = "tax")
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
  "anycensus handles invalid code length for adm2_code", {
  testthat::expect_error(anycensus(codes = "111", type = "population"))
})

testthat::test_that(
  "anycensus cleans up column names", {
  res <- anycensus(codes = "11", type = "population")
  testthat::expect_false(any(grepl("_NA", names(res))))
})
