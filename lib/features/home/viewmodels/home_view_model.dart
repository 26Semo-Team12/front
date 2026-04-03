// lib/features/home/viewmodels/home_view_model.dart

import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/enums.dart';
import '../../auth/services/auth_service.dart';
import '../../gathering/services/invite_service.dart';
import '../models/invitation.dart';

enum TagType { location, time, gender, ageRange, interest }

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService;
  final InviteService _inviteService;
  UserProfile? _currentUser;
  List<Invitation> _invitations = [];
  // 멀티 셀렉트 필터: 기본값 = 새 초대장 + 장기 모임 활성화
  Set<InvitationType> _activeFilters = {
    InvitationType.newInvitation,
    InvitationType.longTerm,
  };

  Set<InvitationType> get activeFilters => Set.unmodifiable(_activeFilters);
  int _currentPageIndex = 0;

  HomeViewModel(this._authService, this._inviteService);

  InvitationType? get activeFilter => null; // 하위 호환용 (미사용)
  int get currentPageIndex => _currentPageIndex;
  UserProfile? get currentUser => _currentUser;

  List<Invitation> get filteredInvitations {
    final list = _invitations
        .where((inv) => _activeFilters.contains(inv.type))
        .toList();
    list.sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }

  Future<void> init() async {
    try {
      _currentUser = await _authService.getMe();
      if (_currentUser?.email == 'asdf@asdf.asdf') {
        // 데모 계정: 각 타입 1개씩 mock 데이터
        _invitations = [
          Invitation(
            id: 'mock-new',
            type: InvitationType.newInvitation,
            title: '주말 등산 모임',
            dateTime: DateTime(2025, 8, 10, 9, 0),
            location: '북한산 국립공원',
            imageUrl: 'https://picsum.photos/seed/hiking/400/200',
            memberCount: 6,
          ),
          Invitation(
            id: 'mock-long',
            type: InvitationType.longTerm,
            title: '매주 수요일 요리 스터디',
            dateTime: DateTime(2025, 8, 20, 18, 30),
            location: '마포구 쿠킹 스튜디오',
            imageUrl: 'https://picsum.photos/seed/cooking/400/200',
            memberCount: 5,
          ),
          Invitation(
            id: 'mock-expired',
            type: InvitationType.expired,
            title: '봄 소풍 피크닉',
            dateTime: DateTime(2025, 4, 5, 11, 0),
            location: '한강공원 여의도',
            imageUrl: 'https://picsum.photos/seed/picnic/400/200',
            memberCount: 10,
          ),
        ];
      } else {
        final realInvites = await _inviteService.getMyInvitations();
        _invitations = realInvites.map((e) => Invitation.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('HomeViewModel.init() failed: $e');
    }
    notifyListeners();
  }

  void toggleFilter(InvitationType type) {
    if (_activeFilters.contains(type)) {
      _activeFilters.remove(type);
    } else {
      _activeFilters.add(type);
    }
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? profileImageUrl}) async {
    if (name != null && name.trim().isEmpty) return;
    try {
      _currentUser = await _authService.updateMe(
        name: (name != null && name.trim().isNotEmpty) ? name : null,
        profileImageUrl: profileImageUrl,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Profile update failed: $e');
    }
  }

  void removeTag(String tagValue, TagType type) async {
    if (_currentUser == null) return;
    try {
      switch (type) {
        case TagType.location:
          final updated = List<LocationModel>.from(_currentUser!.locations)
            ..removeWhere((loc) => loc.displayLabel == tagValue);
          _currentUser = await _authService.updateMe(
            location: updated.isNotEmpty ? updated.first.displayLabel : '',
          );
          _currentUser = _currentUser?.copyWith(locations: updated);
          break;
        case TagType.time:
          final updated = List<TimeSlot>.from(_currentUser!.availableTimes)
            ..removeWhere((slot) => slot.displayLabel == tagValue);
          // Backend doesn't support availableTimes yet, keeping state updated locally.
          _currentUser = _currentUser?.copyWith(availableTimes: updated);
          break;
        case TagType.interest:
          final updated = List<String>.from(_currentUser!.interests)
            ..remove(tagValue);
          _currentUser = await _authService.updateMe(interests: updated);
          break;
        case TagType.ageRange:
          // Setting null in copyWith/updateMe if supported.
          break;
        case TagType.gender:
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Tag removal failed: $e');
    }
  }

  Future<void> addTag(String tagValue, TagType type) async {
    final val = tagValue.trim();
    if (val.isEmpty || _currentUser == null) return;
    try {
      switch (type) {
        case TagType.location:
        case TagType.time:
          break;
        case TagType.interest:
          final updated = List<String>.from(_currentUser!.interests)..add(val);
          _currentUser = await _authService.updateMe(interests: updated);
          break;
        case TagType.ageRange:
          _currentUser = await _authService.updateMe(ageRange: val);
          break;
        case TagType.gender:
          GenderType? mapped;
          if (val == '남성') mapped = GenderType.male;
          else if (val == '여성') mapped = GenderType.female;
          else mapped = GenderType.other;
          _currentUser = await _authService.updateMe(gender: mapped);
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Tag addition failed: $e');
    }
  }

  Future<void> updateAvailableTimes(List<TimeSlot> slots) async {
    if (_currentUser == null) return;
    try {
      // Backend doesn't support availableTimes yet, keeping state updated locally.
      _currentUser = _currentUser?.copyWith(availableTimes: slots);
      notifyListeners();
    } catch (e) {
      debugPrint('Home: Available times update failed: $e');
    }
  }

  Future<void> addLocation(LocationModel location) async {
    if (_currentUser == null) return;
    try {
      final updated = List<LocationModel>.from(_currentUser!.locations);
      if (!updated.contains(location)) {
        if (updated.length >= 3) {
          updated.removeAt(0);
        }
        updated.add(location);
        _currentUser = await _authService.updateMe(
          location: updated.first.displayLabel, // Primary location
        );
        _currentUser = _currentUser?.copyWith(locations: updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Home: Location addition failed: $e');
    }
  }

  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  /// 마이페이지 수정 후 홈화면 프로필 갱신
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getMe();
      notifyListeners();
    } catch (e) {
      debugPrint('HomeViewModel.refreshUser() failed: $e');
    }
  }

  void updateInvitationMeta(String id, {String? newTitle, String? newImageUrl}) {
    final index = _invitations.indexWhere((inv) => inv.id == id);
    if (index != -1) {
      _invitations[index] = _invitations[index].copyWith(
        title: newTitle,
        imageUrl: newImageUrl,
      );
      notifyListeners();
    }
  }
}
