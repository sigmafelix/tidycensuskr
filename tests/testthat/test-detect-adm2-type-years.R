testthat::test_that("district filtering uses parents from the same year", {
  x <- data.frame(
    year = c(2020, 2015, 2010, 2015, 2020, 2015),
    adm2_code = c(31050, 31050, 29010, 31051, 31010, 31052)
  )

  testthat::expect_identical(
    detect_adm2_type(x, mode = "non"),
    x[c(1, 3, 4, 5, 6), , drop = FALSE]
  )
  testthat::expect_identical(
    detect_adm2_type(x, mode = "atn"),
    x[c(1, 2, 3, 5), , drop = FALSE]
  )
  testthat::expect_identical(
    detect_adm2_type(x, year = 2015, mode = "non"),
    x[c(4, 6), , drop = FALSE]
  )
  no_year <- x[x$year == 2015, "adm2_code", drop = FALSE]
  testthat::expect_identical(
    detect_adm2_type(no_year, mode = "non"),
    no_year[2:3, , drop = FALSE]
  )
  testthat::expect_identical(detect_adm2_type(x[FALSE, ], mode = "non"), x[FALSE, ])
})

testthat::test_that("non-autonomous parents must exist in the same year", {
  x <- data.frame(year = c(2015, 2020), adm2_code = c(31050, 31051))
  testthat::expect_warning(
    result <- detect_adm2_type(x, mode = "non"),
    "do not have corresponding upper level unit codes"
  )
  testthat::expect_identical(result, x)
})
