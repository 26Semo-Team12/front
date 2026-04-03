import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnread => _notifications.any((n) => !n.isRead);

  NotificationViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    _notifications = [
      NotificationItem(
        id: '1',
        userId: 1,
        type: NotificationType.invite,
        title: '새로운 모임 초대',
        content: '이번 주말 한강 디자이너 모임에 초대되었습니다.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationItem(
        id: '2',
        userId: 1,
        type: NotificationType.chat,
        title: '새로운 메시지',
        content: '마포구 맛집 탐방 모임방에서 메시지가 도착했습니다.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationItem(
        id: '3',
        userId: 1,
        type: NotificationType.schedule,
        title: '일정 알림',
        content: '내일 오후 2시에 코딩 스터디 모임이 있습니다.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '4',
        userId: 1,
        type: NotificationType.evaluation,
        title: '모임 평가 요청',
        content: '"종로구 독서 모임"이 종료되었습니다. 팀원들의 매너를 평가해주세요.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: '5',
        userId: 1,
        type: NotificationType.system,
        title: '시스템 점검 안내',
        content: '내일 새벽 2시부터 4시까지 서버 정기 점검이 있을 예정입니다.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
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
