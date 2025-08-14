library(sf)
library(janitor)
library(V8)
library(stringi)
library(dplyr)
sf_use_s2(F)

sf_sgg_2020 <-
  read_sf("/mnt/s/Korea/basemap/data/census/bnd_all_00_2020_4Q/bnd_sigungu_00_2020_4Q/bnd_sigungu_00_2020_4Q.shp") %>%
  st_transform(5179) %>%
  st_make_valid()

save(sf_sgg_2020, file = "inst/sgg2020.RData", compress = "xz")

# Transliterate Korean text to Latin script
# without considering pronunciation rules
stringi::stri_trans_general("학여울", "Hangul-Latin")
stringi::stri_trans_general("항녀울", "Hang-Latn")
stringi::stri_trans_general("종로구", "Hang-Latn")
grep("Hang", stringi::stri_trans_list(), value = TRUE)


# 2020
url_tax_general <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=인증키없음&itmId=T001+&objL1=A0201+A0202+A0203+A0204+A0205+A0206+A0207+A0208+A0209+A0210+A0211+A0212+A0213+A0214+A0215+A0216+A0217+A0218+A0219+A0220+A0221+A0222+A0223+A0224+A0225+A0301+A0302+A0303+A0304+A0305+A0306+A0307+A0308+A0309+A0310+A0401+A0402+A0403+A0404+A0405+A0406+A0407+A0408+A0409+A0410+A0411+A0412+A0413+A0414+A0415+A0416+A0417+A0418+A0419+A0420+A0421+A0422+A0423+A0424+A0425+A0426+A0427+A0428+A0429+A0430+A0431+A0501+A0502+A0503+A0504+A0505+A0506+A0507+A0508+A0509+A0510+A0511+A0512+A0513+A0514+A0515+A0516+A0517+A0518+A0601+A0602+A0603+A0604+A0605+A0701+A0702+A0703+A0704+A0705+A0706+A0707+A0708+A0709+A0710+A0711+A0801+A0802+A0803+A0804+A0805+A0806+A0807+A0808+A0809+A0810+A0811+A0812+A0813+A0814+A0815+A09+A1001+A1002+A1003+A1004+A1005+A1101+A1102+A1103+A1104+A1105+A1106+A1107+A1108+A1109+A1110+A1111+A1112+A1113+A1114+A1201+A1202+A1203+A1204+A1205+A1206+A1207+A1208+A1209+A1210+A1211+A1212+A1213+A1214+A1215+A1216+A1217+A1218+A1219+A1220+A1221+A1222+A1309+A1301+A1302+A1303+A1304+A1305+A1306+A1307+A1308+A1401+A1402+A1403+A1404+A1405+A1406+A1407+A1408+A1409+A1410+A1411+A1412+A1413+A1414+A1415+A1416+A1417+A1418+A1419+A1420+A1421+A1422+A1423+A1501+A1502+A1503+A1504+A1505+A1506+A1507+A1508+A1509+A1510+A1511+A1512+A1513+A1514+A1515+A1516+A1601+A1602+A1603+A1604+A1605+A1701+A1702+A1703+A1704+A1705+A1706+A1707+A1708+A1709+A1710+A1711+A1712+A1713+A1714+A1715+A1716+A1717+A1718+A1802+A1801+&objL2=15133SGH0M+&objL3=&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&newEstPrdCnt=1&outputFields=TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_ID+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+&orgId=133&tblId=DT_133N_A3212"

url_tax_income <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=&itmId=T001+T002+&objL1=A0101+A0102+A0103+A0104+A0105+A0106+A0107+A0108+A0109+A0110+A0111+A0112+A0113+A0114+A0115+A0116+A0117+A0118+A0119+A0120+A0121+A0122+A0123+A0124+A0125+A0201+A0202+A0204+A0205+A0203+A0206+A0207+A0208+A0209+A0210+A0301+A0302+A0303+A0304+A0305+A0306+A0307+A0308+A0309+A0310+A0311+A0312+A0313+A0314+A0315+A0316+A0317+A0318+A0319+A0320+A0321+A0322+A0323+A0324+A0325+A0326+A0327+A0328+A0329+A0330+A0331+A0401+A0402+A0403+A0404+A0405+A0406+A0407+A0408+A0409+A0410+A0411+A0412+A0413+A0414+A0415+A0416+A0417+A0418+A0501+A0502+A0503+A0504+A0505+A0601+A0602+A0603+A0604+A0605+A0606+A0607+A0608+A0609+A0610+A0611+A0701+A0702+A0703+A0704+A0705+A0706+A0707+A0708+A0709+A0710+A0711+A0712+A0713+A0714+A0715+A08+A0901+A0902+A0903+A0904+A0905+A1001+A1002+A1003+A1004+A1005+A1006+A1007+A1008+A1009+A1010+A1011+A1012+A1013+A1014+A1101+A1102+A1103+A1104+A1105+A1106+A1107+A1108+A1109+A1110+A1111+A1112+A1113+A1114+A1115+A1116+A1117+A1118+A1119+A1120+A1121+A1122+A1201+A1202+A1203+A1204+A1205+A1206+A1207+A1208+A1301+A1302+A1303+A1304+A1305+A1306+A1307+A1308+A1309+A1310+A1311+A1312+A1313+A1314+A1315+A1316+A1317+A1318+A1319+A1320+A1321+A1322+A1323+A1401+A1402+A1403+A1404+A1405+A1406+A1407+A1408+A1409+A1410+A1411+A1412+A1413+A1414+A1415+A1416+A1501+A1502+A1503+A1504+A1505+A1601+A1602+A1603+A1604+A1605+A1606+A1607+A1608+A1609+A1610+A1611+A1612+A1613+A1614+A1615+A1616+A1617+A1618+A1701+A1702+&objL2=ALL&objL3=&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&newEstPrdCnt=1&outputFields=TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+&orgId=133&tblId=DT_133001N_4214"

url_mortality <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=&itmId=T7+&objL1=0+&objL2=11010+11020+11030+11040+11050+11060+11070+11080+11090+11100+11110+11120+11130+11140+11150+11160+11170+11180+11190+11200+11210+11220+11230+11240+11250+21010+21020+21030+21040+21050+21060+21070+21080+21090+21100+21110+21120+21130+21140+21150+21310+21510+22010+22020+22030+22040+22050+22060+22070+22310+22510+22520+23010+23020+23030+23040+23050+23060+23070+23080+23090+23310+23320+23510+23520+24010+24020+24030+24040+24050+25010+25020+25030+25040+25050+26010+26020+26030+26040+26310+26510+29010+31010+31011+31012+31013+31014+31020+31021+31022+31023+31030+31040+31041+31042+31050+31051+31052+31053+31060+31070+31080+31090+31091+31092+31100+31101+31102+31103+31104+31110+31120+31130+31140+31150+31160+31170+31180+31190+31191+31192+31193+31200+31210+31220+31230+31240+31250+31260+31270+31280+31310+31320+31330+31340+31350+31360+31370+31380+31550+31570+31580+32010+32020+32030+32040+32050+32060+32070+32310+32320+32330+32340+32350+32360+32370+32380+32390+32400+32410+32510+32520+32530+32540+32550+32560+32570+32580+32590+32600+32610+33010+33011+33012+33020+33030+33040+33041+33042+33043+33044+33310+33320+33330+33340+33350+33360+33370+33380+33390+33520+33530+33540+33550+33560+33570+33580+33590+34010+34011+34012+34020+34030+34040+34050+34060+34070+34080+34310+34320+34330+34340+34350+34360+34370+34380+34390+34400+34510+34530+34540+34550+34560+34570+34580+35010+35011+35012+35020+35030+35040+35050+35060+35310+35320+35330+35340+35350+35360+35370+35380+35510+35520+35530+35540+35550+35560+35570+35580+36010+36020+36030+36040+36060+36310+36320+36330+36350+36360+36370+36380+36390+36400+36410+36420+36430+36440+36450+36460+36470+36480+36510+36520+36530+36550+36560+36570+36580+36590+36600+36610+36620+36630+36640+36650+36660+36670+36680+37010+37011+37012+37020+37030+37040+37050+37060+37070+37080+37090+37100+37310+37320+37330+37340+37350+37360+37370+37380+37390+37400+37410+37420+37430+37520+37530+37540+37550+37560+37570+37580+37590+37600+37610+37620+37630+38010+38020+38021+38022+38030+38040+38050+38060+38110+38111+38112+38113+38114+38115+38070+38080+38090+38100+38310+38320+38330+38340+38350+38360+38370+38380+38390+38400+38510+38520+38530+38540+38550+38560+38570+38580+38590+38600+39010+39020+39310+39320+&objL3=ALL&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&newEstPrdCnt=1&outputFields=TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+&orgId=101&tblId=DT_1B34E13"

url_pop <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=인증키없음&itmId=T00+T60+&objL1=11010+11020+11030+11040+11050+11060+11070+11080+11090+11100+11110+11120+11130+11140+11150+11160+11170+11180+11190+11200+11210+11220+11230+11240+11250+21010+21020+21030+21040+21050+21060+21070+21080+21090+21100+21110+21120+21130+21140+21150+21510+22010+22020+22030+22040+22050+22060+22070+22510+22520+23010+23020+23030+23040+23050+23060+23070+23080+23090+23510+23520+24010+24020+24030+24040+24050+25010+25020+25030+25040+25050+26010+26020+26030+26040+26510+29010+31010+31011+31012+31013+31014+31020+31021+31022+31023+31030+31040+31041+31042+31050+31051+31052+31053+31060+31070+31080+31090+31091+31092+31100+31101+31103+31104+31110+31120+31130+31140+31150+31160+31170+31180+31190+31191+31192+31193+31200+31210+31220+31230+31240+31250+31260+31270+31280+31550+31570+31580+32010+32020+32030+32040+32050+32060+32070+32510+32520+32530+32540+32550+32560+32570+32580+32590+32600+32610+33020+33030+33040+33041+33042+33043+33044+33520+33530+33540+33550+33560+33570+33580+33590+34010+34011+34012+34020+34030+34040+34050+34060+34070+34080+34510+34530+34540+34550+34560+34570+34580+35010+35011+35012+35020+35030+35040+35050+35060+35510+35520+35530+35540+35550+35560+35570+35580+36010+36020+36030+36040+36060+36510+36520+36530+36550+36560+36570+36580+36590+36600+36610+36620+36630+36640+36650+36660+36670+36680+37010+37011+37012+37020+37030+37040+37050+37060+37070+37080+37090+37100+37510+37520+37530+37540+37550+37560+37570+37580+37590+37600+37610+37620+37630+38030+38050+38060+38070+38080+38090+38100+38110+38111+38112+38113+38114+38115+38510+38520+38530+38540+38550+38560+38570+38580+38590+38600+39010+39020+&objL2=ALL&objL3=000+&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&newEstPrdCnt=1&outputFields=TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_ID+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+&orgId=101&tblId=DT_1IN1509"
url_pop1520 <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=인증키없음&itmId=T00+T60+&objL1=11010+11020+11030+11040+11050+11060+11070+11080+11090+11100+11110+11120+11130+11140+11150+11160+11170+11180+11190+11200+11210+11220+11230+11240+11250+21004+21005+21003+21010+21020+21030+21040+21050+21060+21070+21080+21090+21100+21110+21120+21130+21140+21150+21510+22004+22005+22003+22010+22020+22030+22040+22050+22060+22070+22510+22520+23004+23005+23003+23010+23020+23030+23040+23050+23060+23070+23080+23090+23510+23520+24010+24020+24030+24040+24050+25010+25020+25030+25040+25050+26004+26005+26003+26010+26020+26030+26040+26510+29004+29005+29003+29010+31004+31005+31003+31010+31011+31012+31013+31014+31020+31021+31022+31023+31030+31040+31041+31042+31050+31051+31052+31053+31060+31070+31080+31090+31091+31092+31100+31101+31103+31104+31110+31120+31130+31140+31150+31160+31170+31180+31190+31191+31192+31193+31200+31210+31220+31230+31240+31250+31260+31270+31280+31550+31570+31580+32004+32005+32003+32010+32020+32030+32040+32050+32060+32070+32510+32520+32530+32540+32550+32560+32570+32580+32590+32600+32610+33004+33005+33003+33020+33030+33040+33041+33042+33043+33044+33520+33530+33540+33550+33560+33570+33580+33590+34004+34005+34003+34010+34011+34012+34020+34030+34040+34050+34060+34070+34080+34510+34530+34540+34550+34560+34570+34580+35004+35005+35003+35010+35011+35012+35020+35030+35040+35050+35060+35510+35520+35530+35540+35550+35560+35570+35580+36004+36005+36003+36010+36020+36030+36040+36060+36510+36520+36530+36550+36560+36570+36580+36590+36600+36610+36620+36630+36640+36650+36660+36670+36680+37004+37005+37003+37010+37011+37012+37020+37030+37040+37050+37060+37070+37080+37090+37100+37510+37520+37530+37540+37550+37560+37570+37580+37590+37600+37610+37620+37630+38004+38005+38003+38030+38050+38060+38070+38080+38090+38100+38110+38111+38112+38113+38114+38115+38510+38520+38530+38540+38550+38560+38570+38580+38590+38600+39004+39005+39003+39010+39020+&objL2=ALL&objL3=000+&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&newEstPrdCnt=3&outputFields=TBL_ID+TBL_NM+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_ID+ITM_NM+ITM_NM_ENG+UNIT_NM+UNIT_NM_ENG+PRD_SE+PRD_DE+LST_CHN_DE&orgId=101&tblId=DT_1IN1509"

kosiskey <- readLines("~/.kosiskey")[1]

library(tidycensuskr)
tidycensuskr::set_kosis_key("~/.kosiskey")

df_tax <- kosis::getStatDataFromURL(
  url_tax_general
)
df_tax_income <- kosis::getStatDataFromURL(
  url_tax_income
)
df_mortality <- kosis::getStatDataFromURL(
  url_mortality
)
df_pop <- kosis::getStatDataFromURL(
  url_pop
)
df_pop1520 <- kosis::getStatDataFromURL(
  url_pop1520
)
sggnm <- read.csv("./tools/sigungu_names_sgis.csv", fileEncoding = "CP949")

# clean and tidy
sidocd_range <-
  tibble::tribble(
    ~sido_kr, ~sido_cd, ~sido_txcd,
    "서울특별시", "11", "02",
    "부산광역시", "21", "15",
    "대구광역시", "22", "13",
    "인천광역시", "23", "03",
    "광주광역시", "24", "10",
    "대전광역시", "25", "06",
    "울산광역시", "26", "16",
    "세종특별자치시", "29", "09",
    "경기도", "31", "04",
    "강원특별자치도", "32", "05",
    "충청북도", "33", "07",
    "충청남도", "34", "08",
    "전라북도", "35", "11",
    "전라남도", "36", "12",
    "경상북도", "37", "14",
    "경상남도", "38", "17",
    "제주특별자치도", "39", "18"
  )


sggnm_si <- sggnm %>%
  dplyr::filter(is.na(tax_exclude)) %>%
  dplyr::select(1, 3, 5, 6) %>%
  dplyr::distinct() %>%
  dplyr::left_join(sidocd_range, by = c("sido_kr")) %>%
  dplyr::group_by(sido_txcd) %>%
  dplyr::arrange(sigungu_1_kr, .by_group = TRUE) %>%
  dplyr::ungroup() %>%
  .[c(1:157, 159:166, 158, 167:227, 229, 228), ]



### Subset

sgg_lookup_large <- read.csv("tools/adm_sgis_lookup_2024.csv", fileEncoding = "UTF-8-BOM")

lookup_adm2 <-
  function(x, year = 2020) {
    x %>%
      dplyr::rename(
        adm1 = name_sido,
        adm2 = name_eng
      ) %>%
      dplyr::filter(grepl("District", level)) %>%
      dplyr::select(adm1, adm2, sgis_2010, sgis_2015, sgis_2020) %>%
      dplyr::mutate(
        dplyr::across(
          dplyr::starts_with("sgis_"),
          ~ as.integer(substr(., 1, 5))
        )
      ) %>%
      tidyr::pivot_longer(
        cols = dplyr::starts_with("sgis_")
      ) %>%
      dplyr::mutate(
        year = as.integer(stringi::stri_extract_first_regex(name, pattern = "\\d{4,4}"))
      ) %>%
      dplyr::select(-name) %>%
      dplyr::filter(year == !!year) %>%
      dplyr::filter(!is.na(value)) %>%
      dplyr::rename(adm2_code = value)
  }
## Base lookup table by year
df_lookup_adm2 <-
  dplyr::bind_rows(
    lookup_adm2(sgg_lookup_large, year = 2010),
    lookup_adm2(sgg_lookup_large, year = 2015),
    lookup_adm2(sgg_lookup_large, year = 2020)
  )

sgg_lookup_ally <-
  sgg_lookup_large %>%
  dplyr::select(sgis_2010, sgis_2015, sgis_2020) %>%
  dplyr::mutate(
    dplyr::across(
      dplyr::everything(),
      ~ as.integer(substr(., 1, 5))
    )
  ) %>%
  dplyr::distinct() %>%
  dplyr::mutate(
    dplyr::across(
      dplyr::everything(),
      ~ data.table::nafill(., type = "locf")
    )
  ) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(
    sgg_lookup %>%
    dplyr::mutate(
      adm2_code = ifelse(substr(adm2_code, 3, 3) %in% c("5", "6"),
                        adm2_code - 200,
                        adm2_code)
    ) %>%
    .[, c("adm2_code", "sido_en", "sigungu_1_en")],
    by = c("sgis_2020" = "adm2_code"),
    multiple = "first"
  )
sgg_lookup_ally

## sgg_lookup
sgg_lookup <- read.csv("inst/extdata/lookup_district_code.csv", fileEncoding = "UTF-8")

# general income tax
df_tax_compact <- df_tax %>%
  dplyr::transmute(
    sgg_tax_global = C1,
    tax_global_total = DT
  ) %>%
  dplyr::inner_join(
    sgg_lookup[, c("sgg_tax_global", "sido_en", "sigungu_1_en", "adm2_code")],
    multiple = "first"
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en,
    adm2_code = adm2_code,
    value = tax_global_total
  ) %>%
  dplyr::mutate(
    year = 2020,
    unit = "million KRW",
    type = "tax",
    class1 = "income",
    class2 = "general"
  ) %>%
  dplyr::select(-sgg_tax_global)

# labor income tax
df_tax_income_compact <- df_tax_income %>%
  dplyr::filter(
    C2_NM == "결정세액"
  ) %>%
  dplyr::transmute(
    sgg_tax_income = C1,
    val = DT,
    unit_abbr = abbreviate(tolower(UNIT_NM_ENG))
  ) %>%
  tidyr::pivot_wider(
    names_from = unit_abbr,
    values_from = val,
    values_fn = as.integer
  ) %>%
  dplyr::rename(
    tax_income_total = inmw
  ) %>%
  dplyr::select(-inpr) %>%
  # dplyr::group_by(sgg_tax_income) %>%
  # dplyr::summarise(
  #   tax_income_percapita_milkrw = inmw / inpr
  # ) %>%
  # dplyr::ungroup() %>%
  dplyr::inner_join(
    sgg_lookup[, c("sgg_tax_income", "sido_en", "sigungu_1_en", "adm2_code")],
    multiple = "first"
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en,
    adm2_code = adm2_code,
    value = tax_income_total
  ) %>%
  dplyr::mutate(
    year = 2020,
    unit = "million KRW",
    type = "tax",
    class1 = "income",
    class2 = "labor"
  ) %>%
  dplyr::select(-sgg_tax_income)

df_pop_10 <-
  readxl::read_excel("tools/pop_2010.xlsx")
names(df_pop_10) <- c("year", "adm2_code", "sex", "marital", "age", "n_rel", "n_nonrel")
df_pop_10 <- df_pop_10 %>%
  dplyr::select(-marital)

df_pop_1520 <-
  readxl::read_excel("tools/pop_1520.xlsx")
names(df_pop_1520) <- c("year", "adm2_code", "sex", "age", "n_rel", "n_nonrel")

# combine 2010 and 2015-2020 and clean
df_pop_1020_clean <-
  dplyr::bind_rows(df_pop_10, df_pop_1520) %>%
  dplyr::mutate(
    year = as.integer(
      stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}")
    ),
    adm2_code = as.integer(
      stringi::stri_extract_first_regex(adm2_code, pattern = "\\d{5,5}")
    ),
    sex = plyr::mapvalues(
      stringi::stri_extract_first_regex(sex, pattern = "\\d{1,1}"),
      c("0", "1", "2"),
      c("total", "male", "female")
    ),
    value = ifelse(is.na(n_rel), 0, n_rel) + ifelse(is.na(n_nonrel), 0, n_nonrel)
  ) %>%
  dplyr::select(
    -n_rel, -n_nonrel, -age
  ) %>%
  dplyr::mutate(
    type = "population",
    class1 = "all households",
    unit = "persons"
  ) %>%
  dplyr::mutate(
    adm2_code = ifelse(substr(adm2_code, 3, 3) %in% c("5", "6"),
                       as.integer(adm2_code) - 200,
                       as.integer(adm2_code))
  ) %>%
  dplyr::left_join(
    df_lookup_adm2,
    # sgg_lookup[, c("adm2_code", "sido_en", "sigungu_1_en")],
    by = c("adm2_code", "year"),
    multiple = "first"
  ) %>%
  dplyr::rename(
    class2 = sex
  ) %>%
  dplyr::filter(substr(adm2_code, 4, 4) != "0") %>%
  dplyr::filter(!is.na(adm1))
write.csv(df_pop_1020_clean, "tools/population_1020_cleaned.csv", row.names = FALSE, fileEncoding = "UTF-8")


# Mortality 2020
df_mort_2020 <- df_mortality %>%
  dplyr::transmute(
    adm2_code = as.integer(C2), 
    class2 = plyr::mapvalues(C3, c("0", "1", "2"), c("total", "male", "female")),
    class1 = "All causes",
    type = "mortality",
    year = 2020,
    unit = "per 100k population",
    value = DT) %>%
  dplyr::left_join(
    sgg_lookup[, c("adm2_code", "sido_en", "sigungu_1_en")],
    by = "adm2_code",
    multiple = "first"
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en
  ) %>%
  dplyr::mutate(value = as.numeric(value)) %>%
  dplyr::filter(!is.na(adm1))



write.csv(df_tax_compact, "tools/tax_global_2020.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(df_tax_income_compact, "tools/tax_income_2020.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(df_mort_2020, "tools/mortality_cleaned_2020.csv", row.names = FALSE, fileEncoding = "UTF-8")
# write.csv(df_pop2, "tools/population_cleaned_2020.csv", row.names = FALSE, fileEncoding = "UTF-8")



## Using the preprocessed data ####
df_tax_compact <- read.csv("tools/tax_global_2020.csv", fileEncoding = "UTF-8")
df_tax_income_compact <- read.csv("tools/tax_income_2020.csv", fileEncoding = "UTF-8")
df_mort_2020 <- read.csv("tools/mortality_cleaned_2020.csv", fileEncoding = "UTF-8")
# df_pop2 <- read.csv("tools/population_cleaned_2020.csv", fileEncoding = "UTF-8")
df_pop_1520_clean <- read.csv("tools/population_1520_cleaned.csv", fileEncoding = "UTF-8")

# consolidate all data into one long data.frame


# df_pop_long <- df_pop2 %>%
#   dplyr::select(-2) %>%
#   tidyr::pivot_longer(
#     cols = 2:7
#   ) %>%
#   tidyr::separate(col = "name", into = c("type", "class1", "class2"), sep = "_") %>%
#   dplyr::mutate(unit = "persons")

# old df_mort_long
# df_mort_long <- df_mort_clean %>%
#   tidyr::pivot_longer(
#     cols = 3:5
#   ) %>%
#   dplyr::mutate(
#     class2 = dplyr::case_when(
#       name == "0" ~ "total",
#       name == "1" ~ "male",
#       name == "2" ~ "female",
#       TRUE  ~ NA_character_
#     ),
#     unit = "per 100k population",
#     type = "mortality"
#   ) %>%
#   dplyr::rename(class1 = category) %>%
#   dplyr::select(-name) %>%
#   dplyr::filter(value != "-") %>%
#   dplyr::mutate(value = as.numeric(value))


## 2010-2015 mortality data ####
mort_a <- readxl::read_excel(
  file.path("tools", "mortality_2010_2015_total.xlsx"),
  skip = 1
)
names(mort_a) <- c("year", "cause", "adm2_code", "total", "male", "female")
mort_a[["year"]] <- rep(c(2010, 2015), each = nrow(mort_a) / 2)
mort_aa <-
  mort_a %>%
  dplyr::mutate(
    type = "mortality",
    unit = "per 100k population",
    class1 = "All causes"
  ) %>%
  tidyr::pivot_longer(
    cols = c("total", "male", "female"),
    names_to = "class2",
    values_to = "value"
  ) %>%
  dplyr::mutate(
    adm2_code = stringi::stri_extract_all_regex(adm2_code, pattern = "[0-9]{5,5}") %>%
      unlist() %>%
      as.integer()
  ) %>%
  dplyr::select(-cause)

# mort_aa[is.na(mort_aa[["sido_en"]]), ]
# mort_aa[mort_aa[["sigungu_1_en"]] == "Yeoju-si", ]
# mort_aa[mort_aa[["adm2_code"]] == 22310, ]
df_lookup_adm2 <- lookup_adm2(sgg_lookup_large)

df_mort_1015 <-
  mort_aa %>%
  dplyr::left_join(
    df_lookup_adm2,
    by = c("adm2_code", "year"),
    multiple = "first"
  ) %>%
  dplyr::mutate(
    value = as.numeric(value)
  ) %>%
  dplyr::filter(!is.na(adm1))

# economy
df_econ_1020 <- read.csv("tools/economy_2010_2020.csv", fileEncoding = "UTF-8")



# Bind all long tables
censuskor <-
  collapse::rowbind(
    list(
      df_tax_compact,
      df_tax_income_compact,
      df_pop_1020_clean,
      df_mort_2020,
      df_mort_1015,
      df_econ_1020
    ),
    fill = TRUE
  ) %>%
  dplyr::select(
    year, adm1, adm2, adm2_code,#adm2_other,
    type, class1, class2, unit, value
  ) %>%
  dplyr::mutate(
    adm2_code = ifelse(substr(adm2_code, 3, 3) %in% c("5", "6"),
                       as.integer(adm2_code) - 200,
                       as.integer(adm2_code))
  )


usethis::use_data(censuskor, overwrite = TRUE)



### Dev code ####
df_tax_k <- cbind(df_tax, sggnm_si)
df_tax_k[, c("C1_NM", "sigungu_1_kr")]

df_tax_income2 <- df_tax_income %>%
  dplyr::filter(C2_NM == "결정세액") %>%
  dplyr::mutate(
    name = "general_tax"
  ) %>%
  dplyr::mutate(
    UNIT_NM_ENG = tolower(sub(" ", "", sub(" ", "", UNIT_NM_ENG)))
  ) %>%
  dplyr::select(C1_NM, C1, name, UNIT_NM_ENG, DT) %>%
  tidyr::pivot_wider(
    names_from = c(name, UNIT_NM_ENG),
    values_from = DT
  )



dim(df_tax)
lookup_sgg_tax <- df_tax[, c("C1", "C1_NM")]
lookup_sgg_tax_income <- df_tax_income[, c("C1", "C1_NM")] %>% dplyr::distinct()
names(lookup_sgg_tax_income) <- c("C1_income", "C1_NM_income")
lookup_sgg_tax_bind <- dplyr::bind_cols(lookup_sgg_tax, lookup_sgg_tax_income)

write.csv(lookup_sgg_tax_bind, "tools/lookup_sgg_tax.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(df_pop2, "tools/population_2020.csv", row.names = FALSE, fileEncoding = "UTF-8")



save(df_tax, df_tax_income, df_mortality, df_pop,
     file = "inst/kosis_tax_mortality_population.RData", compress = "xz")


## 2015, 2010
# 2015
url_tax_general_2015 <-


url_pop_2010 <-
  "https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=인증키없음&itmId=T00+T10+T20+&objL1=11010+11020+11030+11040+11050+11060+11070+11080+11090+11100+11110+11120+11130+11140+11150+11160+11170+11180+11190+11200+11210+11220+11230+11240+11250+21003+21004+21005+21010+21020+21030+21040+21050+21060+21070+21080+21090+21100+21110+21120+21130+21140+21150+21310+22003+22004+22005+22010+22020+22030+22040+22050+22060+22070+22310+23003+23004+23005+23010+23020+23030+23040+23050+23060+23070+23080+23310+23320+24010+24020+24030+24040+24050+25010+25020+25030+25040+25050+26003+26004+26005+26010+26020+26030+26040+26310+31003+31004+31005+31010+31011+31012+31013+31014+31020+31021+31022+31023+31030+31040+31041+31042+31050+31051+31052+31053+31060+31070+31080+31090+31091+31092+31100+31101+31103+31104+31110+31120+31130+31140+31150+31160+31170+31180+31190+31191+31192+31193+31200+31210+31220+31230+31240+31250+31260+31270+31320+31350+31370+31380+32003+32004+32005+32010+32020+32030+32040+32050+32060+32070+32310+32320+32330+32340+32350+32360+32370+32380+32390+32400+32410+33003+33004+33005+33010+33011+33012+33020+33030+33310+33320+33330+33340+33350+33360+33370+33380+33390+34003+34004+34005+34010+34011+34012+34020+34030+34040+34050+34060+34070+34310+34320+34330+34340+34350+34360+34370+34380+34390+35003+35004+35005+35010+35011+35012+35020+35030+35040+35050+35060+35310+35320+35330+35340+35350+35360+35370+35380+36003+36004+36005+36010+36020+36030+36040+36060+36310+36320+36330+36350+36360+36370+36380+36390+36400+36410+36420+36430+36440+36450+36460+36470+36480+37003+37004+37005+37010+37011+37012+37020+37030+37040+37050+37060+37070+37080+37090+37100+37310+37320+37330+37340+37350+37360+37370+37380+37390+37400+37410+37420+37430+38003+38004+38005+38030+38050+38060+38070+38080+38090+38100+38110+38111+38112+38113+38114+38115+38310+38320+38330+38340+38350+38360+38370+38380+38390+38400+39003+39004+39005+39010+39020+&objL2=000+&objL3=&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=F&newEstPrdCnt=3&outputFields=OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM_ENG+ITM_ID+ITM_NM_ENG+UNIT_NM_ENG+&orgId=101&tblId=DT_1IN1003"



library(sf)
sf_use_s2(FALSE)

sf_sgg_2020 <-
  sf::st_read("/mnt/s/Korea/basemap/tidycensuskr_sgg2020.fgb") |>
  sf::st_transform(4326)
