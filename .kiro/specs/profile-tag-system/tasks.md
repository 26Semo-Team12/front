# 구현 계획: profile-tag-system

## 개요

기존 3종 태그(interests, ageRange, gender)를 5종(location, time, gender, ageRange, interest)으로 확장합니다.
데이터 모델 → 색상 상수 → 서비스 → ViewModel → UI 위젯 순서로 점진적으로 구현합니다.

## 태스크

- [x] 1. 데이터 모델 확장 (`user_profile.dart`)
  - [x] 1.1 `LocationModel` 불변 클래스 구현
    - `province`, `district` 필드 정의
    - `toJson()` / `fromJson()` 직렬화 구현
    - `==` 연산자 및 `hashCode` 오버라이드 (중복 체크용)
    - `displayLabel` getter 구현 (`district`가 빈 문자열이면 `province`만 반환)
    - _요구사항: 1.2_

  - [x] 1.2 Property 2: `LocationModel` 직렬화 라운드트립 속성 테스트 작성
    - **Property 2: LocationModel 직렬화 라운드트립**
    - **Validates: Requirements 1.2**
    - `glados` 라이브러리로 임의의 province/district 문자열 쌍에 대해 `toJson()` → `fromJson()` 후 원래 값과 동일한지 검증

  - [x] 1.3 `TimeSlot` 불변 클래스 구현
    - `weekday(0~6)`, `hourIndex(0~23)` 필드 정의
    - `toSerializedString()` 구현 (예: `"MON-09"`)
    - `fromSerializedString()` 팩토리 생성자 구현
    - `displayLabel` getter 구현
    - `==` 연산자 및 `hashCode` 오버라이드
    - _요구사항: 1.3, 4.8_

  - [x] 1.4 Property 1: `TimeSlot` 직렬화 라운드트립 속성 테스트 작성
    - **Property 1: TimeSlot 직렬화 라운드트립**
    - **Validates: Requirements 1.3, 4.8**
    - `Glados2<int, int>`로 임의의 weekday % 7, hourIndex % 24에 대해 `toSerializedString()` → `fromSerializedString()` 후 원래 값과 동일한지 검증

  - [x] 1.5 `UserProfile` 모델 확장
    - `locations(List<LocationModel>)`, `availableTimes(List<TimeSlot>)` 필드 추가
    - `ageRange`, `gender` 타입을 `String?`(nullable)로 변경
    - `copyWith` 메서드에 `locations`, `availableTimes` 파라미터 추가
    - _요구사항: 1.4, 1.5, 1.6_

- [x] 2. 색상 상수 파일 생성 (`tag_colors.dart`)
  - [x] 2.1 `lib/core/models/tag_colors.dart` 파일 생성
    - `TagType`별 색상 상수 `kTagColors` 맵 정의
    - location: `Color(0xFF4A90D9)`, time: `Color(0xFF7B68EE)`, gender: `Color(0xFFE8A838)`, ageRange: `Color(0xFF50C878)`, interest: `Color(0xFFE05C5C)`
    - _요구사항: 6.1, 6.5_

  - [x] 2.2 Property 8: 태그 색상 완전성 속성 테스트 작성
    - **Property 8: 태그 색상 완전성**
    - **Validates: Requirements 6.1, 6.5**
    - 모든 `TagType` 값에 대해 `kTagColors[type]`이 null이 아닌지 검증

- [x] 3. `MockApiService` 확장
  - [x] 3.1 `patchMe` 메서드에 `locations`, `availableTimes` 파라미터 추가
    - 기존 파라미터 유지, `List<LocationModel>?`, `List<TimeSlot>?` 파라미터 추가
    - `_currentUser` 기본값에 `locations`, `availableTimes` 더미 데이터 추가
      - `locations`: `[LocationModel(province: '로렘시', district: '입숨구')]`
      - `availableTimes`: `[TimeSlot(weekday:0, hourIndex:9), TimeSlot(weekday:2, hourIndex:14), TimeSlot(weekday:4, hourIndex:19)]`
    - _요구사항: 1.7, 2.1, 2.2_

- [x] 4. `HomeViewModel` 확장
  - [x] 4.1 `TagType` 열거형에 `location`, `time` 추가
    - 기존 `interest`, `ageRange`, `gender`에 `location`, `time` 추가
    - _요구사항: 1.1_

  - [x] 4.2 `addLocation(LocationModel)` 메서드 구현
    - `locations.length >= 3`이면 조용히 무시
    - 동일한 `LocationModel`이 이미 존재하면 조용히 무시
    - 조건 통과 시 `patchMe`로 업데이트 후 `notifyListeners` 호출
    - _요구사항: 8.1, 8.4, 3.8_

  - [x] 4.3 Property 3: 지역 태그 중복 불허 속성 테스트 작성
    - **Property 3: 지역 태그 중복 불허**
    - **Validates: Requirements 3.8, 8.4**
    - 동일한 `LocationModel`을 두 번 `addLocation`하면 `locations.length`가 1인지 검증

  - [x] 4.4 Property 4: 지역 태그 최대 3개 제한 속성 테스트 작성
    - **Property 4: 지역 태그 최대 3개 제한**
    - **Validates: Requirements 3.6, 8.4**
    - 서로 다른 4개 이상의 `LocationModel`을 추가해도 `locations.length <= 3`인지 검증

  - [x] 4.5 `updateAvailableTimes(List<TimeSlot>)` 메서드 구현
    - 전달된 목록으로 `availableTimes` 전체 교체
    - `patchMe`로 업데이트 후 `notifyListeners` 호출
    - _요구사항: 8.2, 8.5_

  - [x] 4.6 Property 5: 시간 태그 전체 교체 속성 테스트 작성
    - **Property 5: 시간 태그 전체 교체**
    - **Validates: Requirements 4.4, 8.2, 8.5**
    - 임의의 `List<TimeSlot>`으로 `updateAvailableTimes` 호출 후 `currentUser.availableTimes`가 정확히 해당 목록과 동일한지 검증

  - [x] 4.7 `removeTag` 메서드에 `location`, `time` 케이스 추가
    - `TagType.location`: `displayLabel`이 일치하는 `LocationModel`을 `locations`에서 제거
    - `TagType.time`: `displayLabel`이 일치하는 `TimeSlot`을 `availableTimes`에서 제거
    - `patchMe`로 업데이트 후 `notifyListeners` 호출
    - _요구사항: 8.3, 8.6, 8.7_

  - [x] 4.8 Property 6: 태그 삭제 후 목록에서 제거 속성 테스트 작성
    - **Property 6: 태그 삭제 후 목록에서 제거**
    - **Validates: Requirements 2.4, 5.5, 8.6, 8.7**
    - 임의의 태그 값과 `TagType`에 대해 `removeTag` 호출 후 해당 카테고리에서 값이 존재하지 않는지 검증

  - [x] 4.9 Property 7: 공백 관심사 추가 거부 속성 테스트 작성
    - **Property 7: 공백 관심사 추가 거부**
    - **Validates: Requirements 5.6**
    - 공백 문자만으로 구성된 임의의 문자열에 대해 `addTag(value, TagType.interest)` 호출 후 `interests` 목록이 변경되지 않는지 검증

- [x] 5. 체크포인트 - 모델/ViewModel 검증
  - 모든 테스트가 통과하는지 확인합니다. 문제가 있으면 사용자에게 질문하세요.

- [x] 6. `LocationPicker` 위젯 구현 (`location_picker.dart`)
  - [x] 6.1 `lib/features/home/views/location_picker.dart` 파일 생성
    - `kLocationPresets` 상수 정의 (서울특별시, 경기도, 부산광역시 포함)
    - `LocationPicker` StatefulWidget 구현
    - 내부 상태 `_selectedProvince` 관리
    - 시/도 목록 → 시/군/구 목록 2단계 드릴다운 UI 구현
    - 시/군/구 선택 시 `onSelected(LocationModel)` 호출 후 다이얼로그 닫기
    - 뒤로가기/취소 시 `_selectedProvince = null` 초기화, `locations` 변경 없음
    - _요구사항: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7_

- [x] 7. `TimePicker` 위젯 구현 (`time_picker.dart`)
  - [x] 7.1 `lib/features/home/views/time_picker.dart` 파일 생성
    - `TimePicker` StatefulWidget 구현
    - 내부 상태 `_selected(Set<TimeSlot>)`, `_dragSelectMode(bool?)` 관리
    - 7(요일) × 24(시간) 그리드 렌더링
    - `onTapDown`: 단일 셀 토글
    - `onPanStart`: 시작 셀 상태 기준으로 `_dragSelectMode` 결정
    - `onPanUpdate`: 현재 포인터 위치 셀에 `_dragSelectMode` 적용
    - `onPanEnd`: `_dragSelectMode = null` 초기화
    - 진입 시 `initialSlots`를 `_selected`에 미리 로드
    - 확인 버튼: `onConfirm(_selected.toList())` 호출
    - 취소 버튼: 다이얼로그 닫기 (변경 없음)
    - 선택/미선택 셀 시각적 구분
    - _요구사항: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 8. `UserProfileCard` 재구성 (`home_screen_widgets.dart`)
  - [x] 8.1 `PageView` 2페이지 구조 제거, `Wrap` 단일 레이아웃으로 교체
    - `ConstrainedBox(maxHeight: 108)` + `SingleChildScrollView` + `Wrap(spacing:6, runSpacing:6)` 구조 적용
    - 카테고리 순서: location → time → gender → ageRange → interest
    - _요구사항: 7.1, 7.2, 7.3_

  - [x] 8.2 `UserProfileTag` 위젯에 색상 파라미터 추가
    - `color` 파라미터 추가, `kTagColors[tagType]`을 배경색으로 적용
    - _요구사항: 6.2, 6.3, 6.4_

  - [x] 8.3 각 카테고리별 "+" 버튼 및 태그 렌더링 연결
    - `location` "+" 버튼: `locations.length < 3`일 때만 표시, `LocationPicker` 다이얼로그 호출
    - `time` "+" 버튼: `TimePicker` 다이얼로그 호출, `updateAvailableTimes` 연결
    - `gender`, `ageRange`, `interest` "+" 버튼: 기존 `AddTagDialog` 유지
    - `AddTagDialog`의 `TagType` 드롭다운에서 `location`, `time` 제거 (별도 UI 사용)
    - _요구사항: 7.4, 3.6_

  - [x] 8.4 `removeTag` 호출 시 `location`/`time` 태그 삭제 연결
    - location 태그 X 버튼: `viewModel.removeTag(location.displayLabel, TagType.location)` 호출
    - time 태그 X 버튼: `viewModel.removeTag(slot.displayLabel, TagType.time)` 호출
    - _요구사항: 2.4, 5.5_

- [x] 9. 최종 체크포인트 - 통합 검증
  - 모든 테스트가 통과하는지 확인합니다. 문제가 있으면 사용자에게 질문하세요.

## 참고

- `*` 표시된 태스크는 선택적이며 MVP를 위해 건너뛸 수 있습니다.
- 속성 기반 테스트는 `glados` 패키지를 사용합니다 (`pubspec.yaml`에 dev_dependency 추가 필요).
- 각 태스크는 이전 태스크의 결과물을 기반으로 합니다.
- 체크포인트에서 테스트 실패 시 해당 태스크로 돌아가 수정합니다.
