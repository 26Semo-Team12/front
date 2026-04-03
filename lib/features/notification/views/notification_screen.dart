import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../viewmodels/notification_view_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.invite:    return Icons.mail_outline;
      case NotificationType.chat:      return Icons.chat_bubble_outline;
      case NotificationType.match:     return Icons.people_outline;
      case NotificationType.evaluation:return Icons.star_border;
      case NotificationType.schedule:  return Icons.calendar_today_outlined;
      case NotificationType.system:    return Icons.info_outline;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.invite:    return Colors.blue;
      case NotificationType.chat:      return Colors.green;
      case NotificationType.evaluation:return Colors.orange;
      case NotificationType.schedule:  return Colors.purple;
      case NotificationType.match:     return Colors.teal;
      case NotificationType.system:    return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();
    final notifications = viewModel.notifications;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Text('새로운 알림이 없습니다.',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))))
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.onSurface.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final iconColor = _getIconColor(item.type);
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) => viewModel.removeNotification(item.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Material(
                        color: item.isRead
                            ? cs.surface
                            : const Color(0xFFD6706D).withValues(alpha: 0.07),
                        child: InkWell(
                          onTap: () => viewModel.onNotificationTap(context, item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: iconColor.withValues(alpha: 0.12),
                                  child: Icon(_getIconData(item.type),
                                      size: 20, color: iconColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: item.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.content,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurface.withValues(
                                              alpha: item.isRead ? 0.5 : 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(item.createdAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
