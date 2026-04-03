// lib/features/auth/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/enums.dart';
/// 회원가입/로그인을 담당하는 서비스 레이어
class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// 이메일 존재 여부 확인 및 다음 단계 반환
  /// { success, data: { email, exists, nextStep } }
  Future<Map<String, dynamic>> checkEmail(String email) async {
    final res = await _apiClient.post('/auth/check-email', body: {'email': email});
    return res['data'];
  }

  /// 로그인 처리
  Future<UserProfile> login(String email, String password) async {
    final res = await _apiClient.post('/login', body: {
      'email': email,
      'password': password,
    });

    final data = res['data'];
    final token = data['accessToken'];
    final userJson = data['user'];

    // 토큰 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    return UserProfile.fromJson(userJson);
  }

  /// 회원가입 처리
  Future<UserProfile> signUp(Map<String, dynamic> signupData) async {
    final res = await _apiClient.post('/auth/signup', body: signupData);
    final userJson = res['data'];

    // 회원가입 성공 후 자동 로그인을 위해 토큰을 바로 받지는 않으므로, 
    // 보통은 가입 후 로그인을 다시 하거나 서버가 토큰을 같이 줌.
    // 가이드에는 가입 성공 응답에 토큰이 없으므로, 필요시 로그인을 따로 호출해야 할 수도 있음.
    return UserProfile.fromJson(userJson);
  }

  /// 내 정보 조회 (세션 확인용)
  Future<UserProfile> getMe() async {
    final res = await _apiClient.get('/auth/me');
    return UserProfile.fromJson(res['data']);
  }

  /// 회원 탈퇴
  Future<void> deleteMe() async {
    await _apiClient.delete('/auth/me');
    await signOut();
  }

  /// 로그아웃 시 인증 토큰 제거
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
  
  /// 랜덤 모드 토글 (matching_mode = RANDOM | INTEREST)
  Future<UserProfile> toggleRandomMode(bool enabled) async {
    final res = await _apiClient.patch('/auth/me/random-mode', body: {'enabled': enabled});
    return UserProfile.fromJson(res['data']);
  }

  /// 프로필 수정 (name, profileImageBase64, birth_year, gender, region, interests, age_range 등)
  Future<UserProfile> updateMe({
    String? name,
    String? profileImageBase64,
    int? birthYear,
    GenderType? gender,
    String? region,
    List<String>? interests,
    String? ageRange,
    int? age,
    String? location,
    String? preferredSize,
  }) async {
    final body = {
      if (name != null) 'name': name,
      if (profileImageBase64 != null) 'profileImageBase64': profileImageBase64,
      if (birthYear != null) 'birth_year': birthYear,
      if (gender != null) 'gender': gender.value,
      if (region != null) 'region': region,
      if (interests != null) 'interests': interests,
      if (ageRange != null) 'age_range': ageRange,
      if (age != null) 'age': age,
      if (location != null) 'location': location,
      if (preferredSize != null) 'preferredSize': preferredSize,
    };

    final res = await _apiClient.patch('/auth/me', body: body);
    return UserProfile.fromJson(res['data']);
  }

  /// 현재 로그인 되어있는지 토큰 유무로 검사
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  /// GET /auth/me/availability - 모임 가능 시간 조회
  Future<List<TimeSlot>> getAvailability() async {
    final res = await _apiClient.get('/auth/me/availability');
    final List<dynamic> slots = res['data']['slots'] ?? [];
    return slots.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// PUT /auth/me/availability - 모임 가능 시간 수정
  Future<List<TimeSlot>> updateAvailability(List<TimeSlot> slots) async {
    final res = await _apiClient.put('/auth/me/availability', body: {
      'slots': slots.map((s) => s.toServerJson()).toList(),
    });
    final List<dynamic> updated = res['data']['slots'] ?? [];
    return updated.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }
}

