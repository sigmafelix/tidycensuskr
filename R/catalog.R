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
  .data <- NULL
  utils::data("censuskor", package = "tidycensuskr", envir = environment())

  get("censuskor", envir = environment(), inherits = FALSE) |>
    dplyr::mutate(
      level = ifelse(is.na(.data[["adm3_code"]]), "adm2", "adm3")
    ) |>
    dplyr::count(
      .data[["year"]], .data[["level"]], .data[["type"]], .data[["class1"]],
      .data[["class2"]], .data[["unit"]], name = "n"
    ) |>
    dplyr::arrange(
      .data[["year"]], .data[["level"]], .data[["type"]], .data[["class1"]],
      .data[["class2"]], .data[["unit"]]
    )
}
