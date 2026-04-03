import '../../../core/network/api_client.dart';

class InviteService {
  final ApiClient _apiClient = ApiClient();

  /// GET /invite/me - 내 초대장 목록 조회
  Future<List<dynamic>> getMyInvitations({String status = 'PENDING', int limit = 20, int offset = 0}) async {
    final query = 'status=$status&limit=$limit&offset=$offset';
    final response = await _apiClient.get('/invite/me?$query');
    final data = response['data'];
    if (data is Map) {
      return (data['invitations'] as List<dynamic>?) ?? [];
    }
    if (data is List) {
      return data;
    }
    return [];
  }

  /// PATCH /invite/:invitationId/respond - 초대 수락/거절
  Future<void> respondToInvitation(int invitationId, String action) async {
    await _apiClient.patch('/invite/$invitationId/respond', body: {
      'action': action, // 'ACCEPT' or 'REJECT'
    });
  }

  /// POST /invite - 초대장 발송
  Future<void> sendInvitation(int gatheringId, int receiverUserId, String message) async {
    await _apiClient.post('/invite', body: {
      'gatheringId': gatheringId,
      'receiverUserId': receiverUserId,
      'message': message,
    });
  }
}
