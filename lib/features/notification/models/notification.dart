enum NotificationType {
  invite,
  chat,
  match,
  evaluation,
  schedule,
  system,
}

class NotificationItem {
  final String id;
  final int userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    int? userId,
    NotificationType? type,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
