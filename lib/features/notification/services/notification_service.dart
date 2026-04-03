import '../../../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationItem>> getMyNotifications() async {
    final response = await _apiClient.get('/notification/me');
    final List<dynamic> data = response['data'];
    return data.map((json) => NotificationItem.fromJson(json)).toList();
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiClient.patch('/notification/$notificationId/read');
  }

  Future<void> deleteNotification(int notificationId) async {
    await _apiClient.delete('/notification/$notificationId');
  }
}
