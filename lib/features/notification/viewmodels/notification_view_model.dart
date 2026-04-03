import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  IO.Socket? _socket;

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
    });

    _socket!.onConnect((_) {
      debugPrint('Connected to notification socket');
      _socket!.emit('authenticate', {'userId': userId});
    });

    _socket!.on('notification', (data) {
      final newNotif = NotificationItem.fromJson(data);
      _notifications.insert(0, newNotif);
      notifyListeners();
    });

    _socket!.connect();
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
      NotificationItem(
        id: 2,
        userId: 1,
        type: NotificationType.chat,
        title: '새로운 메시지',
        content: '마포구 맛집 탐방 모임방에서 메시지가 도착했습니다.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationItem(
        id: 3,
        userId: 1,
        type: NotificationType.schedule,
        title: '일정 알림',
        content: '내일 오후 2시에 코딩 스터디 모임이 있습니다.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: 4,
        userId: 1,
        type: NotificationType.evaluation,
        title: '모임 평가 요청',
        content: '"종로구 독서 모임"이 종료되었습니다. 팀원들의 매너를 평가해주세요.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: 5,
        userId: 1,
        type: NotificationType.system,
        title: '시스템 점검 안내',
        content: '내일 새벽 2시부터 4시까지 서버 정기 점검이 있을 예정입니다.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
    super.dispose();
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
