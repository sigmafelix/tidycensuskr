testthat::test_that("all, atn and non distinguish city counts and rates", {
  value <- function(x, code, column) x[[column]][x$adm2_code == code]
  all <- anycensus(2020, codes = "Gyeonggi-do", type = "population", adm2_type = "all")
  atn <- anycensus(2020, codes = "Gyeonggi-do", type = "population", adm2_type = "atn")
  non <- anycensus(2020, codes = "Gyeonggi-do", type = "population", adm2_type = "non")
  gu <- 31011:31014

  testthat::expect_true(is.na(value(all, 31010, "all households_total_prs")))
  testthat::expect_equal(value(all, 31010, "fertility_total_bpw"), 0.796)
  testthat::expect_equal(value(atn, 31010, "all households_total_prs"),
                         sum(all[["all households_total_prs"]][all$adm2_code %in% gu]))
  testthat::expect_equal(value(atn, 31010, "fertility_total_bpw"), 0.796)
  testthat::expect_false(31010 %in% non$adm2_code)
  testthat::expect_true(all(gu %in% non$adm2_code))

  for (mode in c("all", "atn", "non")) {
    direct <- anycensus(2020, codes = 31010, type = "population", adm2_type = mode)
    expected <- switch(mode, all = all, atn = atn, non = non)
    expected_codes <- if (mode == "non") gu else 31010
    cols <- c("adm2_code", "all households_total_prs", "fertility_total_bpw")
    actual <- as.data.frame(direct[, cols])[order(direct$adm2_code), , drop = FALSE]
    target <- as.data.frame(expected[expected$adm2_code %in% expected_codes, cols])
    target <- target[order(target$adm2_code), , drop = FALSE]
    rownames(actual) <- rownames(target) <- NULL
    testthat::expect_equal(actual, target)
  }
})

testthat::test_that("province counts and weighted rates do not double count cities", {
  for (mode in c("all", "atn", "non")) {
    counts <- anycensus(2020, codes = "Gyeonggi-do", type = "population",
                        level = "adm1", adm2_type = mode)
    testthat::expect_equal(counts[["all households_total_prs"]], 12930625)
    rates <- anycensus(2020, codes = "Gyeonggi-do", type = "mortality",
                       level = "adm1", adm2_type = mode, weight_type = "population",
                       aggregator = weighted.mean, na.rm = TRUE)
    testthat::expect_equal(rates[["all households_total_prs"]], 12930625)
    testthat::expect_equal(rates[["all causes_total_p1p"]], 285.992614, tolerance = 1e-5)
  }
  city <- anycensus(2020, codes = 31010, type = "mortality", adm2_type = "atn",
                    weight_type = "population", aggregator = weighted.mean, na.rm = TRUE)
  testthat::expect_equal(city[["all households_total_prs"]], 1156179)
  testthat::expect_equal(city[["all causes_total_p1p"]], 289.177403, tolerance = 1e-5)
})

testthat::test_that("partial Gu counts replace the source city count with a warning", {
  x <- data.frame(year = 2020, type = "population", adm1 = "Seoul", adm1_code = 11,
                  adm2 = c("Example-si", "A-gu Example-si", "B-gu Example-si"),
                  adm2_code = c(11010, 11011, 11012), count = c(999, 10, 20),
                  rate = c(5, 6, 8))
  refs <- list(`2020 11010` = c("11011", "11012", "11013"))
  testthat::expect_warning(result <- .collapse_to_atn(x, refs, rate_columns = "rate"),
                           "incomplete set")
  testthat::expect_equal(result$count, 30)
  testthat::expect_equal(result$rate, 5)
})

testthat::test_that("a count-only city can yield an empty all result with its columns", {
  result <- anycensus(2020, codes = 31010, type = "landuse", adm2_type = "all")
  testthat::expect_equal(nrow(result), 0L)
  testthat::expect_true("park_neighborhood_parks_cnt" %in% names(result))
})
