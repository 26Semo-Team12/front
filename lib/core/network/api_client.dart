// lib/core/network/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전반의 API 통신을 담당하는 기본 HTTP 클라이언트 래퍼
class ApiClient {
  static const String baseUrl = 'https://api.ventureapp.local/v1'; // 환경에 따라 변경
  
  final http.Client _client = http.Client();

  /// 로그인 시 저장된 토큰을 헤더에 주입하기 위해 SharedPreferences에서 읽어옵니다.
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.put(
      uri,
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.delete(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      // 401 Unauthorized 처리 등은 여기서 전역적으로 할 수 있음
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
