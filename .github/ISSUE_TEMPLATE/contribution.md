---
name: Data contribution (자료 기여)
about: Create a data contribution issue
title: ''
labels: ''
assignees: ''
---

### Basic information (기본 정보)
- Which dataset are you contributing to? (어떤 데이터셋을 기여하시나요?): 
- What is the source of the data? (e.g., URL, publication, etc.) (데이터 출처는 무엇인가요? (예: URL, 출판물 등)):
- What is the time period covered by the data? (e.g., 2010-2020) (데이터가 조사된 기간은 언제인가요? (예: 2010-2020)):
- Is there anything else we should know about the data? (e.g., special considerations, limitations, etc.) (데이터에 대해 추가로 알려주실 사항이 있나요? (예: 특별한 고려사항, 제한사항 등)):

### Checklist (확인 사항)
- [ ] I have read the contribution guidelines (기여자 가이드라인을 읽었습니다).
- [ ] I have verified that the data is not already present in `censuskor` (기여한 데이터는 `censuskor.rda` 파일에 없었던 데이터임을 확인했습니다).
- [ ] I have ensured that the additional data complies with the `censuskor` standard layout and formatting (기여한 데이터가 `censuskor`의 표준 형식에 맞게 구성되었습니다).
  - [ ] The additional data include `adm1`, `adm1_code`, `adm2`, `adm2_code`, `type`, `class1`, `class2`, `unit` and `value` columns (기여한 데이터에는 제시된 10개 컬럼과 그 값이 빠짐 없이 입력되어 있습니다).
  - [ ] I have updated the first vignette of the dataset to include information about the new data (첫 번째 vignette에 기여한 데이터에 관한 정보를 입력하였습니다).
- [ ] I have updated the documentation of `censuskor` to reflect the addition of the new data (i.e., the number of rows) (`censuskor` 데이터셋 문서에 기여한 데이터에 관한 정보를 입력하였습니다).
- [ ] `anycensus()` includes the type of data being contributed as a input option (i.e., `type = "new_data_type"`) (`anycensus()` 함수에 기여한 데이터의 유형이 입력 옵션으로 추가되었습니다).