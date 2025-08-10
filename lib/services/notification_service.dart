import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/todo.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      await _requestPermissions();

      _initialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific todo or home screen
    // This would typically involve using a navigation service or global navigator
  }

  // Schedule a notification for a todo
  static Future<void> scheduleNotification(Todo todo) async {
    if (!_initialized) await initialize();

    if (todo.notificationTime == null) return;

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'todo_notifications';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Todo Reminders';
      final channelDescription =
          dotenv.env['NOTIFICATION_CHANNEL_DESCRIPTION'] ??
              'Notifications for todo due dates and reminders';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: _getPriorityColor(todo.priority),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert todo ID to a unique integer for notification ID
      final notificationId = todo.id.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        _getNotificationTitle(todo),
        _getNotificationBody(todo),
        _convertToTZDateTime(todo.notificationTime!),
        notificationDetails,
        payload: todo.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Notification scheduled for todo: ${todo.title}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Schedule recurring notifications for daily/weekly reminders
  static Future<void> scheduleRecurringNotification({
    required String id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initialize();

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'todo_notifications';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Todo Reminders';
      final channelDescription =
          dotenv.env['NOTIFICATION_CHANNEL_DESCRIPTION'] ??
              'Notifications for todo due dates and reminders';

      const androidDetails = AndroidNotificationDetails(
        'recurring_notifications',
        'Recurring Reminders',
        channelDescription: 'Daily and weekly reminder notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = id.hashCode;

      await _notifications.periodicallyShow(
        notificationId,
        title,
        body,
        repeatInterval,
        notificationDetails,
        payload: id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('Recurring notification scheduled: $title');
    } catch (e) {
      debugPrint('Error scheduling recurring notification: $e');
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(String todoId) async {
    try {
      final notificationId = todoId.hashCode;
      await _notifications.cancel(notificationId);
      debugPrint('Notification cancelled for todo: $todoId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  // Show immediate notification
  static Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'todo_notifications';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Todo Reminders';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = id.hashCode;

      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload ?? id,
      );

      debugPrint('Immediate notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Helper methods
  static String _getNotificationTitle(Todo todo) {
    if (todo.isOverdue) {
      return '⚠️ Overdue: ${todo.title}';
    } else if (todo.isDueToday) {
      return '📅 Due Today: ${todo.title}';
    } else {
      return '⏰ Reminder: ${todo.title}';
    }
  }

  static String _getNotificationBody(Todo todo) {
    String body = '';

    if (todo.description.isNotEmpty) {
      body = todo.description;
    } else {
      body = 'Don\'t forget about this task!';
    }

    if (todo.dueDate != null) {
      final timeRemaining = todo.dueDate!.difference(DateTime.now());
      if (timeRemaining.inDays > 0) {
        body += '\n📅 Due in ${timeRemaining.inDays} days';
      } else if (timeRemaining.inHours > 0) {
        body += '\n⏰ Due in ${timeRemaining.inHours} hours';
      } else if (timeRemaining.inMinutes > 0) {
        body += '\n⏰ Due in ${timeRemaining.inMinutes} minutes';
      }
    }

    return body;
  }

  static Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: // High
        return Colors.red;
      case 2: // Medium
        return Colors.orange;
      case 3: // Low
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  static _convertToTZDateTime(DateTime dateTime) {
    // For simplicity, we'll use the local timezone
    // In a production app, you might want to use the timezone package
    return dateTime;
  }

  // Notification statistics
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final pending = await getPendingNotifications();
      return {
        'total': pending.length,
        'today': pending.where((notification) {
          // This is a simplified check - in production you'd parse the scheduled date
          return true; // placeholder
        }).length,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {'total': 0, 'today': 0};
    }
  }
}
