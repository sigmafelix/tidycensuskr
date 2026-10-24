#' Catalog available census variables
#'
#' Return the combinations of year, geographic level, `type`, `class1`, and
#' `class2` available in `censuskor`, with units and row counts.
#'
#' @return A data frame with columns `year`, `level`, `type`, `class1`,
#'   `class2`, `unit`, and `n`.
#' @examples
#' catalog()
#' @export
catalog <- function() {
  utils::data("censuskor", package = "tidycensuskr", envir = environment())

  censuskor |>
    dplyr::mutate(
      level = ifelse(is.na(adm3_code), "adm2", "adm3")
    ) |>
    dplyr::count(year, level, type, class1, class2, unit, name = "n") |>
    dplyr::arrange(year, level, type, class1, class2, unit)
}
