import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance {
    _instance ??= FirebaseNotificationService._internal();
    return _instance!;
  }

  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  // Notification settings
  bool _notificationsEnabled = true;
  String _selectedSound = 'default';
  bool _vibrationEnabled = true;
  int _reminderMinutes = 15;

  // Available notification sounds
  static const List<String> availableSounds = [
    'default',
    'alarm_gentle',
    'alarm_classic',
    'chime',
    'bell',
    'notification',
  ];

  // Getters
  bool get initialized => _initialized;
  String? get fcmToken => _fcmToken;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedSound => _selectedSound;
  bool get vibrationEnabled => _vibrationEnabled;
  int get reminderMinutes => _reminderMinutes;

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        debugPrint(
            '⚠️ Firebase not initialized - running without Firebase features');
        _initialized = true;
        return;
      }

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Load saved settings
      await _loadSettings();

      _initialized = true;
      debugPrint('🔔 Firebase Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Notification Service: $e');
      // Continue without Firebase - app will still work with local notifications
      _initialized = true;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      debugPrint(
          '🔔 Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      // Continue without Firebase permissions, use local notifications only
      _notificationsEnabled = true;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task due dates and reminders',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'task_alarms',
      'Task Alarms',
      description: 'Alarm notifications for urgent tasks',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarm_classic'),
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        // TODO: Send updated token to your backend
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    try {
      // Handle foreground messages
      _onMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📱 Received foreground message: ${message.messageId}');
        _showLocalNotification(message);
      });

      // Handle background message tap
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            '📱 App opened from background message: ${message.messageId}');
        _handleMessageClick(message);
      });

      // Handle terminated app message tap
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          debugPrint(
              '📱 App opened from terminated state message: ${message.messageId}');
          _handleMessageClick(message);
        }
      });
    } catch (e) {
      debugPrint('❌ Error setting up message handlers: $e');
      // Continue without Firebase message handlers
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_notificationsEnabled) return;

    final notification = message.notification;
    if (notification == null) return;

    // Determine notification channel and sound
    String channelId = 'task_reminders';
    String soundFile = 'notification';

    if (message.data['type'] == 'alarm' || message.data['priority'] == 'high') {
      channelId = 'task_alarms';
      soundFile =
          _selectedSound == 'default' ? 'alarm_classic' : _selectedSound;
    } else {
      soundFile = _selectedSound == 'default' ? 'notification' : _selectedSound;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'task_alarms' ? 'Task Alarms' : 'Task Reminders',
      channelDescription: channelId == 'task_alarms'
          ? 'Alarm notifications for urgent tasks'
          : 'Notifications for task due dates and reminders',
      importance: channelId == 'task_alarms' ? Importance.max : Importance.high,
      priority: channelId == 'task_alarms' ? Priority.max : Priority.high,
      sound: RawResourceAndroidNotificationSound(soundFile),
      enableVibration: _vibrationEnabled,
      playSound: true,
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

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('📱 Notification clicked: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Handle message click navigation
  void _handleMessageClick(RemoteMessage message) {
    // TODO: Navigate to appropriate screen based on message data
    debugPrint('📱 Handling message click: ${message.data}');
  }

  /// Schedule a task reminder notification
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String description,
    required DateTime scheduledTime,
    bool isAlarm = false,
  }) async {
    if (!_initialized || !_notificationsEnabled) return;

    try {
      // Calculate notification time
      final notificationTime =
          scheduledTime.subtract(Duration(minutes: _reminderMinutes));

      if (notificationTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Notification time is in the past, scheduling for now');
        // Schedule for immediate delivery if the time has passed
        await _scheduleImmediateNotification(
            taskId, title, description, isAlarm);
        return;
      }

      final channelId = isAlarm ? 'task_alarms' : 'task_reminders';
      final soundFile = isAlarm
          ? (_selectedSound == 'default' ? 'alarm_classic' : _selectedSound)
          : (_selectedSound == 'default' ? 'notification' : _selectedSound);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        isAlarm ? 'Task Alarms' : 'Task Reminders',
        channelDescription: isAlarm
            ? 'Alarm notifications for urgent tasks'
            : 'Notifications for task due dates and reminders',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        sound: RawResourceAndroidNotificationSound(soundFile),
        enableVibration: _vibrationEnabled,
        playSound: true,
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

      await _localNotifications.zonedSchedule(
        taskId.hashCode,
        title,
        description,
        _convertToTZDateTime(notificationTime),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task:$taskId',
      );

      debugPrint(
          '📅 Scheduled ${isAlarm ? 'alarm' : 'reminder'} for task: $title at $notificationTime');
    } catch (e) {
      debugPrint('❌ Error scheduling task reminder: $e');
    }
  }

  /// Schedule immediate notification
  Future<void> _scheduleImmediateNotification(
      String taskId, String title, String description, bool isAlarm) async {
    final channelId = isAlarm ? 'task_alarms' : 'task_reminders';
    final soundFile = isAlarm
        ? (_selectedSound == 'default' ? 'alarm_classic' : _selectedSound)
        : (_selectedSound == 'default' ? 'notification' : _selectedSound);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isAlarm ? 'Task Alarms' : 'Task Reminders',
      channelDescription: isAlarm
          ? 'Alarm notifications for urgent tasks'
          : 'Notifications for task due dates and reminders',
      importance: isAlarm ? Importance.max : Importance.high,
      priority: isAlarm ? Priority.max : Priority.high,
      sound: RawResourceAndroidNotificationSound(soundFile),
      enableVibration: _vibrationEnabled,
      playSound: true,
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

    await _localNotifications.show(
      taskId.hashCode,
      title,
      description,
      notificationDetails,
      payload: 'task:$taskId',
    );
  }

  /// Convert DateTime to TZDateTime
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // This is a simplified version - you'd need to import timezone package
    return dateTime;
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String taskId) async {
    await _localNotifications.cancel(taskId.hashCode);
    debugPrint('🚫 Cancelled notification for task: $taskId');
  }

  /// Update notification settings
  Future<void> updateSettings({
    bool? notificationsEnabled,
    String? selectedSound,
    bool? vibrationEnabled,
    int? reminderMinutes,
  }) async {
    if (notificationsEnabled != null)
      _notificationsEnabled = notificationsEnabled;
    if (selectedSound != null) _selectedSound = selectedSound;
    if (vibrationEnabled != null) _vibrationEnabled = vibrationEnabled;
    if (reminderMinutes != null) _reminderMinutes = reminderMinutes;

    await _saveSettings();
    debugPrint('⚙️ Notification settings updated');
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled =
        prefs.getBool('firebase_notifications_enabled') ?? true;
    _selectedSound =
        prefs.getString('firebase_notification_sound') ?? 'default';
    _vibrationEnabled = prefs.getBool('firebase_vibration_enabled') ?? true;
    _reminderMinutes = prefs.getInt('firebase_reminder_minutes') ?? 15;
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'firebase_notifications_enabled', _notificationsEnabled);
    await prefs.setString('firebase_notification_sound', _selectedSound);
    await prefs.setBool('firebase_vibration_enabled', _vibrationEnabled);
    await prefs.setInt('firebase_reminder_minutes', _reminderMinutes);
  }

  /// Subscribe to topic for general notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
      // Continue without topic subscription - local notifications will still work
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('📢 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
      // Continue without topic unsubscription
    }
  }

  /// Test notification
  Future<void> testNotification({bool isAlarm = false}) async {
    await _scheduleImmediateNotification(
      'test',
      isAlarm ? '🚨 Test Alarm' : '🔔 Test Notification',
      'This is a test ${isAlarm ? 'alarm' : 'notification'} to verify your settings.',
      isAlarm,
    );
  }

  /// Dispose resources
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _initialized = false;
  }
}

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message received: ${message.messageId}');
}
