#' Load KOSIS dataset
#'
#' @param type Statistics type. e.g., "population", "economy", etc.
#'   See `?stat_types`
#' @param ... Additional arguments passed to the `kosis` function.
#' @return A data frame containing the dataset.
#' @export
load_dataset <- function(type, year, ...) {
  # Check if the dataset_id is provided
  if (missing(dataset_id)) {
    stop("Please provide a dataset ID.")
  }
  
  # Load the dataset using the kosis function
  dataset <- kosis(dataset_id, ...)
  
  # Return the loaded dataset
  return(dataset)
}



#' Experimental function to load population data from KOSIS
#'
#' @param year The year for which to load the population data.
#' @param ... Additional arguments passed to the `kosis` function.
#' @return A data frame containing the population data for the specified year.
#' @export
#' @importFrom kosis getStatDataFromURL
#' @note This function is experimental and may change in future versions.
#'   It only supports loading raw population data in a single year.
#' @examples
#' \dontrun{
#' # Load population data for the year 2020
#' population_data <- load_population(2020)
#' }
#' @references
#' - KOSIS
load_population <- function(year) {
  # Check if the year is provided
  if (missing(year)) {
    stop("Please provide a year.")
  }
  # nolint start
  # Load the population dataset using the kosis function
  dataset <- kosis::getStatDataFromURL(
    sprintf(
      paste0(
        "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&",
        "apiKey=&itmId=T00&",
        "objL1=11010+11020+11030+11040+11050+11060+11070+11080+11090+11100+11110+11120+",
        "11130+11140+11150+11160+11170+11180+11190+11200+11210+11220+11230+11240+11250+",
        "21004+21005+21003+21010+21020+21030+21040+21050+21060+21070+21080+21090+21100+",
        "21110+21120+21130+21140+21150+21510+22004+22005+22003+22010+22020+22030+22040+",
        "22050+22060+22070+22510+22520+23004+23005+23003+23010+23020+23030+23040+23050+",
        "23060+23070+23080+23090+23510+23520+24010+24020+24030+24040+24050+25010+25020+",
        "25030+25040+25050+26004+26005+26003+26010+26020+26030+26040+26510+29004+29005+",
        "29003+29010+31004+31005+31003+31010+31011+31012+31013+31014+31020+31021+31022+",
        "31023+31030+31040+31041+31042+31050+31051+31052+31053+31060+31070+31080+31090+",
        "31091+31092+31100+31101+31103+31104+31110+31120+31130+31140+31150+31160+31170+",
        "31180+31190+31191+31192+31193+31200+31210+31220+31230+31240+31250+31260+31270+",
        "31280+31550+31570+31580+32004+32005+32003+32010+32020+32030+32040+32050+32060+",
        "32070+32510+32520+32530+32540+32550+32560+32570+32580+32590+32600+32610+33004+",
        "33005+33003+33020+33030+33040+33041+33042+33043+33044+33520+33530+33540+33550+",
        "33560+33570+33580+33590+34004+34005+34003+34010+34011+34012+34020+34030+34040+",
        "34050+34060+34070+34080+34510+34530+34540+34550+34560+34570+34580+35004+35005+",
        "35003+35010+35011+35012+35020+35030+35040+35050+35060+35510+35520+35530+35540+",
        "35550+35560+35570+35580+36004+36005+36003+36010+36020+36030+36040+36060+36510+",
        "36520+36530+36550+36560+36570+36580+36590+36600+36610+36620+36630+36640+36650+",
        "36660+36670+36680+37004+37005+37003+37010+37011+37012+37020+37030+37040+37050+",
        "37060+37070+37080+37090+37100+37510+37520+37530+37540+37550+37560+37570+37580+",
        "37590+37600+37610+37620+37630+38004+38005+38003+38030+38050+38060+38070+38080+",
        "38090+38100+38110+38111+38112+38113+38114+38115+38510+38520+38530+38540+38550+",
        "38560+38570+38580+38590+38600+39004+39005+39003+39010+39020+",
        "&objL2=ALL&objL3=ALL&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&startPrdDe=%d&",
        "endPrdDe=%d&outputFields=ORG_ID+TBL_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_ID+ITM_NM+",
        "ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+PRD_SE+PRD_DE+&orgId=101&tblId=DT_1IN1509"
      ),
      year, year
    )
  )
  # nolint end

  # Return the loaded dataset
  return(dataset)
}

