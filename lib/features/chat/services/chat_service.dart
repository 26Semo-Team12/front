// lib/features/chat/services/chat_service.dart

import '../../../core/network/api_client.dart';
import '../models/chat_room.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  /// 내 채팅방 목록 조회
  Future<List<ChatRoom>> getChatRooms() async {
    final res = await _apiClient.get('/chatting/rooms');
    final List<dynamic> data = res['data'];
    return data.map((json) => ChatRoom.fromJson(json)).toList();
  }

  /// 특정 채팅방 메시지 기록 조회
  Future<Map<String, dynamic>> getChatMessages(int roomId, {int? limit, int? beforeMessageId}) async {
    String query = '?limit=${limit ?? 30}';
    if (beforeMessageId != null) query += '&beforeMessageId=$beforeMessageId';
    
    final res = await _apiClient.get('/chatting/rooms/$roomId/messages$query');
    return res['data'];
  }

  /// 모임 채팅방 열기 (조회 또는 생성)
  Future<ChatRoom> openGatheringChatRoom(int gatheringId) async {
    final res = await _apiClient.post('/chatting/gatherings/$gatheringId/rooms');
    return ChatRoom.fromJson(res['data']);
  }

  /// 1:1 DIRECT 채팅방 생성 또는 조회
  Future<ChatRoom> openDirectChatRoom(int targetUserId) async {
    final res = await _apiClient.post('/chatting/direct-rooms', body: {'targetUserId': targetUserId});
    return ChatRoom.fromJson(res['data']);
  }
}
