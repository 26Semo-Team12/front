# 구현 계획: 홈 화면 인터랙션 (home-screen-interactions)

## 개요

설계 문서에 정의된 순서대로 데이터 모델 → 서비스 레이어 → ViewModel → View 순으로 구현합니다.
각 단계는 이전 단계의 결과물을 기반으로 하며, 체크포인트에서 전체 테스트를 검증합니다.

## 태스크

- [x] 1. 데이터 모델 변경
  - [x] 1.1 Invitation 모델 재작성
    - `lib/features/home/models/invitation.dart`에서 기존 `description`, `isNew`, `isRegular` 필드 제거
    - `InvitationType` enum (`newInvitation`, `longTerm`, `expired`) 추가
    - `Invitation` 클래스에 `id`, `type`, `dateTime`, `location`, `imageUrl(nullable)`, `memberCount` 필드 추가
    - _요구사항: 8.1, 8.2_

  - [x] 1.2 Invitation 모델 속성 테스트 작성
    - `test/features/home/models/invitation_test.dart` 생성
    - **속성 8: 초대장 목록 정렬 순서 불변** — 임의의 Invitation 목록이 `type.index` 오름차순으로 정렬됨을 검증
    - **검증 대상: 요구사항 6.7**

  - [x] 1.3 UserProfile 모델 변경
    - `lib/core/models/user_profile.dart`에서 `interests`, `ageRange`, `gender` 필드의 `final` 제거
    - `copyWith` 메서드 추가 (`name`, `profileImageUrl`, `interests`, `ageRange`, `gender` 파라미터)
    - _요구사항: 8.3 (간접), 2.2, 3.2, 4.2_

  - [x] 1.4 UserProfile copyWith 속성 테스트 작성
    - `test/core/models/user_profile_test.dart` 생성
    - **속성 5: 이름 업데이트 반영** — 임의의 유효한 이름으로 `copyWith` 후 `name` 일치 검증
    - **검증 대상: 요구사항 2.2**

- [x] 2. MockApiService 구현
  - [x] 2.1 MockApiService 클래스 생성
    - `lib/core/services/mock_api_service.dart` 신규 생성
    - `getMe()` → `Future<UserProfile>` 반환 (목업 데이터)
    - `patchMe({String? name, String? profileImageUrl, List<String>? interests, String? ageRange, String? gender})` → 내부 상태 수정 후 `Future<UserProfile>` 반환
    - `getInvitations()` → `Future<List<Invitation>>` 반환 (3종 타입 포함 목업 데이터)
    - `getSettings()` → `Future<Map<String, dynamic>>` 반환
    - _요구사항: 10.1, 10.2, 10.3, 10.4_

  - [x] 2.2 MockApiService 속성 테스트 작성
    - `test/core/services/mock_api_service_test.dart` 생성
    - **속성 11: MockAPI 프로필 수정 라운드 트립** — 임의의 유효한 수정 데이터로 `patchMe` 후 `getMe` 결과 일치 검증
    - **검증 대상: 요구사항 10.2**

- [x] 3. 체크포인트 — 모델 및 서비스 레이어 검증
  - 모든 테스트가 통과하는지 확인합니다. 문제가 있으면 사용자에게 알려주세요.

- [x] 4. HomeViewModel 재작성
  - [x] 4.1 HomeViewModel에 MockApiService 주입 및 필터 상태 교체
    - `lib/features/home/viewmodels/home_view_model.dart` 수정
    - 생성자에서 `MockApiService` 주입 (`MockApiService _apiService`)
    - `_selectedTabIndex` → `InvitationType? _activeFilter` (null = 전체)로 교체
    - `init()` 메서드에서 `_apiService.getMe()`와 `_apiService.getInvitations()` 호출
    - `filteredInvitations` getter: `_activeFilter`가 null이면 전체, 아니면 해당 타입만 반환 후 `type.index` 오름차순 정렬
    - `toggleFilter(InvitationType type)`: 동일 타입이면 null로, 다른 타입이면 해당 타입으로 설정
    - `updateProfile({String? name, String? profileImageUrl})`: `_apiService.patchMe` 호출 후 `_currentUser` 갱신
    - `removeTag(String tagValue, TagType type)`: 해당 필드에서 값 제거 후 `_apiService.patchMe` 호출
    - `addTag(String tagValue, TagType type)`: 유효성 검사(빈 값 거부) 후 해당 필드에 추가 및 `_apiService.patchMe` 호출
    - _요구사항: 6.4, 6.5, 6.6, 6.7, 2.2, 3.2, 4.2, 4.3, 10.5_

  - [x] 4.2 HomeViewModel 태그 삭제 속성 테스트 작성
    - `test/features/home/viewmodels/home_view_model_test.dart` 생성
    - **속성 1: 태그 삭제 후 목록에서 제거됨** — 임의의 태그 목록에서 임의의 태그 삭제 후 해당 값 부재 검증
    - **검증 대상: 요구사항 3.2**

  - [x] 4.3 HomeViewModel 태그 추가 속성 테스트 작성
    - **속성 2: 태그 추가 후 목록에 포함됨** — 임의의 유효 태그 값과 TagType 추가 후 해당 필드 포함 검증
    - **검증 대상: 요구사항 4.2**

  - [x] 4.4 HomeViewModel 빈 값 거부 속성 테스트 작성
    - **속성 3: 빈 값 입력은 거부됨** — 임의의 공백 문자열로 태그/이름 저장 시도 시 거부 및 상태 불변 검증
    - **검증 대상: 요구사항 2.4, 4.3**

  - [x] 4.5 HomeViewModel 필터 속성 테스트 작성
    - **속성 6: 필터 적용 시 해당 타입만 반환됨** — 임의의 Invitation 목록에 필터 적용 시 결과 타입 일치 검증
    - **속성 7: 필터 토글 라운드 트립** — 필터 활성화 후 동일 필터 재탭 시 전체 복원 검증
    - **검증 대상: 요구사항 6.5, 6.6**

- [x] 5. SettingsScreen 생성 및 AppBar 네비게이션 연결
  - [x] 5.1 SettingsScreen 플레이스홀더 생성
    - `lib/features/settings/views/settings_screen.dart` 신규 생성
    - `Scaffold` + `AppBar(title: Text('설정'), leading: BackButton())` + `body: Center(child: Text('설정 화면'))`
    - _요구사항: 1.2_

  - [x] 5.2 CustomAppBar를 StatelessWidget으로 재작성
    - `lib/features/home/views/home_screen_widgets.dart`에서 `CustomAppBar extends AppBar` → `StatelessWidget implements PreferredSizeWidget`으로 변경
    - `preferredSize` getter: `Size.fromHeight(kToolbarHeight)` 반환
    - `build` 메서드 내부에서 `AppBar` 반환
    - 설정 버튼 `onPressed`에서 `Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))` 호출
    - _요구사항: 1.1, 1.3_

- [x] 6. UserProfileCard 태그 UI 개편
  - [x] 6.1 UserProfileTag에 X 버튼 및 onDelete 콜백 추가
    - `UserProfileTag`에 `onDelete` 콜백 파라미터 추가
    - 태그 텍스트 우측에 `GestureDetector`로 감싼 `Icon(Icons.close, size: 14)` 추가
    - X 버튼 탭 시 `onDelete()` 호출
    - _요구사항: 3.1, 3.2_

  - [x] 6.2 태그 목록 마지막에 "+" 버튼 추가
    - 각 페이지의 태그 Row 마지막에 "+" 버튼 위젯 추가
    - "+" 버튼 탭 시 `AddTagDialog` 표시
    - _요구사항: 3.3, 4.1_

  - [x] 6.3 AddTagDialog 구현
    - `lib/features/home/views/home_screen_widgets.dart`에 `AddTagDialog` StatefulWidget 추가
    - `DropdownButton<TagType>`으로 태그 종류 선택 (`TagType` enum: `interest`, `ageRange`, `gender`)
    - `TextField`로 값 입력
    - 빈 값 제출 시 오류 텍스트("태그 값을 입력해주세요") 표시
    - 추가 버튼 탭 시 `viewModel.addTag` 호출 후 팝업 닫기
    - 취소 버튼 탭 시 팝업만 닫기 (상태 변경 없음)
    - _요구사항: 4.1, 4.2, 4.3, 4.4_

  - [x] 6.4 페이지 인디케이터 제거
    - `UserProfileCard`의 `_buildPageIndicator` 메서드 및 인디케이터 Row 제거
    - `PageView` 스와이프 기능은 유지
    - _요구사항: 5.1, 5.2_

  - [x] 6.5 UserProfileTag onDelete 콜백 단위 테스트 작성
    - `test/features/home/views/home_screen_widgets_test.dart` 생성
    - X 버튼 탭 시 `onDelete` 콜백 호출 검증
    - **속성 4: 다이얼로그/팝업 취소 시 상태 불변** — 취소 탭 후 ViewModel 상태 불변 검증
    - **검증 대상: 요구사항 3.1, 2.3, 4.4_**

- [x] 7. 체크포인트 — ViewModel 및 프로필 UI 검증
  - 모든 테스트가 통과하는지 확인합니다. 문제가 있으면 사용자에게 알려주세요.

- [x] 8. InvitationSection 필터 버튼 방식으로 개편
  - [x] 8.1 FilterButton 위젯 구현
    - `lib/features/home/views/home_screen_widgets.dart`에 `FilterButton` StatelessWidget 추가
    - `label`, `type(InvitationType)`, `isSelected(bool)`, `onTap(VoidCallback)` 파라미터
    - `borderRadius: 20`, 선택 시 배경색 `Color(0xFFD6706D)` + 흰색 텍스트, 비선택 시 흰색 배경 + 회색 테두리
    - _요구사항: 6.2, 6.3_

  - [x] 8.2 InvitationSection 탭바 → FilterButton 3개로 교체
    - `InvitationSection`에서 `DefaultTabController`, `TabBar` 제거
    - 지도 아이콘(`Icons.map_outlined`) 제거
    - `FilterButton` 3개 (`새 초대장/newInvitation`, `장기 모임/longTerm`, `만료된 초대장/expired`) Row로 배치
    - 각 버튼의 `isSelected`는 `viewModel.activeFilter == type`으로 결정
    - 각 버튼의 `onTap`은 `viewModel.toggleFilter(type)` 호출
    - `_buildInvitationList`는 `viewModel.filteredInvitations` 사용
    - `InvitationSection` 생성자에서 `selectedTabIndex` 파라미터 제거
    - _요구사항: 6.1, 6.2, 6.4, 6.5, 6.6, 6.7_

- [x] 9. InvitationCard 이미지 카드 형태로 재작성
  - [x] 9.1 날짜 포맷 헬퍼 함수 구현
    - `lib/features/home/views/home_screen_widgets.dart` 내부에 `_formatDateTime(DateTime dt)` 함수 추가
    - `intl` 패키지 없이 수동 포맷: `'${dt.year}년 ${dt.month}월 ${dt.day}일 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'`
    - _요구사항: 7.3_

  - [x] 9.2 날짜 포맷 속성 테스트 작성
    - **속성 10: 날짜 포맷 형식 준수** — 임의의 DateTime 값에 대해 포맷 결과가 "yyyy년 MM월 dd일 HH:mm" 형식 준수 검증
    - **검증 대상: 요구사항 7.3**

  - [x] 9.3 InvitationCard 이미지 카드 형태로 재작성
    - 기존 `InvitationCard` 위젯 전면 교체
    - 상단: `ClipRRect`로 감싼 이미지 영역 (`imageUrl` null이면 회색 배경 + 아이콘 플레이스홀더)
    - 하단: `title`, `_formatDateTime(invitation.dateTime)`, `location`, `memberCount` 텍스트 표시
    - _요구사항: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 9.4 InvitationCard 필수 정보 표시 위젯 테스트 작성
    - **속성 9: 초대장 카드 필수 정보 표시** — 임의의 Invitation 렌더링 시 title, location, memberCount 포함 검증
    - **검증 대상: 요구사항 7.2, 7.4, 7.5**

- [x] 10. HomeScreen 및 BottomActionArea 정리
  - [x] 10.1 BottomActionArea 제거 및 HomeScreen 정리
    - `lib/features/home/views/home_screen.dart`에서 `BottomActionArea` 위젯 참조 제거
    - `lib/features/home/views/home_screen_widgets.dart`에서 `BottomActionArea` 클래스 삭제
    - `HomeScreen`에서 `MockApiService`를 생성하여 `HomeViewModel` 생성자에 주입
    - `InvitationSection` 호출 시 `selectedTabIndex` 파라미터 제거
    - _요구사항: 9.1, 9.2, 10.5_

- [x] 11. 최종 체크포인트 — 전체 통합 검증
  - 모든 테스트가 통과하는지 확인합니다. 문제가 있으면 사용자에게 알려주세요.

## 참고

- `*` 표시된 서브태스크는 선택 사항으로 MVP 구현 시 건너뛸 수 있습니다.
- 속성 기반 테스트는 `test` 패키지를 사용하며, 각 테스트는 설계 문서의 속성 번호를 주석으로 참조합니다.
- 날짜 포맷은 `intl` 패키지 없이 수동 구현합니다.
