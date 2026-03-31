// lib/core/services/mock_api_service.dart

import 'package:front/core/models/user_profile.dart';
import 'package:front/features/home/models/invitation.dart';

/// MockApiService
/// 실제 HTTP 클라이언트 없이 Future를 반환하여 비동기 API 패턴을 모방합니다.
/// 내부에 _currentUser 상태를 유지하여 patchMe 후 getMe가 수정된 데이터를 반환합니다.
class MockApiService {
  UserProfile _currentUser = UserProfile(
    name: '김벤처',
    profileImageUrl: 'https://picsum.photos/seed/user1/200',
    locations: [LocationModel(province: '로렘시', district: '입숨구')],
    availableTimes: [
      TimeSlot(weekday: 0, hourIndex: 9),
      TimeSlot(weekday: 2, hourIndex: 14),
      TimeSlot(weekday: 4, hourIndex: 19),
    ],
    interests: ['등산', '독서', '요리'],
    ageRange: '20대',
    gender: '남성',
    rating: 4.5,
  );

  /// 현재 사용자 프로필을 반환합니다.
  /// 요구사항 10.1
  Future<UserProfile> getMe() async {
    return _currentUser;
  }

  /// 프로필을 수정하고 수정된 UserProfile을 반환합니다.
  /// 요구사항 10.2
  Future<UserProfile> patchMe({
    String? name,
    String? profileImageUrl,
    List<LocationModel>? locations,
    List<TimeSlot>? availableTimes,
    List<String>? interests,
    Object? ageRange = UserProfile.unset,
    Object? gender = UserProfile.unset,
  }) async {
    _currentUser = _currentUser.copyWith(
      name: name,
      profileImageUrl: profileImageUrl,
      locations: locations,
      availableTimes: availableTimes,
      interests: interests,
      ageRange: ageRange,
      gender: gender,
    );
    return _currentUser;
  }

  /// 초대장 목록을 반환합니다.
  /// newInvitation, longTerm, expired 3종 타입을 포함합니다.
  /// 요구사항 10.3
  Future<List<Invitation>> getInvitations() async {
    return [
      Invitation(
        id: 'inv-001',
        type: InvitationType.newInvitation,
        title: '주말 등산 모임',
        dateTime: DateTime(2025, 8, 10, 9, 0),
        location: '북한산 국립공원',
        imageUrl: 'https://picsum.photos/seed/hiking/400/200',
        memberCount: 6,
      ),
      Invitation(
        id: 'inv-002',
        type: InvitationType.newInvitation,
        title: '독서 클럽 정기 모임',
        dateTime: DateTime(2025, 8, 15, 14, 0),
        location: '강남구 카페 북스',
        imageUrl: 'https://picsum.photos/seed/books/400/200',
        memberCount: 8,
      ),
      Invitation(
        id: 'inv-003',
        type: InvitationType.longTerm,
        title: '매주 수요일 요리 스터디',
        dateTime: DateTime(2025, 8, 20, 18, 30),
        location: '마포구 쿠킹 스튜디오',
        imageUrl: 'https://picsum.photos/seed/cooking/400/200',
        memberCount: 5,
      ),
      Invitation(
        id: 'inv-004',
        type: InvitationType.longTerm,
        title: '월간 사진 동호회',
        dateTime: DateTime(2025, 9, 1, 10, 0),
        location: '서울숲',
        imageUrl: null,
        memberCount: 12,
      ),
      Invitation(
        id: 'inv-005',
        type: InvitationType.expired,
        title: '봄 소풍 피크닉',
        dateTime: DateTime(2025, 4, 5, 11, 0),
        location: '한강공원 여의도',
        imageUrl: 'https://picsum.photos/seed/picnic/400/200',
        memberCount: 10,
      ),
      Invitation(
        id: 'inv-006',
        type: InvitationType.expired,
        title: '신년 맞이 번개 모임',
        dateTime: DateTime(2025, 1, 3, 19, 0),
        location: '홍대 루프탑 바',
        imageUrl: null,
        memberCount: 15,
      ),
      Invitation(
        id: 'inv-007',
        type: InvitationType.newInvitation,
        title: '주말 보드게임 모임',
        dateTime: DateTime(2025, 9, 6, 14, 0),
        location: '강남구 보드게임 카페',
        imageUrl: 'https://picsum.photos/seed/boardgame/400/200',
        memberCount: 6,
      ),
      Invitation(
        id: 'inv-008',
        type: InvitationType.longTerm,
        title: '매월 첫째 주 독서 모임',
        dateTime: DateTime(2025, 9, 7, 15, 0),
        location: '마포구 공공도서관',
        imageUrl: 'https://picsum.photos/seed/library/400/200',
        memberCount: 9,
      ),
      Invitation(
        id: 'inv-009',
        type: InvitationType.newInvitation,
        title: '한강 자전거 라이딩',
        dateTime: DateTime(2025, 9, 13, 8, 0),
        location: '여의도 한강공원',
        imageUrl: 'https://picsum.photos/seed/cycling/400/200',
        memberCount: 11,
      ),
    ];
  }

  /// 앱 설정 정보를 반환합니다.
  /// 요구사항 10.4
  Future<Map<String, dynamic>> getSettings() async {
    return {
      'notifications': {
        'newInvitation': true,
        'longTerm': true,
        'expired': false,
      },
      'privacy': {
        'showProfile': true,
        'showLocation': false,
      },
      'theme': 'light',
      'language': 'ko',
    };
  }
}
