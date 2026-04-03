import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/enums.dart';
import '../../home/viewmodels/home_view_model.dart'; // TagType
import '../../auth/services/auth_service.dart';
import '../../auth/views/auth_screen.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  UserProfile? _currentUser;
  bool _isLoading = false;

  ProfileViewModel(this._authService) {
    _loadUser();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getMe();
      // 서버에서 모임 가능 시간도 로드
      try {
        final slots = await _authService.getAvailability();
        _currentUser = _currentUser?.copyWith(availableTimes: slots);
      } catch (e) {
        debugPrint('ProfileViewModel: getAvailability() failed: $e');
      }
    } catch (e) {
      debugPrint('ProfileViewModel._loadUser() failed: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void removeTag(String tagValue, TagType type) async {
    if (_currentUser == null) return;
    try {
      switch (type) {
        case TagType.location:
          final updated = List<LocationModel>.from(_currentUser!.locations)
            ..removeWhere((loc) => loc.displayLabel == tagValue);
          final newUser = await _authService.updateMe(
            location: updated.isNotEmpty ? updated.first.displayLabel : '',
          );
          _updateUser(newUser.copyWith(locations: updated));
          break;
        case TagType.interest:
          final updated = List<String>.from(_currentUser!.interests)
            ..remove(tagValue);
          final newUser = await _authService.updateMe(interests: updated);
          _updateUser(newUser);
          break;
        case TagType.ageRange:
          final newUser = await _authService.updateMe(ageRange: null);
          _updateUser(newUser);
          break;
        case TagType.gender:
          final newUser = await _authService.updateMe(gender: null);
          _updateUser(newUser);
          break;
        case TagType.time:
          final updated = List<TimeSlot>.from(_currentUser!.availableTimes)
            ..removeWhere((slot) => slot.displayLabel == tagValue);
          // Backend doesn't support availableTimes yet, keeping state updated locally.
          _currentUser = _currentUser?.copyWith(availableTimes: updated);
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
        case TagType.interest:
          final updated = List<String>.from(_currentUser!.interests)..add(val);
          final newUser = await _authService.updateMe(interests: updated);
          _updateUser(newUser);
          break;
        case TagType.ageRange:
          final newUser = await _authService.updateMe(ageRange: val);
          _updateUser(newUser);
          break;
        case TagType.gender:
          GenderType? mapped;
          if (val == '남성') mapped = GenderType.male;
          else if (val == '여성') mapped = GenderType.female;
          else mapped = GenderType.other;
          final newUser = await _authService.updateMe(gender: mapped);
          _updateUser(newUser);
          break;
        case TagType.location:
          // addLocation is used for LocationModel specifically
          break;
        case TagType.time:
          // updateAvailableTimes is used for List<TimeSlot>
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Tag addition failed: $e');
    }
  }

  Future<void> updateProfileImage(String base64Image) async {
    if (_currentUser == null) return;
    try {
      final newUser = await _authService.updateMe(profileImageBase64: base64Image);
      _updateUser(newUser);
    } catch (e) {
      debugPrint('Profile image update failed: $e');
    }
  }

  void _updateUser(UserProfile newUser) {
    if (_currentUser == null) {
      _currentUser = newUser;
    } else {
      // 서버에서 주지 않는 정보(availableTimes, locations 등)를 기존 정보에서 복사
      _currentUser = newUser.copyWith(
        availableTimes: newUser.availableTimes.isEmpty ? _currentUser!.availableTimes : newUser.availableTimes,
        locations: newUser.locations.isEmpty ? _currentUser!.locations : newUser.locations,
        ageRange: newUser.ageRange == null ? _currentUser!.ageRange : newUser.ageRange,
      );
    }
    notifyListeners();
  }

  Future<void> updateAvailableTimes(List<TimeSlot> slots) async {
    if (_currentUser == null) return;
    try {
      final updated = await _authService.updateAvailability(slots);
      _currentUser = _currentUser?.copyWith(availableTimes: updated);
      notifyListeners();
    } catch (e) {
      debugPrint('Available times update failed: $e');
      // 서버 실패 시 로컬만 업데이트
      _currentUser = _currentUser?.copyWith(availableTimes: slots);
      notifyListeners();
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
        final newUser = await _authService.updateMe(
          location: updated.first.displayLabel, // Primary location
        );
        _updateUser(newUser.copyWith(locations: updated));
      }
    } catch (e) {
      debugPrint('Location addition failed: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
    _isLoading = false;
  }

  Future<void> deleteAccount(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.deleteMe();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Account deletion failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRandomMode(bool enabled) async {
    if (_currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final newUser = await _authService.toggleRandomMode(enabled);
      _updateUser(newUser);
    } catch (e) {
      debugPrint('Random mode toggle failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
