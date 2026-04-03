import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  IO.Socket? _socket;
  final StreamController<NotificationItem> _popupController = StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get notificationStream => _popupController.stream;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnread => _notifications.any((n) => !n.isRead);

  NotificationViewModel() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _notificationService.getMyNotifications();
      _notifications = list;
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      _loadMockData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initSocket(int userId) {
    _socket = IO.io('http://43.201.46.164:3000/notifications', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'accessToken': ''},
    });

    // 토큰 설정 후 연결
    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('access_token') ?? '';
      _socket = IO.io('http://43.201.46.164:3000/notifications', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'accessToken': token},
      });

      _socket!.onConnect((_) {
        debugPrint('Connected to notification socket');
      });

      _socket!.on('notification', (data) {
        final notifData = data['notification'] as Map<String, dynamic>?;
        if (notifData != null) {
          final newNotif = NotificationItem.fromJson(notifData);
          _notifications.insert(0, newNotif);
          _popupController.add(newNotif); // 팝업 브로드캐스트
          notifyListeners();
        }
      });

      _socket!.connect();
    });
  }

  void _loadMockData() {
    _notifications = [
      NotificationItem(
        id: 1,
        userId: 1,
        type: NotificationType.invite,
        title: '새로운 모임 초대',
        content: '이번 주말 한강 디자이너 모임에 초대되었습니다.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  void markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      try {
        await _notificationService.markAsRead(id);
      } catch (e) {
        debugPrint('Failed to mark notification as read: $e');
      }
    }
  }

  void removeNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    _popupController.close();
    super.dispose();
  }

  void simulateNotification() {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      type: NotificationType.invite,
      title: '새로운 초대장',
      content: '방금 새로운 모임 초대장이 도착했습니다!',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, newItem);
    _popupController.add(newItem);
    notifyListeners();
  }

  void onNotificationTap(BuildContext context, NotificationItem item) {
    markAsRead(item.id);
    
    // TODO: 상세 화면 라우팅
    switch (item.type) {
      case NotificationType.invite:
        // Navigator.push(context, ...);
        break;
      case NotificationType.chat:
        break;
      case NotificationType.match:
        break;
      case NotificationType.evaluation:
        break;
      case NotificationType.schedule:
        break;
      case NotificationType.system:
        break;
    }
  }
}
