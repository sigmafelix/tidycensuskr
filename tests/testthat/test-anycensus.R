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
  "anycensusk returns correct data for adm2_code (numeric code)", {
  res <- anycensusk(codes = "11", type = "population")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(all(grepl("^11", res$adm2_code)))
})

testthat::test_that(
  "anycensusk returns correct data for adm1 (character name)", {
  res <- anycensusk(codes = "Seoul", type = "tax")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(all(res$adm1 == "Seoul"))
})

testthat::test_that(
  "anycensusk returns all data when codes is NULL", {
  res <- anycensusk(codes = NULL, type = "mortality")
  testthat::expect_true(is.data.frame(res))
  testthat::expect_true(nrow(res) >= 2)
})


testthat::test_that(
  "anycensusk handles invalid code length for adm2_code", {
  testthat::expect_error(anycensusk(codes = "111", type = "population"))
})

testthat::test_that(
  "anycensusk cleans up column names", {
  res <- anycensusk(codes = "11", type = "population")
  testthat::expect_false(any(grepl("_NA", names(res))))
})
