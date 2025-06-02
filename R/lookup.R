#' Lookup KOSIS table code with a keyword
#'
#' @param keyword The keyword to search for in the KOSIS table codes.
#' @param ... Additional arguments passed to the `kosis` function.
#' @return A data frame containing the KOSIS table codes that match the keyword.
lookup_kosis <- function(keyword, ...) {
  # Check if the keyword is provided
  if (missing(keyword)) {
    stop("Please provide a keyword to search for.")
  }
  
  # Load the KOSIS table codes using the kosis function with the keyword
  table_codes <- kosis("TBL_CODE", keyword = keyword, ...)
  
  # Return the table codes
  return(table_codes)
}



