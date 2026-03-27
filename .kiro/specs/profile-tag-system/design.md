# 설계 문서: profile-tag-system

## 개요

Venture 앱의 프로필 태그 시스템을 기존 3종(interests, ageRange, gender)에서 5종(location, time, gender, ageRange, interest) 카테고리로 확장합니다.

주요 변경 사항:
- `LocationModel`, `TimeSlot` 불변 클래스 신규 추가 (직렬화 포함)
- `UserProfile` 모델에 `locations`, `availableTimes` 필드 추가
- `MockApiService`에 필수 태그 기본값 및 `patchMe` 확장
- `HomeViewModel`에 `addLocation`, `updateAvailableTimes`, `removeTag` 확장
- `LocationPicker` (2단계 드릴다운), `TimePicker` (7×24 그리드) 위젯 신규 추가
- `UserProfileCard` 태그 영역을 `Wrap` + 최대 높이 108px + 세로 스크롤로 재구성
- 카테고리별 태그 색상 상수 관리

---

## 아키텍처

기존 Flutter + Provider + MVVM 패턴을 유지합니다.

```
┌─────────────────────────────────────────────────────────┐
│                        View Layer                        │
│  UserProfileCard  LocationPicker  TimePicker  Dialogs   │
└────────────────────────┬────────────────────────────────┘
                         │ Provider.of<HomeViewModel>
┌────────────────────────▼────────────────────────────────┐
│                    ViewModel Layer                       │
│  HomeViewModel                                          │
│  - addLocation(LocationModel)                           │
│  - updateAvailableTimes(List<TimeSlot>)                 │
│  - removeTag(value, TagType)                            │
│  - addTag(value, TagType)                               │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    Service Layer                         │
│  MockApiService                                         │
│  - getMe() → UserProfile                               │
│  - patchMe({locations, availableTimes, ...})            │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                     Model Layer                          │
│  UserProfile  LocationModel  TimeSlot  TagType          │
└─────────────────────────────────────────────────────────┘
```

### 파일 구조

```
lib/
├── core/
│   ├── models/
│   │   ├── user_profile.dart          # UserProfile + LocationModel + TimeSlot
│   │   └── tag_colors.dart            # 카테고리별 색상 상수
│   └── services/
│       └── mock_api_service.dart      # patchMe 확장 + 기본값 추가
└── features/
    └── home/
        ├── viewmodels/
        │   └── home_view_model.dart   # TagType 확장 + 신규 메서드
        └── views/
            ├── home_screen_widgets.dart  # UserProfileCard 재구성
            ├── location_picker.dart      # LocationPicker 위젯
            └── time_picker.dart          # TimePicker 위젯
```

---

## 컴포넌트 및 인터페이스

### TagType 열거형

```dart
enum TagType { location, time, gender, ageRange, interest }
```

기존 3종에서 `location`, `time`이 추가됩니다.

---

### LocationPicker 위젯

2단계 드릴다운 UI입니다. `showDialog`로 표시하며, 내부 상태로 선택된 시/도(`_selectedProvince`)를 관리합니다.

**상태 흐름:**

```
[초기 상태]
  시/도 목록 표시
      │
      ▼ 시/도 탭
[시/도 선택됨]
  시/군/구 목록 + "[시/도 전체]" 표시
      │                    │
      ▼ 시/군/구 탭         ▼ 뒤로가기/취소
  LocationModel 생성       _selectedProvince = null
  onSelected(model) 호출   (불완전 데이터 버림)
  다이얼로그 닫힘
```

**인터페이스:**

```dart
class LocationPicker extends StatefulWidget {
  final void Function(LocationModel) onSelected;
  const LocationPicker({required this.onSelected});
}
```

**프리셋 데이터 구조:**

```dart
const Map<String, List<String>> kLocationPresets = {
  '서울특별시': ['강남구', '강북구', '마포구', '송파구', /* ... */],
  '경기도': ['수원시', '성남시', '고양시', '용인시', /* ... */],
  '부산광역시': ['해운대구', '수영구', '사하구', /* ... */],
  // 추가 지역...
};
```

---

### TimePicker 위젯

7(요일) × 24(시간) 그리드 UI입니다. when2meet 방식의 드래그 선택을 지원합니다.

**드래그 모드 결정 로직:**

```
드래그 시작 시:
  - 시작 셀이 미선택 상태 → 선택 모드 (드래그 경로 전체 선택)
  - 시작 셀이 선택 상태   → 해제 모드 (드래그 경로 전체 해제)
```

**인터페이스:**

```dart
class TimePicker extends StatefulWidget {
  final List<TimeSlot> initialSlots;
  final void Function(List<TimeSlot>) onConfirm;
  const TimePicker({required this.initialSlots, required this.onConfirm});
}
```

**내부 상태:**

```dart
class _TimePickerState extends State<TimePicker> {
  late Set<TimeSlot> _selected;   // 현재 선택된 슬롯 집합
  bool? _dragSelectMode;          // true=선택, false=해제, null=드래그 없음
}
```

**GestureDetector 이벤트 처리:**
- `onTapDown` → 단일 셀 토글
- `onPanStart` → 시작 셀 상태 기준으로 `_dragSelectMode` 결정
- `onPanUpdate` → 현재 포인터 위치의 셀에 `_dragSelectMode` 적용
- `onPanEnd` → `_dragSelectMode = null` 초기화

---

### UserProfileCard (재구성)

기존 `PageView` 2페이지 구조를 제거하고 단일 `Wrap` 레이아웃으로 통합합니다.

**태그 영역 레이아웃:**

```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 108),
  child: SingleChildScrollView(
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // location 태그들 + location "+" 버튼 (3개 미만일 때)
        // time 태그들 + time "+" 버튼
        // gender 태그 + gender "+" 버튼
        // ageRange 태그 + ageRange "+" 버튼
        // interest 태그들 + interest "+" 버튼
      ],
    ),
  ),
)
```

**"+" 버튼 동작:**
- `location`: `LocationPicker` 다이얼로그 표시 (locations.length >= 3이면 숨김)
- `time`: `TimePicker` 다이얼로그 표시
- `gender`, `ageRange`: 텍스트 입력 `AddTagDialog` 표시
- `interest`: 텍스트 입력 `AddTagDialog` 표시

---

### tag_colors.dart (신규)

```dart
// lib/core/models/tag_colors.dart
import 'package:flutter/material.dart';
import 'home_view_model.dart'; // TagType

const Map<TagType, Color> kTagColors = {
  TagType.location:  Color(0xFF4A90D9), // 파랑
  TagType.time:      Color(0xFF7B68EE), // 보라
  TagType.gender:    Color(0xFFE8A838), // 주황
  TagType.ageRange:  Color(0xFF50C878), // 초록
  TagType.interest:  Color(0xFFE05C5C), // 빨강
};
```

---

## 데이터 모델

### LocationModel

```dart
class LocationModel {
  final String province; // 시/도
  final String district; // 시/군/구 (빈 문자열 = 시/도 전체)

  const LocationModel({required this.province, required this.district});

  // 직렬화
  Map<String, dynamic> toJson() => {
    'province': province,
    'district': district,
  };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    province: json['province'] as String,
    district: json['district'] as String,
  );

  // 동등성 비교 (중복 체크에 사용)
  @override
  bool operator ==(Object other) =>
      other is LocationModel &&
      other.province == province &&
      other.district == district;

  @override
  int get hashCode => Object.hash(province, district);

  // 표시 문자열
  String get displayLabel =>
      district.isEmpty ? province : '$province $district';
}
```

### TimeSlot

직렬화 포맷: `"MON-09"` (요일 3자리 대문자 + `-` + 시작 시각 2자리 zero-padded)

```dart
class TimeSlot {
  final int weekday;   // 0=월, 1=화, ..., 6=일
  final int hourIndex; // 0~23

  const TimeSlot({required this.weekday, required this.hourIndex});

  static const List<String> _weekdayLabels = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  ];

  // 직렬화: "MON-09"
  String toSerializedString() =>
      '${_weekdayLabels[weekday]}-${hourIndex.toString().padLeft(2, '0')}';

  // 역직렬화: "MON-09" → TimeSlot(weekday: 0, hourIndex: 9)
  factory TimeSlot.fromSerializedString(String s) {
    final parts = s.split('-');
    final weekday = _weekdayLabels.indexOf(parts[0]);
    final hourIndex = int.parse(parts[1]);
    return TimeSlot(weekday: weekday, hourIndex: hourIndex);
  }

  // 표시 문자열
  String get displayLabel =>
      '${_weekdayLabels[weekday]} ${hourIndex.toString().padLeft(2, '0')}:00';

  @override
  bool operator ==(Object other) =>
      other is TimeSlot &&
      other.weekday == weekday &&
      other.hourIndex == hourIndex;

  @override
  int get hashCode => Object.hash(weekday, hourIndex);
}
```

### UserProfile (확장)

```dart
class UserProfile {
  final String name;
  final String profileImageUrl;
  final List<LocationModel> locations;      // 신규 (필수, 최대 3개)
  final List<TimeSlot> availableTimes;      // 신규 (필수)
  final List<String> interests;
  final String? ageRange;                   // nullable로 변경
  final String? gender;                     // nullable로 변경
  final double rating;

  UserProfile copyWith({
    String? name,
    String? profileImageUrl,
    List<LocationModel>? locations,
    List<TimeSlot>? availableTimes,
    List<String>? interests,
    String? ageRange,
    String? gender,
  });
}
```

### MockApiService (확장)

```dart
// 기본값 포함
UserProfile _currentUser = UserProfile(
  name: '김벤처',
  profileImageUrl: 'https://picsum.photos/seed/user1/200',
  locations: [LocationModel(province: '로렘시', district: '입숨구')],
  availableTimes: [
    TimeSlot(weekday: 0, hourIndex: 9),  // MON-09
    TimeSlot(weekday: 2, hourIndex: 14), // WED-14
    TimeSlot(weekday: 4, hourIndex: 19), // FRI-19
  ],
  interests: ['등산', '독서', '요리'],
  ageRange: '20대',
  gender: '남성',
  rating: 4.5,
);

Future<UserProfile> patchMe({
  String? name,
  String? profileImageUrl,
  List<LocationModel>? locations,
  List<TimeSlot>? availableTimes,
  List<String>? interests,
  String? ageRange,
  String? gender,
}) async { ... }
```

---

## 정확성 속성 (Correctness Properties)

*속성(Property)이란 시스템의 모든 유효한 실행에서 참이어야 하는 특성 또는 동작입니다. 즉, 시스템이 무엇을 해야 하는지에 대한 형식적 명세입니다. 속성은 사람이 읽을 수 있는 명세와 기계가 검증할 수 있는 정확성 보장 사이의 다리 역할을 합니다.*

### Property 1: TimeSlot 직렬화 라운드트립

*임의의* 유효한 `TimeSlot`(weekday: 0~6, hourIndex: 0~23)에 대해, `toSerializedString()` 후 `fromSerializedString()`을 수행하면 원래 값과 동일한 `TimeSlot`이 반환되어야 한다.

직렬화 포맷(`"MON-09"`)이 올바르게 구현되었는지를 라운드트립으로 검증한다. weekday와 hourIndex 두 필드 모두 보존되어야 한다.

**Validates: Requirements 1.3, 4.8**

---

### Property 2: LocationModel 직렬화 라운드트립

*임의의* `LocationModel`(임의의 province, district 문자열 쌍)에 대해, `toJson()` 후 `fromJson()`을 수행하면 원래 값과 동일한 `LocationModel`이 반환되어야 한다.

province와 district 두 필드 모두 직렬화/역직렬화 과정에서 손실 없이 보존되어야 한다.

**Validates: Requirements 1.2**

---

### Property 3: 지역 태그 중복 불허

*임의의* `LocationModel`에 대해, 동일한 값(province와 district 모두 일치)을 `addLocation`으로 두 번 추가하면 `locations` 목록의 크기는 한 번 추가했을 때와 동일해야 한다.

중복 추가 시도는 조용히 무시되어야 하며, 목록에는 항상 유일한 `LocationModel`만 존재해야 한다.

**Validates: Requirements 3.8, 8.4**

---

### Property 4: 지역 태그 최대 3개 제한

*임의의* `LocationModel` 목록에 대해, `addLocation`을 반복 호출하더라도 `locations` 목록의 크기는 절대 3을 초과하지 않아야 한다.

이 속성은 중복 여부와 무관하게 항상 성립해야 한다. 즉, 서로 다른 4개의 `LocationModel`을 추가해도 `locations.length <= 3`이어야 한다.

**Validates: Requirements 3.6, 8.4**

---

### Property 5: 시간 태그 전체 교체

*임의의* `List<TimeSlot>`으로 `updateAvailableTimes`를 호출하면, `currentUser.availableTimes`는 정확히 해당 목록과 동일해야 한다.

이전에 저장된 `availableTimes` 값은 완전히 교체되어야 하며, 이전 슬롯이 잔존하거나 새 슬롯이 누락되어서는 안 된다.

**Validates: Requirements 4.4, 8.2, 8.5**

---

### Property 6: 태그 삭제 후 목록에서 제거

*임의의* `UserProfile`과 임의의 태그 값 및 `TagType`에 대해, `removeTag(value, type)`을 호출하면 해당 카테고리 목록에서 그 값이 더 이상 존재하지 않아야 한다.

`location`, `time`, `interest` 타입은 목록에서 해당 항목이 제거되어야 하고, `gender`, `ageRange` 타입은 해당 필드가 null 또는 빈 값으로 초기화되어야 한다.

**Validates: Requirements 2.4, 5.5, 8.6, 8.7**

---

### Property 7: 공백 관심사 추가 거부

*임의의* 공백 문자(스페이스, 탭, 줄바꿈 등)만으로 구성된 문자열에 대해, `addTag(value, TagType.interest)`를 호출하면 `interests` 목록이 변경되지 않아야 한다.

빈 문자열뿐 아니라 순수 공백 문자열도 유효하지 않은 입력으로 처리되어야 한다.

**Validates: Requirements 5.6**

---

### Property 8: 태그 색상 완전성

*임의의* `TagType` 값(location, time, gender, ageRange, interest)에 대해, `kTagColors`에서 해당 타입의 색상을 조회하면 항상 null이 아닌 `Color` 값이 반환되어야 한다.

모든 TagType이 색상 맵에 등록되어 있어야 하며, 새로운 TagType이 추가될 경우 색상 맵도 함께 업데이트되어야 한다.

**Validates: Requirements 6.1, 6.5**

---

## 오류 처리

| 상황 | 처리 방식 |
|------|-----------|
| `addLocation` 호출 시 `locations.length >= 3` | 조용히 무시 (UI에서 버튼 비활성화로 선제 방지) |
| `addLocation` 호출 시 중복 `LocationModel` | 조용히 무시 |
| `addTag` 호출 시 빈 문자열/공백 | `AddTagDialog`에서 `"태그 값을 입력해주세요"` 오류 메시지 표시 |
| `LocationPicker`에서 시/도만 선택 후 취소 | `_selectedProvince = null` 초기화, `locations` 변경 없음 |
| `TimePicker`에서 취소 | `availableTimes` 변경 없음 |
| `TimeSlot.fromSerializedString` 잘못된 포맷 | `RangeError` 또는 `FormatException` 발생 (호출부에서 try-catch 처리) |
| `LocationModel.fromJson` 필드 누락 | `TypeError` 발생 (MockApiService 내부 데이터이므로 실제 발생 가능성 낮음) |

---

## 테스트 전략

### 이중 테스트 접근법

단위 테스트와 속성 기반 테스트를 함께 사용합니다. 단위 테스트는 구체적인 예시와 엣지 케이스를, 속성 기반 테스트는 임의 입력에 대한 보편적 속성을 검증합니다.

### 단위 테스트

- `TimeSlot.toSerializedString()` 구체적 예시 검증 (`TimeSlot(weekday:0, hourIndex:9)` → `"MON-09"`)
- `LocationModel` 동등성 비교 (`==` 연산자)
- `HomeViewModel.addLocation` 중복/최대 개수 제한 동작
- `HomeViewModel.removeTag` 각 TagType별 동작
- `LocationPicker` 취소 시 상태 초기화 확인
- `TimePicker` 드래그 모드 결정 로직 (시작 셀 선택 상태 기준)
- `AddTagDialog` 빈 입력 오류 메시지 표시

### 속성 기반 테스트

Flutter/Dart 환경에서는 [**dart_test**](https://pub.dev/packages/test)와 함께 [**glados**](https://pub.dev/packages/glados) 라이브러리를 사용합니다.

각 속성 테스트는 최소 100회 반복 실행합니다.

**테스트 태그 형식:** `// Feature: profile-tag-system, Property {번호}: {속성 설명}`

```dart
// Feature: profile-tag-system, Property 1: TimeSlot 직렬화 라운드트립
test('TimeSlot serialization round trip', () {
  Glados2<int, int>().test(
    'TimeSlot round trip',
    (weekday, hourIndex) {
      final slot = TimeSlot(
        weekday: weekday % 7,
        hourIndex: hourIndex % 24,
      );
      expect(
        TimeSlot.fromSerializedString(slot.toSerializedString()),
        equals(slot),
      );
    },
  );
});
```

```dart
// Feature: profile-tag-system, Property 3: 지역 태그 중복 불허
test('addLocation rejects duplicates', () {
  Glados<LocationModel>().test(
    'no duplicate locations',
    (location) {
      final vm = HomeViewModel(MockApiService());
      vm.addLocation(location);
      vm.addLocation(location); // 동일 값 재추가
      expect(vm.currentUser!.locations.length, equals(1));
    },
  );
});
```

```dart
// Feature: profile-tag-system, Property 4: 지역 태그 최대 3개 제한
test('locations never exceed 3', () {
  Glados<List<LocationModel>>().test(
    'max 3 locations',
    (locations) {
      final vm = HomeViewModel(MockApiService());
      for (final loc in locations) {
        vm.addLocation(loc);
      }
      expect(vm.currentUser!.locations.length, lessThanOrEqualTo(3));
    },
  );
});
```

각 설계 속성(Property 1~8)은 단일 속성 기반 테스트로 구현합니다.
