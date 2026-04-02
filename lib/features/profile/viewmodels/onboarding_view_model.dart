import 'package:flutter/material.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/mock_api_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final MockApiService _mockApiService = MockApiService.instance;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Step 1 fields
  String _name = '';
  int? _birthYear;
  GenderType? _gender;
  String _region = '';

  String get name => _name;
  int? get birthYear => _birthYear;
  GenderType? get gender => _gender;
  String get region => _region;

  String? _step1Error;
  String? get step1Error => _step1Error;

  // Step 2 fields
  final Set<String> _selectedInterests = {};
  Set<String> get selectedInterests => _selectedInterests;

  String? _step2Error;
  String? get step2Error => _step2Error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setName(String value) {
    _name = value;
    _step1Error = null;
    notifyListeners();
  }

  void setBirthYear(int? value) {
    _birthYear = value;
    _step1Error = null;
    notifyListeners();
  }

  void setGender(GenderType type) {
    _gender = type;
    _step1Error = null;
    notifyListeners();
  }

  void setRegion(String value) {
    _region = value;
    _step1Error = null;
    notifyListeners();
  }

  void toggleInterest(String interest) {
    if (_selectedInterests.contains(interest)) {
      _selectedInterests.remove(interest);
    } else {
      _selectedInterests.add(interest);
    }
    _step2Error = null;
    notifyListeners();
  }

  bool validateStep1() {
    if (_name.trim().isEmpty) {
      _step1Error = '이름을 입력해 주세요.';
      notifyListeners();
      return false;
    }
    if (_birthYear == null || _birthYear! < 1900 || _birthYear! > DateTime.now().year) {
      _step1Error = '올바른 출생 연도를 입력해 주세요.';
      notifyListeners();
      return false;
    }
    if (_gender == null) {
      _step1Error = '성별을 선택해 주세요.';
      notifyListeners();
      return false;
    }
    if (_region.trim().isEmpty) {
      _step1Error = '주 활동 지역을 입력해 주세요.';
      notifyListeners();
      return false;
    }
    _step1Error = null;
    notifyListeners();
    return true;
  }

  bool validateStep2() {
    if (_selectedInterests.isEmpty) {
      _step2Error = '관심사를 1개 이상 선택해 주세요.';
      notifyListeners();
      return false;
    }
    _step2Error = null;
    notifyListeners();
    return true;
  }

  void nextStep() {
    if (_currentStep == 0) {
      if (validateStep1()) {
        _currentStep++;
        notifyListeners();
      }
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<void> submit(VoidCallback onSuccess) async {
    if (!validateStep2()) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _mockApiService.patchMe(
        name: _name.trim(),
        interests: _selectedInterests.toList(),
        gender: _gender,
      );
      // isProfileCompleted는 백엔드나 MockApiService에서 관리해야 하지만, 지금은 호출만 함.
      onSuccess();
    } catch (e) {
      _step2Error = '프로필 저장에 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
