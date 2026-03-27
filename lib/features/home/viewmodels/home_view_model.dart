// lib/features/home/viewmodels/home_view_model.dart

import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/mock_api_service.dart';
import '../models/invitation.dart';

enum TagType { location, time, gender, ageRange, interest }

class HomeViewModel extends ChangeNotifier {
  final MockApiService _apiService;
  UserProfile? _currentUser;
  List<Invitation> _invitations = [];
  InvitationType? _activeFilter; // null이면 전체 표시
  int _currentPageIndex = 0;

  HomeViewModel(this._apiService);

  InvitationType? get activeFilter => _activeFilter;
  int get currentPageIndex => _currentPageIndex;
  UserProfile? get currentUser => _currentUser;

  List<Invitation> get filteredInvitations {
    final list = _activeFilter == null
        ? List<Invitation>.from(_invitations)
        : _invitations.where((inv) => inv.type == _activeFilter).toList();
    list.sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }

  Future<void> init() async {
    _currentUser = await _apiService.getMe();
    _invitations = await _apiService.getInvitations();
    notifyListeners();
  }

  void toggleFilter(InvitationType type) {
    _activeFilter = (_activeFilter == type) ? null : type;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? profileImageUrl}) async {
    if (name != null && name.trim().isEmpty) return;
    _currentUser = await _apiService.patchMe(
      name: (name != null && name.trim().isNotEmpty) ? name : null,
      profileImageUrl: profileImageUrl,
    );
    notifyListeners();
  }

  void removeTag(String tagValue, TagType type) {
    if (_currentUser == null) return;
    switch (type) {
      case TagType.location:
        final updatedLocs = List<LocationModel>.from(_currentUser!.locations)
          ..removeWhere((loc) => loc.displayLabel == tagValue);
        _apiService.patchMe(locations: updatedLocs);
        _currentUser = _currentUser!.copyWith(locations: updatedLocs);
      case TagType.time:
        final updatedTimes = List<TimeSlot>.from(_currentUser!.availableTimes)
          ..removeWhere((slot) => slot.displayLabel == tagValue);
        _apiService.patchMe(availableTimes: updatedTimes);
        _currentUser = _currentUser!.copyWith(availableTimes: updatedTimes);
      case TagType.interest:
        final updated = List<String>.from(_currentUser!.interests)
          ..remove(tagValue);
        _apiService.patchMe(interests: updated);
        _currentUser = _currentUser!.copyWith(interests: updated);
      case TagType.ageRange:
        _apiService.patchMe(ageRange: null);
        _currentUser = _currentUser!.copyWith(ageRange: null);
      case TagType.gender:
        _apiService.patchMe(gender: null);
        _currentUser = _currentUser!.copyWith(gender: null);
    }
    notifyListeners();
  }

  Future<void> addTag(String tagValue, TagType type) async {
    if (tagValue.trim().isEmpty) return;
    if (_currentUser == null) return;
    switch (type) {
      case TagType.location:
        break;
      case TagType.time:
        break;
      case TagType.interest:
        final updated = List<String>.from(_currentUser!.interests)
          ..add(tagValue.trim());
        _currentUser = await _apiService.patchMe(interests: updated);
      case TagType.ageRange:
        _currentUser = await _apiService.patchMe(ageRange: tagValue.trim());
      case TagType.gender:
        _currentUser = await _apiService.patchMe(gender: tagValue.trim());
    }
    notifyListeners();
  }

  Future<void> updateAvailableTimes(List<TimeSlot> slots) async {
    if (_currentUser == null) return;
    _currentUser = await _apiService.patchMe(availableTimes: slots);
    notifyListeners();
  }

  Future<void> addLocation(LocationModel location) async {
    if (_currentUser == null) return;
    final current = _currentUser!.locations;
    if (current.length >= 3) return;
    if (current.contains(location)) return;
    final updated = List<LocationModel>.from(current)..add(location);
    _currentUser = await _apiService.patchMe(locations: updated);
    notifyListeners();
  }

  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }
}
