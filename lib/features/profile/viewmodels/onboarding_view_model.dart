import 'package:flutter/material.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/user_profile.dart';
import '../../auth/services/auth_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final String? email;
  final String? password;

  OnboardingViewModel({this.email, this.password});

  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Step 1 fields
  String _name = '';
  int? _birthYear;
  GenderType? _gender;
  LocationModel? _location;

  String get name => _name;
  int? get birthYear => _birthYear;
  GenderType? get gender => _gender;
  LocationModel? get location => _location;
  // 하위 호환용
  String get region => _location?.displayLabel ?? '';

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

  void setRegion(LocationModel loc) {
    _location = loc;
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
    if (_birthYear == null || _birthYear! < 1925 || _birthYear! > 2005) {
      _step1Error = '올바른 출생 연도를 입력해 주세요. (1925-2005)';
      notifyListeners();
      return false;
    }
    if (_gender == null) {
      _step1Error = '성별을 선택해 주세요.';
      notifyListeners();
      return false;
    }
    if (_location == null) {
      _step1Error = '주 활동 지역을 선택해 주세요.';
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
    _step2Error = null;
    notifyListeners();

    try {
      // 나이 계산: 현재 연도 - 출생연도
      final currentYear = DateTime.now().year;
      final age = currentYear - (_birthYear ?? currentYear);

      final signupData = {
        'email': email,
        'password': password,
        'name': _name.trim(),
        'age': age,
        'gender': _gender?.name.toLowerCase() ?? 'other',
        'location': _location?.displayLabel ?? '',
        'interests': _selectedInterests.toList(),
        'preferredSize': 'any',
        'profileImageBase64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      };

      await _authService.signUp(signupData);

      if (email != null && password != null) {
        await _authService.login(email!, password!);
      }

      onSuccess();
    } catch (e) {
      _step2Error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
