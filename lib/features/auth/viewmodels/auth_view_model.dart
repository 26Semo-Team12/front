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

  // 하위 호환
  bool get isEmailSubmitted => _step != AuthStep.email;
  bool get isExistingUser => _step == AuthStep.password;

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

  /// 이메일 확인 → check-email API 모의
  Future<void> submitEmail() async {
    if (!_validateEmail()) return;
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: test@test.com = 기존 회원
    final exists = _email.trim() == 'test@test.com';
    _step = exists ? AuthStep.password : AuthStep.signup;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitPassword(void Function(bool isSignup) onSuccess) async {
    if (_password.trim().isEmpty) {
      _passwordError = '비밀번호를 입력해 주세요.';
      notifyListeners();
      return;
    }
    if (_step == AuthStep.signup) {
      if (_password.trim().length < 6) {
        _passwordError = '비밀번호는 6자리 이상이어야 합니다.';
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
    notifyListeners();

    try {
      await _authService.signInWithEmail(_email.trim());
      onSuccess(_step == AuthStep.signup);
    } catch (e) {
      _passwordError = '처리에 실패했습니다: $e';
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
