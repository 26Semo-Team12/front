# 요구사항 문서

## 소개

Venture 앱의 홈 화면 UI 수정 및 버튼 기능 구현 스펙입니다.
Venture는 비슷한 관심사를 가진 사람들을 연결해 오프라인 모임을 주선하는 Flutter 모바일 앱으로,
홈 화면은 사용자 프로필 카드, 초대장 목록, 앱바로 구성됩니다.
이번 작업은 현재 기능이 없는 버튼들에 실제 동작을 연결하고, UI 구조를 개선하는 것을 목표로 합니다.

---

## 용어 정의

- **HomeScreen**: 앱 실행 후 사용자가 처음 보는 메인 화면
- **AppBar**: 화면 상단의 앱 바 (로고, 설정 버튼 포함)
- **UserProfileCard**: 사용자 프로필 사진, 이름, 태그를 표시하는 카드 위젯
- **Tag**: 사용자의 관심사, 나이대, 성별 등을 나타내는 칩 형태의 UI 요소
- **InvitationSection**: 초대장 및 모임 목록을 표시하는 섹션
- **InvitationCard**: 개별 초대장 또는 모임 정보를 표시하는 카드 위젯
- **InvitationType**: 초대장의 종류 (newInvitation / longTerm / expired)
- **FilterButton**: 초대장 목록을 종류별로 필터링하는 토글 버튼
- **SettingsScreen**: 설정 화면 (플레이스홀더)
- **HomeViewModel**: 홈 화면의 상태와 비즈니스 로직을 관리하는 ViewModel
- **MockAPI**: 백엔드 연동 전 목업 데이터를 반환하는 가상 API 레이어

---

## 요구사항

### 요구사항 1: AppBar 설정 버튼 네비게이션

**사용자 스토리:** 사용자로서, 홈 화면 상단의 설정 버튼을 눌러 설정 화면으로 이동하고 싶다. 그래야 앱 설정을 변경할 수 있다.

#### 인수 기준

1. WHEN 사용자가 AppBar의 설정 아이콘 버튼을 탭하면, THE HomeScreen SHALL 설정 화면(SettingsScreen)으로 네비게이션한다.
2. THE SettingsScreen SHALL 플레이스홀더 텍스트("설정 화면")와 뒤로 가기 버튼을 포함한다.
3. WHEN 사용자가 SettingsScreen에서 뒤로 가기를 탭하면, THE HomeScreen SHALL 이전 홈 화면 상태를 유지한 채로 복귀한다.

---

### 요구사항 2: 프로필 편집 다이얼로그

**사용자 스토리:** 사용자로서, 프로필 카드의 편집 아이콘을 눌러 이름과 프로필 사진을 수정하고 싶다. 그래야 내 정보를 최신 상태로 유지할 수 있다.

#### 인수 기준

1. WHEN 사용자가 UserProfileCard의 편집 아이콘을 탭하면, THE HomeScreen SHALL 이름 편집 필드와 사진 변경 옵션을 포함한 다이얼로그를 표시한다.
2. WHEN 사용자가 다이얼로그에서 이름을 수정하고 확인을 탭하면, THE HomeViewModel SHALL 사용자 이름을 업데이트하고 UserProfileCard에 즉시 반영한다.
3. WHEN 사용자가 다이얼로그에서 취소를 탭하면, THE HomeScreen SHALL 다이얼로그를 닫고 기존 프로필 정보를 유지한다.
4. IF 사용자가 이름 필드를 비워두고 확인을 탭하면, THEN THE HomeScreen SHALL 유효성 오류 메시지("이름을 입력해주세요")를 표시한다.

---

### 요구사항 3: 태그 삭제 기능

**사용자 스토리:** 사용자로서, 프로필 카드의 태그 옆 X 버튼을 눌러 원하지 않는 태그를 삭제하고 싶다. 그래야 내 관심사 목록을 관리할 수 있다.

#### 인수 기준

1. THE UserProfileCard SHALL 각 태그 우측에 X 버튼을 표시한다.
2. WHEN 사용자가 태그의 X 버튼을 탭하면, THE HomeViewModel SHALL 해당 태그를 사용자 프로필에서 제거하고 UserProfileCard를 즉시 업데이트한다.
3. THE UserProfileCard SHALL 태그 목록의 마지막에 "+" 버튼을 표시한다.

---

### 요구사항 4: 태그 추가 기능

**사용자 스토리:** 사용자로서, 프로필 카드의 "+" 버튼을 눌러 새 태그를 추가하고 싶다. 그래야 내 관심사나 정보를 보완할 수 있다.

#### 인수 기준

1. WHEN 사용자가 UserProfileCard의 "+" 버튼을 탭하면, THE HomeScreen SHALL 태그 종류 선택(관심사 / 나이대 / 성별)과 값 입력 필드를 포함한 팝업을 표시한다.
2. WHEN 사용자가 태그 종류를 선택하고 값을 입력한 후 추가를 탭하면, THE HomeViewModel SHALL 해당 태그를 사용자 프로필에 추가하고 UserProfileCard를 즉시 업데이트한다.
3. IF 사용자가 값 입력 필드를 비워두고 추가를 탭하면, THEN THE HomeScreen SHALL 유효성 오류 메시지("태그 값을 입력해주세요")를 표시한다.
4. WHEN 사용자가 팝업에서 취소를 탭하면, THE HomeScreen SHALL 팝업을 닫고 기존 태그 목록을 유지한다.

---

### 요구사항 5: 프로필 카드 페이지 인디케이터 제거

**사용자 스토리:** 사용자로서, 프로필 카드에서 불필요한 페이지 인디케이터 없이 태그를 스와이프로 탐색하고 싶다. 그래야 더 깔끔한 UI를 경험할 수 있다.

#### 인수 기준

1. THE UserProfileCard SHALL 페이지 인디케이터 동그라미를 표시하지 않는다.
2. THE UserProfileCard SHALL 관심사 페이지와 나이+성별 페이지 간 스와이프 기능을 유지한다.

---

### 요구사항 6: InvitationSection UI 개편

**사용자 스토리:** 사용자로서, 초대장 섹션에서 지도 아이콘과 탭바 대신 필터 버튼으로 초대장을 분류하고 싶다. 그래야 더 직관적으로 원하는 초대장을 찾을 수 있다.

#### 인수 기준

1. THE InvitationSection SHALL 헤더 우측의 지도 아이콘을 표시하지 않는다.
2. THE InvitationSection SHALL 탭바(정기모임/새초대장/만료) 대신 "새 초대장", "장기 모임", "만료된 초대장" 세 개의 FilterButton을 표시한다.
3. THE FilterButton SHALL 모서리가 둥근 사각형(borderRadius: 20) 형태의 토글 버튼으로 렌더링된다.
4. WHEN 아무 FilterButton도 선택되지 않은 상태이면, THE InvitationSection SHALL 모든 초대장을 표시한다.
5. WHEN 사용자가 FilterButton을 탭하면, THE InvitationSection SHALL 해당 InvitationType에 해당하는 초대장만 필터링하여 표시한다.
6. WHEN 사용자가 이미 선택된 FilterButton을 다시 탭하면, THE InvitationSection SHALL 필터를 해제하고 전체 초대장을 표시한다.
7. THE InvitationSection SHALL 초대장을 newInvitation → longTerm → expired 순서로 정렬하여 표시한다.

---

### 요구사항 7: 초대장 카드 이미지 형태로 변경

**사용자 스토리:** 사용자로서, 초대장 카드에서 이미지와 함께 제목, 일시, 장소를 확인하고 싶다. 그래야 모임 정보를 한눈에 파악할 수 있다.

#### 인수 기준

1. THE InvitationCard SHALL 상단에 이미지 영역(imageUrl이 null인 경우 플레이스홀더 이미지)을 표시한다.
2. THE InvitationCard SHALL 이미지 하단에 초대장 제목(title)을 표시한다.
3. THE InvitationCard SHALL 모임 일시(dateTime)를 "yyyy년 MM월 dd일 HH:mm" 형식으로 표시한다.
4. THE InvitationCard SHALL 모임 장소(location)를 표시한다.
5. THE InvitationCard SHALL 참여 인원(memberCount)을 표시한다.

---

### 요구사항 8: Invitation 모델 변경

**사용자 스토리:** 개발자로서, Invitation 모델이 실제 서비스 데이터 구조를 반영하도록 변경하고 싶다. 그래야 백엔드 API와 일관된 데이터 구조를 유지할 수 있다.

#### 인수 기준

1. THE Invitation SHALL type(InvitationType), title(String), dateTime(DateTime), location(String), imageUrl(String?), memberCount(int) 필드를 포함한다.
2. THE InvitationType SHALL newInvitation, longTerm, expired 세 가지 값을 가지는 열거형(enum)이다.
3. THE HomeViewModel SHALL 변경된 Invitation 모델을 사용하는 목업 데이터를 제공한다.

---

### 요구사항 9: BottomActionArea 제거

**사용자 스토리:** 개발자로서, 렌더링되지 않는 "새로운 모험 시작하기" 버튼 영역을 제거하고 싶다. 그래야 불필요한 코드를 정리하고 화면 레이아웃을 개선할 수 있다.

#### 인수 기준

1. THE HomeScreen SHALL BottomActionArea 위젯을 포함하지 않는다.
2. THE HomeScreen SHALL BottomActionArea 제거 후에도 정상적으로 렌더링된다.

---

### 요구사항 10: 목업 API 레이어 구현

**사용자 스토리:** 개발자로서, 백엔드 연동 전 목업 API를 통해 데이터를 관리하고 싶다. 그래야 실제 API 연동 시 최소한의 변경으로 전환할 수 있다.

#### 인수 기준

1. THE MockAPI SHALL GET /users/me 엔드포인트에 해당하는 목업 메서드를 제공하여 UserProfile을 반환한다.
2. THE MockAPI SHALL PATCH /users/me 엔드포인트에 해당하는 목업 메서드를 제공하여 이름, 사진, 태그 수정을 처리한다.
3. THE MockAPI SHALL GET /invitations 엔드포인트에 해당하는 목업 메서드를 제공하여 Invitation 목록을 반환한다.
4. THE MockAPI SHALL GET /settings 엔드포인트에 해당하는 목업 메서드를 제공하여 설정 정보를 반환한다.
5. THE HomeViewModel SHALL MockAPI를 통해 데이터를 로드한다.
