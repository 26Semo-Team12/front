import 'package:flutter/material.dart';
import '../../../core/services/mock_api_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/enums.dart';
import '../../home/viewmodels/home_view_model.dart'; // TagType
import '../../auth/views/auth_screen.dart';

class ProfileViewModel extends ChangeNotifier {
  final MockApiService _apiService;
  UserProfile? _currentUser;
  bool _isLoading = false;

  ProfileViewModel(this._apiService) {
    _loadUser();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await _apiService.getMe();
    _isLoading = false;
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
      case TagType.time:
        break;
    }
    notifyListeners();
  }

  Future<void> addTag(String tagValue, TagType type) async {
    final val = tagValue.trim();
    if (val.isEmpty || _currentUser == null) return;
    switch (type) {
      case TagType.interest:
        final updated = List<String>.from(_currentUser!.interests)..add(val);
        _currentUser = await _apiService.patchMe(interests: updated);
      case TagType.ageRange:
        _currentUser = await _apiService.patchMe(ageRange: val);
      case TagType.gender:
        GenderType? mapped;
        if (val == '남성') mapped = GenderType.male;
        else if (val == '여성') mapped = GenderType.female;
        else mapped = GenderType.other;
        _currentUser = await _apiService.patchMe(gender: mapped);
      case TagType.location:
      case TagType.time:
        break;
    }
    notifyListeners();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    if (_currentUser == null) return;
    _currentUser = await _apiService.patchMe(profileImageUrl: imageUrl);
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

  Future<void> logout(BuildContext context) async {
    // Mock clearing shared_preferences / token
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }
}
