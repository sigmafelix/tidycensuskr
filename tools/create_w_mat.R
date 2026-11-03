# Rebuild boundary/weights from local sources. Default: stage only.
# Rscript tools/create_w_mat.R --publish also replaces the bundled R datasets.
library(sf)
library(jsonlite)

publish <- "--publish" %in% commandArgs(trailingOnly = TRUE)
out_dir <- "tools/spatial_weights"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
sf_dir <- "../tidycensuskr.sf/inst/extdata"
geojson <- "tools/adm2_topology/2020/adm2_sf_2020_repaired.geojson"
registry_path <- "tools/sgg_marine_connections.csv"
registry <- read.csv(registry_path, colClasses = "character", check.names = FALSE)
registry$opening_year <- as.integer(registry$opening_year)
override_path <- "tools/queen_adjacency_overrides.csv"
overrides <- read.csv(override_path,colClasses="character")

# Retain each existing boundary's attributes, code types and row order.
boundaries <- list()
boundary_sources <- character()
for (year in c(2010, 2015, 2020, 2025)) {
  source <- if (year == 2020) geojson else sprintf(
    "tools/adm2_topology/%d/adm2_sf_%d_repaired.rds", year, year)
  if (year == 2020) {
    e <- new.env(); load("data/adm2_sf_2020.rda", envir = e)
    x <- e$adm2_sf_2020
    repaired <- st_read(source, quiet = TRUE)
  } else {
    x <- readRDS(file.path(sf_dir, sprintf("adm2_sf_%d.rds", year)))
    repaired <- readRDS(source)
  }
  idx <- match(as.character(x$adm2_code), as.character(repaired$adm2_code))
  stopifnot(nrow(x) == nrow(repaired), !anyNA(idx),
            !anyDuplicated(repaired$adm2_code), st_crs(x) == st_crs(repaired))
  geometry <- st_geometry(repaired)[idx]
  if (all(st_geometry_type(x) == "MULTIPOLYGON")) geometry <- st_cast(geometry,"MULTIPOLYGON")
  st_geometry(x) <- geometry
  stopifnot(all(st_is_valid(x)), !any(lengths(st_overlaps(x))))
  name <- sprintf("adm2_sf_%d", year)
  assign(name, x)
  save(list = name, file = file.path(out_dir, paste0(name, ".rda")), compress = "xz")
  st_write(x, file.path(out_dir, paste0(name, ".gpkg")),
           layer = sprintf("adm2_%d", year), delete_dsn = TRUE, quiet = TRUE)
  if (publish) save(list = name, file = file.path(if (year == 2020) "data" else "../tidycensuskr.sf/data", paste0(name, ".rda")), compress = "xz")
  boundaries[[as.character(year)]] <- x
  boundary_sources[as.character(year)] <- source
}

summary <- list()
for (year in c(2010, 2015, 2020, 2025)) {
  source <- unname(boundary_sources[as.character(year)])
  x <- boundaries[[as.character(year)]]
  codes <- as.character(x$adm2_code)
  stopifnot(!anyNA(codes), !anyDuplicated(codes), all(nchar(codes) == 5L))
  queen <- st_touches(x, sparse = FALSE)
  diag(queen) <- FALSE
  stopifnot(identical(queen, t(queen)))
  geometric_queen <- queen
  requested <- overrides[overrides$year == as.character(year),,drop=FALSE]
  requested$source_queen <- logical(nrow(requested))
  requested$added <- logical(nrow(requested))
  for (i in seq_len(nrow(requested))) {
    a <- match(requested$code_a[i],codes); b <- match(requested$code_b[i],codes)
    stopifnot(!is.na(a),!is.na(b),a!=b)
    requested$source_queen[i] <- geometric_queen[a,b]
    requested$added[i] <- !queen[a,b]
    queen[a,b] <- queen[b,a] <- TRUE
  }
  write.csv(requested,file.path(out_dir,sprintf("queen_overrides_%d.csv",year)),row.names=FALSE)
  connected <- queen
  audit <- registry
  audit$year <- year
  audit$code_a <- if (year == 2025) audit$code_a_2025 else if (year == 2010) audit$code_a_2010 else audit$code_a
  audit$code_b <- if (year == 2025) audit$code_b_2025 else if (year == 2010) audit$code_b_2010 else audit$code_b
  audit$status <- "not_open_by_cutoff"
  for (i in seq_len(nrow(audit))) {
    if (audit$opening_year[i] > year) next
    a <- match(audit$code_a[i], codes)
    b <- match(audit$code_b[i], codes)
    stopifnot(!is.na(a), !is.na(b))
    audit$status[i] <- if (a == b) "same_district" else if (queen[a, b]) {
      "already_queen"
    } else if (connected[a, b]) "duplicate_pair" else "added"
    if (a != b) connected[a, b] <- connected[b, a] <- TRUE
  }
  write.csv(audit, file.path(out_dir, sprintf("connections_%d.csv", year)),
            row.names = FALSE, fileEncoding = "UTF-8")
  for (variant in c("queen", "marine")) {
    name <- paste0(if (variant == "queen") "w_mat_o_" else "w_mat_", year)
    m <- if (variant == "queen") queen else connected
    m <- matrix(as.integer(m), nrow = length(codes), dimnames = list(codes, codes))
    stopifnot(identical(m, t(m)), all(diag(m) == 0L), all(m %in% 0:1))
    assign(name, m)
    save(list = name, file = file.path(out_dir, paste0(name, ".rda")), compress = "xz")
    if (publish) save(list = name, file = file.path(if (year == 2020) "data" else "../tidycensuskr.sf/data", paste0(name, ".rda")), compress = "xz")
    write.csv(m, file.path(out_dir, paste0(name, "_matrix.csv")), row.names = TRUE)
    metadata <- list(year = year, boundary_vintage = year,
                     connection_cutoff = sprintf("%d-12-31", year),
                     rule = if (variant == "queen") "Queen with documented junction corrections" else "Queen with documented junction corrections plus marine road connections",
                     geometric_queen_pairs = sum(geometric_queen)/2,
                     queen_corrections_added = sum(requested$added),
                     queen_overrides = requested,
                     queen_overrides_md5 = unname(tools::md5sum(override_path)),
                     shape = c(nrow(m), ncol(m)), adm2_code_order = codes,
                     undirected_links = sum(m) / 2,
                     islands = codes[rowSums(m) == 0L],
                     boundary_source = source,
                     boundary_source_md5 = unname(tools::md5sum(source)),
                     registry_md5 = unname(tools::md5sum(registry_path)),
                     sf_version = as.character(packageVersion("sf")),
                     geos_version = unname(sf_extSoftVersion()["GEOS"]),
                     caveat = if (year %in% c(2010, 2015)) "Same-year planar partition repairs overlap ownership and edge matching; source holes are retained without independent evidence for filling." else if (year == 2020) "Topology repaired using 2015 historical evidence and 2020 geometry only; unresolved historical pairs retained for review." else "2025 boundary geometry is unchanged; the user-confirmed Guro/Yeongdeungpo/Dongjak/Gwanak four-way junction is restored in both matrices via documented adjacency overrides.")
    write_json(metadata, file.path(out_dir, paste0(name, "_order.json")),
               auto_unbox = TRUE, pretty = TRUE)
    summary[[name]] <- data.frame(dataset = name, year = year, districts = nrow(m),
                                 links = sum(m) / 2, islands = sum(rowSums(m) == 0L))
  }
  message(year, ": Queen ", sum(queen) / 2, "; marine ", sum(connected) / 2,
          "; new marine links ", sum(connected & !queen) / 2)
}
write.csv(do.call(rbind, summary), file.path(out_dir, "summary.csv"), row.names = FALSE)
write_json(list(corrected_geojson_md5 = unname(tools::md5sum(geojson)),
                registry_md5 = unname(tools::md5sum(registry_path)),
                queen_overrides_md5 = unname(tools::md5sum(override_path)),
                years = c(2010, 2015, 2020, 2025)),
           file.path(out_dir, "provenance.json"), auto_unbox = TRUE, pretty = TRUE)
