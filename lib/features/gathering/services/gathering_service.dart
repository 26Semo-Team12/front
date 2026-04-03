// lib/features/gathering/services/gathering_service.dart

import '../../../core/network/api_client.dart';
import '../models/gathering.dart';

class GatheringService {
  final ApiClient _apiClient = ApiClient();

  /// 내 모임 목록 조회
  Future<List<Gathering>> getMyGatherings() async {
    final res = await _apiClient.get('/gatherings/me');
    final List<dynamic> data = res['data'];
    return data.map((json) => Gathering.fromJson(json)).toList();
  }

  /// 모임 상세 조회
  Future<Gathering> getGatheringDetail(int gatheringId) async {
    final res = await _apiClient.get('/gatherings/$gatheringId');
    return Gathering.fromJson(res['data']);
  }

  /// 모임 생성 (테스트용)
  Future<Gathering> createGathering(Map<String, dynamic> gatheringData) async {
    final res = await _apiClient.post('/gatherings', body: gatheringData);
    return Gathering.fromJson(res['data']);
  }
}
