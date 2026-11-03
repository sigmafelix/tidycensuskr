# Run after the candidate build: Rscript tools/test_repair_adm2_topology_2020.R
source("tools/repair_adm2_topology_2020.R")
passed <- 0L
verify <- function(label, code) {
  force(code)
  passed <<- passed + 1L
  cat("PASS:", label, "\n")
}
rectangle <- function(x0, x1, y0 = 0, y1 = 10) {
  st_polygon(list(rbind(c(x0, y0), c(x1, y0), c(x1, y1), c(x0, y1), c(x0, y0))))
}
fixture <- st_sf(year = 2020L, adm2_code = c("10001", "10002"),
                 geometry = st_sfc(rectangle(0, 10), rectangle(9.9, 20), crs = 5179))
verify("planar partition removes overlaps, preserves attributes and national union", {
  p <- partition_coverage(fixture)
  stopifnot(nrow(relations(p$x, "interior")) == 0, nrow(relations(p$x)) == 1,
            all(st_is_valid(p$x)), identical(st_drop_geometry(fixture), st_drop_geometry(p$x)),
            area_m2(st_sym_difference(st_union(fixture), st_union(p$x))) < 1e-9)
})
verify("a genuine enclosed hole is not filled by generic coverage reconstruction", {
  x <- fixture
  st_geometry(x)[[1]] <- st_polygon(list(unclass(st_geometry(x)[[1]])[[1]],
                                       rbind(c(2, 2), c(2, 3), c(3, 3), c(3, 2), c(2, 2))))
  p <- partition_coverage(x)
  stopifnot(sum(as.numeric(st_area(p$faces[is.na(p$owner)]))) == 1,
            area_m2(st_sym_difference(st_union(x), st_union(p$x))) < 1e-9)
})
verify("reference components with changed codes aggregate into the original target order", {
  target <- fixture; st_geometry(target)[2] <- st_sfc(rectangle(10, 20), crs = 5179)
  ref <- st_sf(year = 2015L, adm2_code = c("20001", "20002", "10002"),
               geometry = st_sfc(rectangle(0, 5), rectangle(5, 10), rectangle(10, 20), crs = 5179))
  matched <- align_reference(ref, target, 2015)
  stopifnot(identical(matched$x$adm2_code, target$adm2_code),
            identical(matched$mapping$target_code, c("10001", "10001", "10002")),
            all(st_equals(matched$x, target, sparse = FALSE)[cbind(1:2, 1:2)]))
})

original <- readRDS("../tidycensuskr.sf/inst/extdata/adm2_sf_2020.rds")
original$adm2_code <- as.character(original$adm2_code)
neighbours <- c("11190", "11200", "11210", "11170")
x <- original[match(neighbours, original$adm2_code), ]
ref15 <- readRDS("../tidycensuskr.sf/inst/extdata/adm2_sf_2015.rds")
ref15 <- ref15[match(neighbours, ref15$adm2_code), ]; ref15$adm2_code <- as.character(ref15$adm2_code)
p <- partition_coverage(x)
limits <- list(pair_gap_m = 1, gap_width_m = 1, gap_area_m2 = 100,
               junction_span_m = 1, reference_distance_m = 25)
verify("the four districts share one exact 2015-style junction", {
  fixed <- repair_junctions(p, ref15, limits)
  keys <- relations(fixed$x)$key
  stopifnot("11190:11210" %in% keys, "11170:11200" %in% keys,
            nrow(relations(fixed$x, "interior")) == 0, all(st_is_valid(fixed$x)),
            nrow(fixed$controls) == 1L, fixed$controls$districts == "11170|11190|11200|11210")
  stopifnot(abs(fixed$audit$initial_gap_m[match("11170:11200", fixed$audit$key)] - 0.2338424) < 1e-6)
  for (pair in list(c("11190", "11210"), c("11170", "11200"))) {
    idx <- match(pair, fixed$x$adm2_code)
    stopifnot(st_relate(fixed$x[idx[1], ], fixed$x[idx[2], ], sparse = FALSE)[1] == "FF2F01212",
              shared_border_m(st_geometry(fixed$x)[idx[1]], st_geometry(fixed$x)[idx[2]]) == 0)
  }
  xy_key <- function(g) unique(apply(st_coordinates(g)[, 1:2, drop = FALSE], 1, function(z) paste(sprintf("%a", z), collapse = ":")))
  shared <- Reduce(intersect, lapply(seq_len(4), function(i) xy_key(st_geometry(fixed$x)[i])))
  point <- paste(sprintf("%a", st_coordinates(fixed$controls)[1, 1:2]), collapse = ":")
  stopifnot(length(shared) == 1L, shared == point)
})
verify("a future-year reference is rejected", {
  future <- ref15; future$year <- 2025L
  stopifnot(inherits(try(repair_junctions(p, future, limits), silent = TRUE), "try-error"),
            inherits(try(align_reference(future, p$x, 2025), silent = TRUE), "try-error"))
})

verify("reference disagreement cannot create a new junction", {
  ref <- ref15
  st_geometry(ref)[3] <- st_geometry(ref)[3] + c(10000, 10000)
  fixed <- repair_junctions(p, ref, limits)
  stopifnot(is.null(fixed$controls), !("11190:11210" %in% relations(fixed$x)$key),
            area_m2(st_sym_difference(st_union(p$x), st_union(fixed$x))) == 0)
})
verify("a tight junction span leaves the source geometry unchanged", {
  strict <- limits; strict$junction_span_m <- 0.1
  fixed <- repair_junctions(p, ref15, strict)
  stopifnot(is.null(fixed$controls), identical(st_geometry(p$x), st_geometry(fixed$x)))
})

folder <- "tools/adm2_topology_2020"
final <- readRDS(file.path(folder, "adm2_sf_2020_repaired.rds"))
verify("national candidate retains all original exact Queen links, row order and identifiers", {
  stopifnot(nrow(final) == 250L, all(st_is_valid(final)),
            identical(final$adm2_code, original$adm2_code),
            all(relations(original)$key %in% relations(final)$key),
            nrow(relations(final)) == 640L, nrow(relations(final, "interior")) == 0L)
})
verify("rebuilding the repaired coverage is idempotent in area and adjacency", {
  again <- partition_coverage(final)$x
  difference <- sum(vapply(seq_len(nrow(final)), function(i) area_m2(st_sym_difference(st_geometry(again)[i], st_geometry(final)[i])), numeric(1)))
  stopifnot(difference < 0.01, setequal(relations(again)$key, relations(final)$key),
            nrow(relations(again, "interior")) == 0L)
})
verify("a 2.2 km reference disagreement is explicitly retained for historical review", {
  remaining <- read.csv(file.path(folder, "unrestored_reference_pairs.csv"), colClasses = c(code_a = "character", code_b = "character"))
  stopifnot("31070:34080" %in% remaining$key, remaining$distance_m[match("31070:34080", remaining$key)] > 2200)
})
verify("CSV WKT round trip preserves codes, exact relations and edge-matched coverage", {
  frame <- read.csv(file.path(folder, "adm2_sf_2020_repaired.csv"), colClasses = c(adm2_code = "character", geometry_wkt = "character"))
  restored <- st_as_sf(frame, wkt = "geometry_wkt", crs = 5179)
  stopifnot(identical(restored$adm2_code, final$adm2_code),
            setequal(relations(restored)$key, relations(final)$key),
            all(st_is_valid(restored)), nrow(relations(restored, "interior")) == 0L,
            length(geos_operation(restored, "coverageValidate", file.path(folder, ".cache"))) == 0L)
})
verify("all four serialized polygons retain the exact same junction coordinate", {
  node <- st_coordinates(st_read(file.path(folder, "junction_controls.gpkg"), quiet = TRUE))[1, 1:2]
  node_key <- paste(sprintf("%a", node), collapse = ":")
  frame <- read.csv(file.path(folder, "adm2_sf_2020_repaired.csv"), colClasses = c(adm2_code = "character", geometry_wkt = "character"))
  datasets <- list(final, st_read(file.path(folder, "adm2_sf_2020_repaired.geojson"), quiet = TRUE),
                   st_as_sf(frame, wkt = "geometry_wkt", crs = 5179))
  for (data in datasets) {
    ids <- match(neighbours, as.character(data$adm2_code))
    keys <- lapply(ids, function(i) {
      xy <- st_coordinates(st_geometry(data)[i])[, 1:2, drop = FALSE]
      unique(paste(sprintf("%a", xy[, 1]), sprintf("%a", xy[, 2]), sep = ":"))
    })
    shared <- Reduce(intersect, keys)
    stopifnot(length(shared) == 1L, shared == node_key)
  }
})
cat("Verified", passed, "focused checks.\n")
