enum NotificationType {
  invite,
  chat,
  match,
  evaluation,
  schedule,
  system,
}

class NotificationItem {
  final int id;
  final int userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final dynamic metadata;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.isRead = false,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      userId: json['userId'],
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type?.toUpperCase()) {
      case 'INVITE':
        return NotificationType.invite;
      case 'CHAT':
        return NotificationType.chat;
      case 'MATCH':
        return NotificationType.match;
      case 'EVALUATION':
        return NotificationType.evaluation;
      case 'SCHEDULE':
        return NotificationType.schedule;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  NotificationItem copyWith({
    int? id,
    int? userId,
    NotificationType? type,
    String? title,
    String? content,
    bool? isRead,
    dynamic metadata,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
