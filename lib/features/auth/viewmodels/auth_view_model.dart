// lib/features/auth/viewmodels/auth_view_model.dart

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStep { email, password, signup }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStep _step = AuthStep.email;
  AuthStep get step => _step;

  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String get email => _email;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirm => _obscureConfirm;

  // 하위 호환 및 상태
  bool get isEmailSubmitted => _step != AuthStep.email;
  bool _exists = false;
  bool get isExistingUser => _exists;

  void updateEmail(String v) {
    _email = v;
    if (_emailError != null) { _emailError = null; notifyListeners(); }
  }

  void updatePassword(String v) {
    _password = v;
    if (_passwordError != null) { _passwordError = null; notifyListeners(); }
  }

  void updateConfirmPassword(String v) {
    _confirmPassword = v;
    if (_passwordError != null) { _passwordError = null; notifyListeners(); }
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  bool _validateEmail() {
    if (_email.trim().isEmpty) {
      _emailError = '이메일을 입력해 주세요.';
      notifyListeners();
      return false;
    }
    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(_email.trim())) {
      _emailError = '올바른 이메일 형식을 입력해 주세요.';
      notifyListeners();
      return false;
    }
    _emailError = null;
    notifyListeners();
    return true;
  }

  /// 이메일 확인 → check-email API 호출
  Future<void> onContinuePressed() async {
    if (!_validateEmail()) return;
    _isLoading = true;
    _emailError = null;
    notifyListeners();

    try {
      final data = await _authService.checkEmail(_email.trim());
      
      _exists = data['exists'] ?? false;
      final nextStep = data['nextStep'];

      if (nextStep == 'LOGIN') {
        _step = AuthStep.password;
      } else if (nextStep == 'SIGNUP') {
        _step = AuthStep.signup;
      } else {
        // 기본값 처리
        _step = _exists ? AuthStep.password : AuthStep.signup;
      }
    } catch (e) {
      _emailError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitPassword(void Function(bool isSignup, {String? email, String? password}) onSuccess) async {
    if (_password.trim().isEmpty) {
      _passwordError = '비밀번호를 입력해 주세요.';
      notifyListeners();
      return;
    }
    if (_step == AuthStep.signup) {
      if (_password.trim().length < 8) {
        _passwordError = '비밀번호는 8자리 이상이어야 합니다.';
        notifyListeners();
        return;
      }
      if (_password != _confirmPassword) {
        _passwordError = '비밀번호가 일치하지 않습니다.';
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _passwordError = null;
    notifyListeners();

    try {
      if (_step == AuthStep.password) {
        // 로그인 루틴
        await _authService.login(_email.trim(), _password.trim());
        onSuccess(false);
      } else {
        // 회원가입 전초 단계: Onboarding으로 이동
        // 여기서 실제 가입을 하는게 아니라 정보를 들고 온보딩으로 넘김
        onSuccess(true, email: _email.trim(), password: _password.trim());
      }
    } catch (e) {
      _passwordError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goBackToEmail() {
    _step = AuthStep.email;
    _password = '';
    _confirmPassword = '';
    _passwordError = null;
    notifyListeners();
  }
}
