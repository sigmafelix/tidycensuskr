# Download and stage the latest SGIS administrative neighborhood English names
# published in 2025. The source file's stated data vintage is 2024-12-31.
# Run from the repository root with:
#   Rscript tools/refresh_sgis_eup_myeon_dong_english_2025.R

source_url <- paste0(
  "https://www.data.go.kr/cmm/cmm/fileDownload.do?",
  "atchFileId=FILE_000000003182877&fileDetailSn=1&insertDataPrcus=N"
)
output_path <- "tools/sgis_eup_myeon_dong_english_2025.csv"
expected_columns <- c(
  "시도명", "시군구명", "읍면동명",
  "시도영문명", "시군구영문명", "읍면동영문명", "주소영문명"
)

refresh_sgis_names <- function() {
  source_path <- tempfile(fileext = ".csv")
  on.exit(unlink(source_path), add = TRUE)

  utils::download.file(
    source_url, destfile = source_path, mode = "wb", quiet = TRUE
  )
  source_data <- utils::read.csv(
    source_path,
    fileEncoding = "EUC-KR",
    colClasses = "character",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  if (!identical(names(source_data), expected_columns)) {
    stop("The downloaded SGIS table does not have the expected columns.")
  }
  natural_key <- source_data[c("시도명", "시군구명", "읍면동명")]
  if (anyNA(natural_key) || anyDuplicated(natural_key)) {
    stop("The downloaded SGIS table has missing or duplicate area names.")
  }
  english_columns <- c("시도영문명", "시군구영문명", "읍면동영문명", "주소영문명")
  if (any(vapply(
    source_data[english_columns],
    function(x) anyNA(x) || any(!nzchar(trimws(x))),
    logical(1)
  ))) {
    stop("The downloaded SGIS table has missing English names.")
  }

  utils::write.csv(
    source_data,
    file = output_path,
    row.names = FALSE,
    fileEncoding = "UTF-8",
    na = ""
  )
  message("Wrote ", nrow(source_data), " SGIS name records to ", output_path)
  message("Official source data vintage: 2024-12-31; published: 2025-07-08.")
}

refresh_sgis_names()
