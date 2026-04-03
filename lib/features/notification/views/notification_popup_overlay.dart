import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../viewmodels/notification_view_model.dart';

class NotificationPopupOverlay extends StatefulWidget {
  final Widget child;

  const NotificationPopupOverlay({super.key, required this.child});

  @override
  State<NotificationPopupOverlay> createState() => _NotificationPopupOverlayState();
}

class _NotificationPopupOverlayState extends State<NotificationPopupOverlay> {
  StreamSubscription? _subscription;
  OverlayEntry? _overlayEntry;
  final List<NotificationItem> _queue = [];
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<NotificationViewModel>();
      _subscription = viewModel.notificationStream.listen(_showPopup);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showPopup(NotificationItem item) {
    if (_isShowing) {
      _queue.add(item);
      return;
    }
    _display(item);
  }

  Future<void> _display(NotificationItem item) async {
    _isShowing = true;
    _overlayEntry = _createOverlayEntry(item);
    Overlay.of(context).insert(_overlayEntry!);

    await Future.delayed(const Duration(seconds: 4));

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _isShowing = false;
    if (_queue.isNotEmpty) {
      _display(_queue.removeAt(0));
    }
  }

  OverlayEntry _createOverlayEntry(NotificationItem item) {
    return OverlayEntry(
      builder: (context) => _NotificationPopup(
        item: item,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _isShowing = false;
          if (_queue.isNotEmpty) {
            _display(_queue.removeAt(0));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NotificationPopup extends StatefulWidget {
  final NotificationItem item;
  final VoidCallback onDismiss;

  const _NotificationPopup({required this.item, required this.onDismiss});

  @override
  State<_NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<_NotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      top: mq.padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(widget.item.type),
                    color: cs.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.item.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.invite:
        return Icons.mail_outline;
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.match:
        return Icons.favorite_border;
      default:
        return Icons.notifications_none;
    }
  }
}
