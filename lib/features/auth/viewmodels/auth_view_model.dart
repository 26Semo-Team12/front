// lib/features/auth/viewmodels/auth_view_model.dart

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// 로그인/회원가입 화면의 비즈니스 로직 ViewModel
/// - 이메일 입력 상태 관리
/// - 유효성 검사
/// - Mock 로그인 처리
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String _email = '';
  String? _emailError;
  bool _isLoading = false;

  bool _isEmailSubmitted = false;
  bool _isExistingUser = false;
  String _password = '';
  String _confirmPassword = '';
  String? _passwordError;

  String get email => _email;
  String? get emailError => _emailError;
  bool get isLoading => _isLoading;

  bool get isEmailSubmitted => _isEmailSubmitted;
  bool get isExistingUser => _isExistingUser;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String? get passwordError => _passwordError;

  void updateEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
  }

  void updatePassword(String value) {
    _password = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  /// 이메일 유효성 검사
  bool _validateEmail() {
    if (_email.trim().isEmpty) {
      _emailError = '이메일을 입력해 주세요.';
      notifyListeners();
      return false;
    }

    // 이메일 형식 확인
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(_email.trim())) {
      _emailError = '올바른 이메일 형식을 입력해 주세요.';
      notifyListeners();
      return false;
    }

    _emailError = null;
    notifyListeners();
    return true;
  }

  Future<void> onContinuePressed(void Function(bool isSignup) onSuccess) async {
    if (!_isEmailSubmitted) {
      if (!_validateEmail()) return;
      _isLoading = true;
      notifyListeners();
      
      // Mock User Check (test@test.com == 기존유저)
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isEmailSubmitted = true;
      _isExistingUser = (_email.trim() == 'test@test.com');
      
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_password.trim().isEmpty) {
      _passwordError = '비밀번호를 입력해 주세요.';
      notifyListeners();
      return;
    }
    
    if (!_isExistingUser) {
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
      onSuccess(!_isExistingUser);
    } catch (e) {
      _passwordError = '로그인에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google 로그인 (Mock)
  Future<void> onGoogleSignIn(void Function(bool isSignup) onSuccess) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    notifyListeners();

    onSuccess(false);
  }

  /// Apple 로그인 (Mock)
  Future<void> onAppleSignIn(void Function(bool isSignup) onSuccess) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    notifyListeners();

    onSuccess(false);
  }
}
