import '../../../core/network/api_client.dart';
import '../models/evaluation.dart';

class EvaluationService {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitEvaluation({
    required int gatheringId,
    required int evaluateeId,
    required List<PositiveTag> positiveTags,
    required List<NegativeTag> negativeTags,
    String? comment,
  }) async {
    await _apiClient.post('/evaluation', body: {
      'gatheringId': gatheringId,
      'evaluateeId': evaluateeId,
      'positiveTags': positiveTags.map((e) => e.name).toList(),
      'negativeTags': negativeTags.map((e) => e.name).toList(),
      'comment': comment,
    });
  }

  Future<Map<String, dynamic>> getMyEvaluationSummary() async {
    final response = await _apiClient.get('/evaluation/me/summary');
    return response['data'];
  }
}
