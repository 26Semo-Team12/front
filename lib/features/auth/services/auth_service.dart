// lib/features/auth/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/mock_api_service.dart';

/// 회원가입/로그인을 담당하는 서비스 레이어
class AuthService {
  // 실제 연동 시엔 ApiClient를 주입받아 사용
  // final ApiClient _apiClient;
  // AuthService(this._apiClient);

  /// 이메일을 사용하여 로그인을 모의 처리하고 UserProfile을 반환합니다.
  Future<UserProfile> signInWithEmail(String email) async {
    // 1. API 호출 (Mock)
    await Future.delayed(const Duration(milliseconds: 800));

    // 2. 응답으로 받은 토큰 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', 'mock_jwt_token_for_$email');

    // 3. Mock Api Service 중앙 레포지토리 업데이트
    // 신규 로그인인 경우 이메일을 세팅하고 기본 뼈대 정보를 등록해둡니다.
    final profile = await MockApiService.instance.patchMe(
      email: email,
      name: email.split('@').first,
    );

    return profile;
  }

  /// 로그아웃 시 인증 토큰 제거
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
  
  /// 현재 로그인 되어있는지 토큰 유무로 검사
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
