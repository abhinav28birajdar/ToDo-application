import 'dart:async';
import 'package:flutter/material.dart';
import '../services/real_time_notification_manager.dart';

class RealTimeNotificationWidget extends StatefulWidget {
  final Widget child;

  const RealTimeNotificationWidget({
    super.key,
    required this.child,
  });

  @override
  State<RealTimeNotificationWidget> createState() => _RealTimeNotificationWidgetState();
}

class _RealTimeNotificationWidgetState extends State<RealTimeNotificationWidget>
    with TickerProviderStateMixin {
  final RealTimeNotificationManager _notificationManager = RealTimeNotificationManager();
  StreamSubscription<String>? _notificationSubscription;
  
  final List<NotificationItem> _notifications = [];
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeIn,
    ));

    // Listen to notification stream
    _notificationSubscription = _notificationManager.notificationStream.listen(
      _handleNotification,
    );
  }

  void _handleNotification(String message) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      timestamp: DateTime.now(),
    );

    setState(() {
      _notifications.add(notification);
    });

    _animationController?.forward();

    // Auto-dismiss after 4 seconds
    Timer(const Duration(seconds: 4), () {
      _dismissNotification(notification.id);
    });
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });

    if (_notifications.isEmpty) {
      _animationController?.reverse();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_notifications.isNotEmpty) _buildNotificationOverlay(),
        ],
      ),
    );
  }

  Widget _buildNotificationOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation!,
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: Column(
                children: _notifications.map((notification) {
                  return _buildNotificationCard(notification);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getNotificationColor(notification.message),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _getNotificationIcon(notification.message),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _dismissNotification(notification.id),
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String message) {
    if (message.contains('completed') || message.contains('🎉')) {
      return Colors.green;
    } else if (message.contains('created') || message.contains('✅')) {
      return Colors.blue;
    } else if (message.contains('updated') || message.contains('🔄')) {
      return Colors.orange;
    } else if (message.contains('deleted') || message.contains('🗑️')) {
      return Colors.red;
    } else if (message.contains('overdue') || message.contains('⚠️')) {
      return Colors.red;
    } else if (message.contains('reminder') || message.contains('⏰')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  Widget _getNotificationIcon(String message) {
    IconData iconData;
    Color iconColor;

    if (message.contains('completed') || message.contains('🎉')) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else if (message.contains('created') || message.contains('✅')) {
      iconData = Icons.add_task;
      iconColor = Colors.blue;
    } else if (message.contains('updated') || message.contains('🔄')) {
      iconData = Icons.edit;
      iconColor = Colors.orange;
    } else if (message.contains('deleted') || message.contains('🗑️')) {
      iconData = Icons.delete;
      iconColor = Colors.red;
    } else if (message.contains('overdue') || message.contains('⚠️')) {
      iconData = Icons.warning;
      iconColor = Colors.red;
    } else if (message.contains('reminder') || message.contains('⏰')) {
      iconData = Icons.notifications;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.info;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class NotificationItem {
  final String id;
  final String message;
  final DateTime timestamp;

  NotificationItem({
    required this.id,
    required this.message,
    required this.timestamp,
  });
}