import '../../../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// GET /notifications - 알림 목록 조회
  Future<List<NotificationItem>> getMyNotifications({bool onlyUnread = false}) async {
    final query = onlyUnread ? '?onlyUnread=true' : '';
    final response = await _apiClient.get('/notifications$query');
    final List<dynamic> data = response['data']['notifications'];
    return data.map((json) => NotificationItem.fromJson(json)).toList();
  }

  /// GET /notifications/unread-count - 미읽음 개수 조회
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    return response['data']['unreadCount'] as int;
  }

  /// PATCH /notifications/:id/read - 단건 읽음 처리
  Future<void> markAsRead(int notificationId) async {
    await _apiClient.patch('/notifications/$notificationId/read');
  }

  /// PATCH /notifications/read-all - 전체 읽음 처리
  Future<void> markAllAsRead() async {
    await _apiClient.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(int notificationId) async {
    await _apiClient.delete('/notifications/$notificationId');
  }
}
