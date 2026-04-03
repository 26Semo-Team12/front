import '../../../core/network/api_client.dart';

class InviteService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getMyInvitations({String status = 'PENDING', int limit = 20, int offset = 0}) async {
    final query = 'status=$status&limit=$limit&offset=$offset';
    final response = await _apiClient.get('/invite/me?$query');
    return response['data']['invitations'];
  }

  Future<void> respondToInvitation(int invitationId, String status) async {
    await _apiClient.patch('/invite/$invitationId/status', body: {
      'status': status,
    });
  }

  Future<void> sendInvitation(int gatheringId, int receiverUserId, String message) async {
    await _apiClient.post('/invite', body: {
      'gatheringId': gatheringId,
      'receiverUserId': receiverUserId,
      'message': message,
    });
  }
}
