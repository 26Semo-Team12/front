// lib/features/gathering/services/schedule_service.dart

import '../../../core/network/api_client.dart';

class ScheduleService {
  final ApiClient _apiClient = ApiClient();

  /// 일정 후보 목록 조회
  Future<List<Map<String, dynamic>>> getScheduleOptions(int gatheringId) async {
    final res = await _apiClient.get('/schedules/gatherings/$gatheringId/options');
    final List<dynamic> options = res['data']['options'];
    return options.cast<Map<String, dynamic>>();
  }

  /// 일정 후보 생성
  Future<Map<String, dynamic>> createScheduleOption(int gatheringId, DateTime startAt) async {
    final res = await _apiClient.post(
      '/schedules/gatherings/$gatheringId/options',
      body: {'startAt': startAt.toIso8601String()},
    );
    return res['data'];
  }

  /// 일정 투표
  Future<Map<String, dynamic>> voteScheduleOption(int scheduleOptionId, String status) async {
    final res = await _apiClient.put(
      '/schedules/options/$scheduleOptionId/vote',
      body: {'status': status},
    );
    return res['data'];
  }

  /// 일정 최종 확정
  Future<Map<String, dynamic>> finalizeSchedule(int gatheringId, int scheduleOptionId) async {
    final res = await _apiClient.post(
      '/schedules/gatherings/$gatheringId/finalize',
      body: {'scheduleOptionId': scheduleOptionId},
    );
    return res['data'];
  }
}
