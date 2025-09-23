import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Add some sample notifications - in a real app, these would come from a service
    final now = DateTime.now();
    _notifications.addAll([
      NotificationItem(
        id: '1',
        title: '🔔 Task Reminder',
        message: 'Complete your daily workout',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: NotificationType.reminder,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: '✅ Task Completed',
        message: 'You completed "Review project documents"',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: NotificationType.completion,
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: '🚨 Urgent Task',
        message: 'Meeting with client in 30 minutes',
        timestamp: now.subtract(const Duration(minutes: 30)),
        type: NotificationType.urgent,
        isRead: false,
      ),
      NotificationItem(
        id: '4',
        title: '📝 New Note Added',
        message: 'You added a new note: "Shopping list"',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.note,
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: '⏰ Daily Goal',
        message: 'You have 3 tasks remaining for today',
        timestamp: now.subtract(const Duration(hours: 8)),
        type: NotificationType.goal,
        isRead: false,
      ),
    ]);
    setState(() {});
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.completion:
        return Colors.green;
      case NotificationType.note:
        return Colors.purple;
      case NotificationType.goal:
        return Colors.orange;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Icons.warning_amber_rounded;
      case NotificationType.reminder:
        return Icons.schedule;
      case NotificationType.completion:
        return Icons.check_circle;
      case NotificationType.note:
        return Icons.note_add;
      case NotificationType.goal:
        return Icons.track_changes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.primaryColor,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marked all as read'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Mark all read',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Notifications'),
                  content: const Text('Are you sure you want to clear all notifications?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                setState(() {
                  _notifications.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All notifications cleared'),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Text(
                    'You\'re all caught up!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification, theme);
              },
            ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, ThemeData theme) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.red.shade400,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _notifications.insert(
                    _notifications.length,
                    notification,
                  );
                });
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? theme.cardColor 
              : theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead 
              ? null 
              : Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _getTimeAgo(notification.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: notification.isRead 
              ? null 
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            if (!notification.isRead) {
              setState(() {
                notification.isRead = true;
              });
            }
          },
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType {
  urgent,
  reminder,
  completion,
  note,
  goal,
}