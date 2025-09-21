import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  // Static instance for singleton pattern
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._internal();

  NotificationService._internal()
      : _notifications = FlutterLocalNotificationsPlugin();

  factory NotificationService(
      {FlutterLocalNotificationsPlugin? notificationsPlugin}) {
    return _instance ??= NotificationService._internal();
  }

  // Initialize the notification service
  Future<void> initializeNotifications() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

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
  Future<void> _requestPermissions() async {
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
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation will be handled by the provider
  }

  // Schedule a notification for a task
  Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized) await initializeNotifications();
    if (task.notificationTime == null) return;

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'task_notifications';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Task Reminders';
      final channelDescription =
          dotenv.env['NOTIFICATION_CHANNEL_DESCRIPTION'] ??
              'Notifications for task due dates and reminders';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: _getPriorityColor(task.priority),
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

      // Convert task ID to a unique integer for notification ID
      final notificationId = task.id.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        _getNotificationTitle(task),
        _getNotificationBody(task),
        _convertToTZDateTime(task.notificationTime!),
        notificationDetails,
        payload: task.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(task.recurrence),
      );

      debugPrint('Notification scheduled for task: ${task.title}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Get DateTimeComponents for recurring notifications
  DateTimeComponents? _getDateTimeComponents(String? recurrence) {
    if (recurrence == null) return null;

    switch (recurrence) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      case 'yearly':
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  // Schedule recurring notifications for daily/weekly reminders
  Future<void> scheduleRecurringNotification({
    required String id,
    required String title,
    required String body,
    required String recurrence,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initializeNotifications();

    try {
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

      // Handle different recurrence patterns
      final tz.TZDateTime scheduledTZDateTime =
          _convertToTZDateTime(scheduledDate);
      DateTimeComponents? dateTimeComponents =
          _getDateTimeComponents(recurrence);

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZDateTime,
        notificationDetails,
        payload: id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: dateTimeComponents,
      );

      debugPrint('Recurring notification scheduled: $title ($recurrence)');
    } catch (e) {
      debugPrint('Error scheduling recurring notification: $e');
    }
  }

  // Real-time notification for task updates
  Future<void> showTaskUpdateNotification({
    required String taskId,
    required String title,
    required String action, // 'created', 'updated', 'completed', 'deleted'
    String? description,
  }) async {
    if (!_initialized) await initializeNotifications();

    String notificationTitle;
    String notificationBody;
    String emoji;

    switch (action) {
      case 'created':
        emoji = '✅';
        notificationTitle = 'New Task Added';
        notificationBody = '$emoji $title has been created';
        break;
      case 'updated':
        emoji = '🔄';
        notificationTitle = 'Task Updated';
        notificationBody = '$emoji $title has been updated';
        break;
      case 'completed':
        emoji = '🎉';
        notificationTitle = 'Task Completed!';
        notificationBody = '$emoji Congratulations! You completed: $title';
        break;
      case 'deleted':
        emoji = '🗑️';
        notificationTitle = 'Task Deleted';
        notificationBody = '$emoji $title has been deleted';
        break;
      default:
        emoji = '📝';
        notificationTitle = 'Task Update';
        notificationBody = '$emoji $title was $action';
    }

    if (description != null && description.isNotEmpty) {
      notificationBody += '\n$description';
    }

    await showNotification(
      id: 'task_update_$taskId',
      title: notificationTitle,
      body: notificationBody,
      payload: 'task:$taskId',
    );
  }

  // Real-time notification for sync status
  Future<void> showSyncNotification({
    required String status, // 'syncing', 'synced', 'error'
    int? syncedCount,
    String? errorMessage,
  }) async {
    if (!_initialized) await initializeNotifications();

    String title;
    String body;
    String emoji;

    switch (status) {
      case 'syncing':
        emoji = '🔄';
        title = 'Syncing Data';
        body = '$emoji Syncing your tasks with the cloud...';
        break;
      case 'synced':
        emoji = '✅';
        title = 'Sync Complete';
        body = syncedCount != null
            ? '$emoji Successfully synced $syncedCount items'
            : '$emoji All data is up to date';
        break;
      case 'error':
        emoji = '⚠️';
        title = 'Sync Error';
        body = errorMessage != null
            ? '$emoji $errorMessage'
            : '$emoji Failed to sync data. Please try again.';
        break;
      default:
        emoji = '📡';
        title = 'Sync Update';
        body = '$emoji Sync status: $status';
    }

    await showNotification(
      id: 'sync_$status',
      title: title,
      body: body,
      payload: 'sync:$status',
    );
  }

  // Real-time notification for overdue tasks
  Future<void> showOverdueTasksNotification(List<Task> overdueTasks) async {
    if (!_initialized) await initializeNotifications();
    if (overdueTasks.isEmpty) return;

    String title;
    String body;

    if (overdueTasks.length == 1) {
      title = '⚠️ Overdue Task';
      body = 'You have an overdue task: ${overdueTasks.first.title}';
    } else {
      title = '⚠️ Overdue Tasks';
      body =
          'You have ${overdueTasks.length} overdue tasks that need attention';
    }

    await showNotification(
      id: 'overdue_tasks',
      title: title,
      body: body,
      payload: 'overdue_tasks',
    );
  }

  // Daily summary notification
  Future<void> showDailySummaryNotification({
    required int totalTasks,
    required int completedTasks,
    required int pendingTasks,
    required int dueTodayTasks,
  }) async {
    if (!_initialized) await initializeNotifications();

    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    String emoji = '📊';
    if (completionRate >= 80)
      emoji = '🎉';
    else if (completionRate >= 60)
      emoji = '👍';
    else if (completionRate >= 40) emoji = '📈';

    final title = '$emoji Daily Summary';
    final body =
        'Completed: $completedTasks/$totalTasks tasks ($completionRate%)'
        '${dueTodayTasks > 0 ? '\n📅 $dueTodayTasks tasks due today' : ''}';

    await showNotification(
      id: 'daily_summary',
      title: title,
      body: body,
      payload: 'daily_summary',
    );
  }

  // Weekly achievement notification
  Future<void> showWeeklyAchievementNotification({
    required int weeklyCompleted,
    required int weeklyTarget,
  }) async {
    if (!_initialized) await initializeNotifications();

    String title;
    String body;
    String emoji;

    if (weeklyCompleted >= weeklyTarget) {
      emoji = '🏆';
      title = 'Weekly Goal Achieved!';
      body =
          '$emoji Congratulations! You completed $weeklyCompleted tasks this week!';
    } else {
      emoji = '💪';
      title = 'Keep Going!';
      body =
          '$emoji You completed $weeklyCompleted/$weeklyTarget tasks this week. Almost there!';
    }

    await showNotification(
      id: 'weekly_achievement',
      title: title,
      body: body,
      payload: 'weekly_achievement',
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(String id) async {
    try {
      final notificationId = id.hashCode;
      await _notifications.cancel(notificationId);
      debugPrint('Notification cancelled for id: $id');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initializeNotifications();

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'task_notifications';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Task Reminders';

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

  // Schedule notification for Todo object
  Future<void> scheduleTodoNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initializeNotifications();

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

      // Schedule notification
      await _notifications.zonedSchedule(
        id.hashCode,
        '⏰ Todo Reminder',
        title,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Todo notification scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling todo notification: $e');
    }
  }

  // Helper methods
  String _getNotificationTitle(Task task) {
    if (task.isOverdue) {
      return '⚠️ Overdue: ${task.title}';
    } else if (task.isDueToday) {
      return '📅 Due Today: ${task.title}';
    } else {
      return '⏰ Reminder: ${task.title}';
    }
  }

  String _getNotificationBody(Task task) {
    String body = '';

    if (task.description.isNotEmpty) {
      body = task.description;
    } else {
      body = 'Don\'t forget about this task!';
    }

    if (task.dueDate != null) {
      final timeRemaining = task.dueDate!.difference(DateTime.now());
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

  Color _getPriorityColor(int priority) {
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

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    // If the scheduledDate is in the past, add a day to schedule it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final pending = await getPendingNotifications();

      return {
        'total': pending.length,
        'today':
            pending.length, // In a real app, you would parse the scheduled date
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {'total': 0, 'today': 0};
    }
  }

  // Schedule a notification for notes with reminders
  Future<void> scheduleNoteReminder(
      String noteId, String title, DateTime reminderTime) async {
    if (!_initialized) await initializeNotifications();

    try {
      final channelId =
          dotenv.env['NOTIFICATION_CHANNEL_ID'] ?? 'note_reminders';
      final channelName =
          dotenv.env['NOTIFICATION_CHANNEL_NAME'] ?? 'Note Reminders';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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

      final notificationId = noteId.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        '📝 Note Reminder: $title',
        'You asked to be reminded about this note.',
        _convertToTZDateTime(reminderTime),
        notificationDetails,
        payload: 'note:$noteId',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Note reminder scheduled for: $title');
    } catch (e) {
      debugPrint('Error scheduling note reminder: $e');
    }
  }
}
