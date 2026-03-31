# 요구사항 문서

## 소개

Venture 앱의 프로필 태그 시스템을 개편합니다. 기존의 `interests`, `ageRange`, `gender` 3종 태그 구조를 **지역(location)**, **시간(time)**, **성별(gender)**, **연령(ageRange)**, **관심사(interest)** 5종 카테고리로 확장합니다. 지역과 시간은 필수 태그로 목업 기본값을 제공하며, 나머지는 선택적입니다. 프로필 카드는 현재 2페이지 구조에서 1페이지로 통합되고, 카테고리별 색상 구분 및 태그 추가/삭제 UI가 개선됩니다.

---

## 용어 정의

- **Tag_System**: 사용자 프로필에 부착되는 카테고리별 태그 집합을 관리하는 시스템
- **ProfileCard**: 홈 화면에서 사용자 프로필 정보를 표시하는 카드 위젯
- **LocationTag**: 시/도 → 시/군/구 2단계 드릴다운으로 선택하는 지역 태그
- **TimeTag**: 요일 × 시간 그리드에서 선택하는 가능 시간대 태그
- **GenderTag**: 성별을 나타내는 선택적 태그
- **AgeRangeTag**: 연령대를 나타내는 선택적 태그
- **InterestTag**: 관심사를 나타내는 선택적 태그 (복수 추가 가능)
- **TagType**: `location`, `time`, `gender`, `ageRange`, `interest` 5가지 카테고리 열거형
- **LocationModel**: 시/도(`province`)와 시/군/구(`district`) 두 필드를 가진 구조체
- **TimeSlot**: 요일(`weekday`: 0=월~6=일)과 시간 인덱스(`hourIndex`: 0~23)로 구성된 구조체. 저장 포맷: `"MON-09"` (요일 3자리 대문자-시작 시각 2자리)
- **LocationPicker**: 시/도 → 시/군/구 2단계 드릴다운 UI 컴포넌트
- **TimePicker**: 요일 × 시간 그리드 UI 컴포넌트 (when2meet 스타일)
- **MockApiService**: 실제 HTTP 없이 비동기 API 패턴을 모방하는 목업 서비스
- **HomeViewModel**: 홈 화면의 상태와 비즈니스 로직을 관리하는 ViewModel

---

## 요구사항

### 요구사항 1: 태그 데이터 모델 확장

**User Story:** 개발자로서, 5종 카테고리 태그를 모두 표현할 수 있는 타입 안전한 데이터 모델이 필요합니다. 그래야 서버 필터링 시 문자열 파싱 없이 구조화된 데이터를 활용할 수 있습니다.

#### 인수 기준

1. THE `Tag_System` SHALL `TagType`을 `location`, `time`, `gender`, `ageRange`, `interest` 5가지 값을 가진 열거형으로 정의한다.
2. THE `Tag_System` SHALL `LocationModel`을 `province(String)`와 `district(String)` 두 필드를 가진 불변 클래스로 정의한다. `district`가 빈 문자열이면 시/도 전체를 의미한다.
3. THE `Tag_System` SHALL `TimeSlot`을 `weekday(int, 0=월~6=일)`와 `hourIndex(int, 0~23)` 두 필드를 가진 불변 클래스로 정의한다. 직렬화 포맷은 `"MON-09"` (요일 3자리 대문자-시작 시각 2자리 zero-padded)로 한다.
4. THE `UserProfile` SHALL `locations(List<LocationModel>)`, `availableTimes(List<TimeSlot>)`, `interests(List<String>)`, `ageRange(String?)`, `gender(String?)` 필드를 포함한다.
5. THE `UserProfile` SHALL `ageRange`와 `gender` 필드를 nullable(`String?`)로 정의하여 미설정 상태를 명시적으로 표현한다.
6. THE `UserProfile.copyWith` SHALL `locations`와 `availableTimes` 파라미터를 포함하도록 확장한다.
7. IF `patchMe`가 `locations` 또는 `availableTimes` 파라미터를 수신하면, THEN THE `MockApiService` SHALL 해당 필드를 업데이트하고 수정된 `UserProfile`을 반환한다.

---

### 요구사항 2: 필수 태그 목업 기본값

**User Story:** 사용자로서, 앱을 처음 열었을 때 지역과 시간 태그에 임시 기본값이 표시되기를 원합니다. 그래야 온보딩 전에도 프로필 카드가 비어 보이지 않습니다.

#### 인수 기준

1. THE `MockApiService` SHALL `locations` 필드에 최소 1개의 더미 `LocationModel` 인스턴스를 기본값으로 포함한다. (예: `LocationModel(province: "로렘시", district: "입숨구")`)
2. THE `MockApiService` SHALL `availableTimes` 필드에 최소 3개의 더미 `TimeSlot` 인스턴스를 기본값으로 포함한다.
3. THE `ProfileCard` SHALL 앱 초기 로드 시 `locations`와 `availableTimes` 기본값을 태그로 표시한다.
4. WHEN 사용자가 필수 태그를 삭제하면, THE `Tag_System` SHALL 해당 태그를 목록에서 제거한다. (최소 개수 강제는 온보딩 화면에서 처리하므로 현재 단계에서는 적용하지 않는다.)

---

### 요구사항 3: 지역 태그 관리

**User Story:** 사용자로서, 시/도와 시/군/구를 2단계로 선택하여 지역 태그를 추가하고 싶습니다. 그래야 정확한 활동 지역을 표시할 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 지역 태그 추가 버튼을 탭하면, THE `LocationPicker` SHALL 시/도 목록을 표시한다.
2. WHEN 사용자가 시/도를 선택하면, THE `LocationPicker` SHALL 해당 시/도에 속한 시/군/구 목록과 "[시/도 전체]" 옵션을 함께 표시한다.
3. WHEN 사용자가 시/군/구(또는 전체)를 선택하면, THE `Tag_System` SHALL 선택된 `LocationModel`을 `locations` 목록에 추가하고 `LocationPicker`를 닫는다.
4. WHEN 사용자가 시/도만 선택한 상태에서 뒤로가기 또는 취소를 탭하면, THE `LocationPicker` SHALL 시/도 선택을 초기화하고 불완전한 데이터를 `locations`에 추가하지 않는다.
5. WHEN 사용자가 `LocationPicker`를 시/도 선택 전에 닫으면, THE `Tag_System` SHALL 아무 변경도 적용하지 않는다.
6. WHILE `locations` 목록의 크기가 3 이상이면, THE `Tag_System` SHALL 지역 태그 추가 버튼을 비활성화한다.
7. THE `LocationPicker` SHALL 최소 서울특별시, 경기도, 부산광역시를 포함한 프리셋 지역 데이터를 제공한다.
8. IF 동일한 `LocationModel`(province와 district 모두 일치)이 이미 `locations`에 존재하면, THEN THE `Tag_System` SHALL 중복 추가를 허용하지 않는다.

---

### 요구사항 4: 시간 태그 관리

**User Story:** 사용자로서, 요일과 시간대를 그리드에서 드래그하거나 탭하여 가능한 시간을 선택하고 싶습니다. 그래야 다른 사용자들이 나의 활동 가능 시간을 알 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 시간 태그 편집 버튼을 탭하면, THE `TimePicker` SHALL 7개 요일(월~일) × 24개 시간 슬롯으로 구성된 그리드를 표시한다.
2. WHEN 사용자가 그리드 셀을 탭하면, THE `TimePicker` SHALL 해당 셀의 선택 상태를 토글한다.
3. WHEN 사용자가 그리드 셀에서 드래그를 시작하면, THE `TimePicker` SHALL 드래그 시작 셀의 초기 상태를 기준으로 드래그 모드(선택 또는 해제)를 결정한다. 드래그 경로의 모든 셀에 해당 모드를 일괄 적용한다. (when2meet 방식)
4. WHEN 사용자가 시간 선택을 확정하면, THE `Tag_System` SHALL 선택된 `TimeSlot` 목록으로 `availableTimes`를 교체하고 `TimePicker`를 닫는다.
5. WHEN 사용자가 `TimePicker`를 취소하면, THE `Tag_System` SHALL 기존 `availableTimes`를 유지하고 변경을 적용하지 않는다.
6. THE `TimePicker` SHALL 선택된 셀과 미선택 셀을 시각적으로 구분하여 표시한다.
7. THE `TimePicker` SHALL 진입 시 현재 `availableTimes`에 저장된 슬롯을 선택된 상태로 미리 표시한다.
8. THE `TimeSlot` SHALL `"MON-09"` 형식(요일 3자리 대문자 + `-` + 시작 시각 2자리 zero-padded)으로 직렬화된다. 유효한 요일 값은 `MON, TUE, WED, THU, FRI, SAT, SUN`이다.

---

### 요구사항 5: 선택적 태그 관리 (성별, 연령, 관심사)

**User Story:** 사용자로서, 성별, 연령대, 관심사 태그를 자유롭게 추가하고 삭제하고 싶습니다. 그래야 나의 프로필을 더 풍부하게 표현할 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 관심사 추가 버튼을 탭하면, THE `Tag_System` SHALL 텍스트 입력 필드를 포함한 다이얼로그를 표시한다.
2. WHEN 사용자가 관심사 태그를 추가하면, THE `Tag_System` SHALL 해당 값을 `interests` 목록에 추가한다.
3. WHEN 사용자가 성별 태그를 추가하면, THE `Tag_System` SHALL 기존 `gender` 값을 새 값으로 교체한다.
4. WHEN 사용자가 연령 태그를 추가하면, THE `Tag_System` SHALL 기존 `ageRange` 값을 새 값으로 교체한다.
5. WHEN 사용자가 임의의 태그의 X 버튼을 탭하면, THE `Tag_System` SHALL 해당 태그를 해당 카테고리 목록에서 제거한다.
6. IF 입력된 관심사 문자열이 비어 있거나 공백만으로 구성되면, THEN THE `Tag_System` SHALL 추가 동작을 수행하지 않고 오류 메시지("태그 값을 입력해주세요")를 표시한다.

---

### 요구사항 6: 카테고리별 태그 색상

**User Story:** 사용자로서, 태그의 카테고리를 색상으로 즉시 구분하고 싶습니다. 그래야 프로필 카드에서 정보를 빠르게 파악할 수 있습니다.

#### 인수 기준

1. THE `Tag_System` SHALL 각 `TagType`에 고유한 배경색을 할당한다. 초기 색상은 구현 시 결정하며 추후 변경 가능하도록 상수로 관리한다.
2. THE `ProfileCard` SHALL `location` 태그를 할당된 색상으로 렌더링한다.
3. THE `ProfileCard` SHALL `time` 태그를 할당된 색상으로 렌더링한다.
4. THE `ProfileCard` SHALL `gender`, `ageRange`, `interest` 태그를 각각의 할당된 색상으로 렌더링한다.
5. THE `Tag_System` SHALL 동일 카테고리 내 모든 태그에 동일한 색상을 적용한다.

---

### 요구사항 7: 프로필 카드 1페이지 통합 및 레이아웃

**User Story:** 사용자로서, 모든 태그를 한 화면에서 보고 싶습니다. 그래야 페이지를 넘기지 않고 프로필 전체를 한눈에 확인할 수 있습니다.

#### 인수 기준

1. THE `ProfileCard` SHALL 모든 카테고리의 태그를 단일 페이지에 `Wrap` 위젯으로 표시한다.
2. THE `ProfileCard` SHALL 기존 `PageView` 기반 2페이지 구조를 제거한다.
3. THE `ProfileCard` SHALL 태그 영역의 최대 높이를 3줄 분량(약 `108px`)으로 제한하고, 초과 시 세로 스크롤을 허용한다.
4. THE `ProfileCard` SHALL 각 카테고리 태그 그룹 마지막에 "+" 추가 버튼을 표시한다. 단, `location` 태그가 3개이면 해당 "+" 버튼을 숨긴다.
5. WHEN 태그 목록이 최대 높이를 초과하면, THE `ProfileCard` SHALL 태그 영역을 스크롤 가능하게 하고 스크롤 가능함을 시각적으로 표시한다.

---

### 요구사항 8: HomeViewModel 태그 연산 확장

**User Story:** 개발자로서, ViewModel이 5종 태그 카테고리를 모두 처리할 수 있어야 합니다. 그래야 UI와 데이터 레이어 간의 일관된 인터페이스를 유지할 수 있습니다.

#### 인수 기준

1. THE `HomeViewModel` SHALL `addLocation(LocationModel)` 메서드를 제공한다.
2. THE `HomeViewModel` SHALL `updateAvailableTimes(List<TimeSlot>)` 메서드를 제공한다. (시간은 전체 교체 방식)
3. THE `HomeViewModel` SHALL `removeTag` 메서드가 `location`과 `time` `TagType`을 처리하도록 확장한다.
4. WHEN `addLocation`이 호출되면, THE `HomeViewModel` SHALL `locations` 크기가 3 미만이고 중복이 없을 때만 `MockApiService.patchMe`를 통해 업데이트한다.
5. WHEN `updateAvailableTimes`가 호출되면, THE `HomeViewModel` SHALL `MockApiService.patchMe`를 통해 `availableTimes`를 교체하고 `notifyListeners`를 호출한다.
6. WHEN `removeTag(value, TagType.location)`이 호출되면, THE `HomeViewModel` SHALL `locations` 목록에서 해당 `LocationModel`을 제거하고 `notifyListeners`를 호출한다.
7. WHEN `removeTag(value, TagType.time)`이 호출되면, THE `HomeViewModel` SHALL `availableTimes` 목록에서 해당 `TimeSlot`을 제거하고 `notifyListeners`를 호출한다.
