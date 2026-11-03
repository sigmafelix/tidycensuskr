test_that("supplemental matrices preserve binary symmetry, code order and marine union", {
  for (year in c(2020)) {
    e <- new.env()
    marine_name <- paste0("w_mat_", year)
    queen_name <- paste0("w_mat_o_", year)
    utils::data(list = c(marine_name, queen_name), package = "tidycensuskr", envir = e)
    marine <- e[[marine_name]]
    queen <- e[[queen_name]]
    n <- c(`2010` = 251L, `2015` = 252L, `2020` = 250L, `2025` = 252L)[as.character(year)]
    expect_identical(dim(marine), rep(unname(n), 2L))
    for (m in list(marine, queen)) {
      expect_type(m, "integer")
      expect_identical(m, t(m))
      expect_true(all(m %in% 0:1))
      expect_true(all(diag(m) == 0L))
      expect_identical(rownames(m), colnames(m))
      expect_false(anyDuplicated(rownames(m)) > 0L)
    }
    expect_identical(dimnames(marine), dimnames(queen))
    expect_true(all(marine >= queen))
    # Marine access across the same endpoints existed by the first snapshot.
    expect_equal(marine["21120", "38090"], 1L) # 2010-12-14 Geoga
    expect_equal(marine["23010", "23080"], 1L) # Yeongjong / later North Port tunnel
    # Shindo bridge opened in 2026, so Jung--Ongjin has no added edge.
    ongjin <- if (year == 2025) "23520" else "23320"
    expect_equal(marine["23010", ongjin], queen["23010", ongjin])
  }
})

test_that("bundled 2020 boundary and matrices agree on repaired Queen contacts", {
  e <- new.env()
  utils::data(list = c("adm2_sf_2020", "w_mat_2020", "w_mat_o_2020"),
              package = "tidycensuskr", envir = e)
  x <- e$adm2_sf_2020
  expect_identical(as.character(x$adm2_code), rownames(e$w_mat_o_2020))
  expect_true(all(sf::st_is_valid(x)))
  expect_true(all(lengths(sf::st_overlaps(x)) == 0L))
  q <- sf::st_touches(x, sparse = FALSE)
  expect_equal(unname(e$w_mat_o_2020), unname(q * 1L))
  expect_equal(sum(e$w_mat_o_2020) / 2, 640)
  expect_equal(sum(e$w_mat_2020) / 2, 659)
  codes <- c(11170L, 11190L, 11200L, 11210L)
  g <- sf::st_geometry(x[match(codes, x$adm2_code), ])
  point <- Reduce(sf::st_intersection, lapply(seq_along(g), function(i) g[i]))
  expect_equal(as.character(sf::st_geometry_type(point)), "POINT")
  expect_identical(load_districts(2020), x)
  expect_equal(e$w_mat_2020["34030", "34380"], 1L) # Wonsan-Anmyeon 2019
})


test_that("the local 2020 coverage matches its Queen matrix", {
  for (year in c(2020)) {
    e <- new.env()
    name <- sprintf("adm2_sf_%d", year)
    qname <- sprintf("w_mat_o_%d", year)
    utils::data(list=c(name,qname),package="tidycensuskr",envir=e)
    x <- e[[name]]
    expect_identical(load_districts(year),x)
    expect_identical(as.character(x$adm2_code),rownames(e[[qname]]))
    expect_true(all(sf::st_is_valid(x)))
    expect_true(all(lengths(sf::st_overlaps(x))==0L))
    expect_equal(unname(e[[qname]]),unname(sf::st_touches(x,sparse=FALSE)*1L))

  }
})
