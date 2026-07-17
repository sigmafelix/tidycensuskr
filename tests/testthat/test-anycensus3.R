testthat::test_that("anycensus3 keeps adm2 and adm3 observations separate", {
  adm2 <- anycensus3(codes = 11, type = "population", level = "adm2")
  adm3 <- anycensus3(codes = 11010, type = "population", level = "adm3")

  testthat::expect_true(all(grepl("^11", adm2$adm2_code)))
  testthat::expect_false("adm3_code" %in% names(adm2))
  testthat::expect_false(any(vapply(adm2, is.list, logical(1))))

  testthat::expect_true(all(grepl("^11010", adm3$adm3_code)))
  testthat::expect_true(all(!is.na(adm3$adm3_code)))
  testthat::expect_false(any(vapply(adm3, is.list, logical(1))))
})

testthat::test_that("anycensus3 resolves parent names for adm3 queries", {
  by_code <- anycensus3(codes = 11010, type = "population", level = "adm3")
  by_name <- anycensus3(
    codes = "Jongno-gu",
    type = "population",
    level = "adm3"
  )

  testthat::expect_equal(sort(by_name$adm3_code), sort(by_code$adm3_code))
})

testthat::test_that("anycensus3 supports NULL codes at adm3 level", {
  res <- anycensus3(codes = NULL, type = "population", level = "adm3")

  testthat::expect_gt(nrow(res), 0)
  testthat::expect_true(all(!is.na(res$adm3_code)))
})

testthat::test_that("anycensus3 aggregates adm2 rows to adm1", {
  res <- anycensus3(codes = "Seoul", type = "population", level = "adm1")

  testthat::expect_equal(nrow(res), 1)
  testthat::expect_equal(res$adm1_code, 11)
})

testthat::test_that("anycensus3 supports multiple codes", {
  by_code <- anycensus3(
    codes = c(11, 26),
    type = "population",
    level = "adm2"
  )
  by_name <- anycensus3(
    codes = c("Seoul", "Busan"),
    type = "population",
    level = "adm2"
  )

  testthat::expect_setequal(unique(by_code$adm1_code), c(11, 26))
  testthat::expect_true(all(grepl("^(11|26)", by_code$adm2_code)))
  testthat::expect_setequal(unique(by_name$adm1_code), c(11, 21))
})

testthat::test_that("anycensus3 supports multiple type values", {
  res <- anycensus3(
    codes = c(11, 26),
    type = c("population", "housing"),
    level = "adm3"
  )

  testthat::expect_setequal(unique(res$adm1_code), c(11, 26))
  testthat::expect_setequal(unique(res$type), c("population", "housing"))
  testthat::expect_true(all(grepl("^(11|26)", res$adm2_code)))
})

testthat::test_that("anycensus3 rejects multiple weighted type values", {
  testthat::expect_error(
    anycensus3(
      codes = 11,
      type = c("mortality", "population"),
      level = "adm1",
      weight_type = "population"
    ),
    "requires a single `type`"
  )
})
