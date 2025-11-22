###
.onAttach <- function(libname, pkgname) {
  desc_file <- system.file("DESCRIPTION", package = pkgname)
  if (file.exists(desc_file)) {
    build_date <- file.info(desc_file)$mtime
    packageStartupMessage(
      sprintf(
        "tidycensuskr %s (%s)
Please install the companion data package tidycensuskr.sf to use the district boundaries.
install.packages('tidycensuskr.sf', repos = 'https://sigmafelix.r-universe.dev')\n",
        utils::packageVersion(pkgname),
        format(build_date, "%Y-%m-%d")
      )
    )
  }
}
