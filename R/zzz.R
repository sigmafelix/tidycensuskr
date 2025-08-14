###
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    sprintf("tidycensuskr %s (%s)", utils::packageVersion(pkgname), Sys.Date())
  )
}


#' Set KOSIS API Key from a File
#'
#' @param file A character string specifying the path to the file
#'   containing the KOSIS API key.
#' @return NULL
#' @export
#' @description This function reads a KOSIS API key from a specified file and
#'   sets it for use in KOSIS API calls.
#' @details The file should contain the API key as a single line of text.
#'   If the file does not exist, an error will be raised.
#' @importFrom kosis kosis.setKey
set_kosis_key <- function(file) {
  # Check if the file exists
  if (!file.exists(file)) {
    stop("The specified file does not exist.")
  }

  # Read the key from the file
  key <- readLines(file, warn = FALSE)

  # Set the KOSIS key
  kosis::kosis.setKey(key[1])

  message("KOSIS key has been set successfully.")
}
