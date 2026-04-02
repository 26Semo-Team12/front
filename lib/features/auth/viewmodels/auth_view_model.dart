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

  String get email => _email;
  String? get emailError => _emailError;
  bool get isLoading => _isLoading;

  /// 이메일 입력값 업데이트
  void updateEmail(String value) {
    _email = value;
    // 입력 중 에러 메시지 초기화
    if (_emailError != null) {
      _emailError = null;
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

  /// '계속' 버튼 클릭 시 호출
  /// 유효성 검사 성공 시 [onSuccess] 콜백 호출
  Future<void> onContinuePressed(VoidCallback onSuccess) async {
    if (!_validateEmail()) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithEmail(_email.trim());
      onSuccess();
    } catch (e) {
      _emailError = '로그인에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google 로그인 (Mock)
  Future<void> onGoogleSignIn(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    notifyListeners();

    onSuccess();
  }

  /// Apple 로그인 (Mock)
  Future<void> onAppleSignIn(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    notifyListeners();

    onSuccess();
  }
}
