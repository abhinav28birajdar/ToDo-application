import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final NotificationService _notificationService = NotificationService.instance;
  final AudioService _audioService = AudioService();
  final StreamController<String> _alarmStreamController =
      StreamController<String>.broadcast();

  final List<AlarmItem> _activeAlarms = [];
  String? _currentlyPlayingAlarmId;
  Timer? _alarmTimer;

  // Stream for alarm updates
  Stream<String> get alarmStream => _alarmStreamController.stream;

  /// Initialize the alarm service
  Future<void> initialize() async {
    await _notificationService.initializeNotifications();
    debugPrint('Alarm service initialized');
  }

  /// Schedule a new alarm for a task
  Future<void> scheduleTaskAlarm(Task task) async {
    if (task.dueDate == null) return;

    try {
      final alarmId = 'alarm_${task.id}';
      final alarmItem = AlarmItem(
        id: alarmId,
        taskId: task.id,
        title: task.title,
        scheduledTime: task.dueDate!,
        isRecurring: false,
        soundPath: 'assets/sounds/alarm.mp3',
      );

      // Add to active alarms
      _activeAlarms.add(alarmItem);

      // Schedule the notification
      await _notificationService.scheduleTodoNotification(
        id: alarmId,
        title: '⏰ Alarm: ${task.title}',
        body: 'Your task is due now!',
        scheduledDate: task.dueDate!,
      );

      _alarmStreamController.add('Alarm scheduled for: ${task.title}');
      debugPrint('Alarm scheduled for task: ${task.title} at ${task.dueDate}');
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
    }
  }

  /// Schedule a custom alarm
  Future<void> scheduleCustomAlarm({
    required String title,
    required DateTime scheduledTime,
    required String soundPath,
    bool isRecurring = false,
    String? description,
  }) async {
    try {
      final alarmId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final alarmItem = AlarmItem(
        id: alarmId,
        taskId: null,
        title: title,
        scheduledTime: scheduledTime,
        isRecurring: isRecurring,
        soundPath: soundPath,
        description: description,
      );

      _activeAlarms.add(alarmItem);

      await _notificationService.scheduleTodoNotification(
        id: alarmId,
        title: '⏰ $title',
        body: description ?? 'Alarm notification',
        scheduledDate: scheduledTime,
      );

      _alarmStreamController.add('Custom alarm scheduled: $title');
      debugPrint('Custom alarm scheduled: $title at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling custom alarm: $e');
    }
  }

  /// Trigger alarm (called when notification fires)
  Future<void> triggerAlarm(String alarmId) async {
    try {
      final alarm = _activeAlarms.firstWhere((a) => a.id == alarmId);
      _currentlyPlayingAlarmId = alarmId;

      // Play alarm sound
      await _audioService.playAlarmSound();

      // Show alarm dialog or notification
      _alarmStreamController.add('🔔 ALARM: ${alarm.title}');

      // Set up auto-stop after 60 seconds if not manually stopped
      _alarmTimer = Timer(const Duration(seconds: 60), () {
        stopAlarm(alarmId);
      });

      debugPrint('Alarm triggered: ${alarm.title}');
    } catch (e) {
      debugPrint('Error triggering alarm: $e');
    }
  }

  /// Stop a specific alarm
  Future<void> stopAlarm(String alarmId) async {
    try {
      await _notificationService.cancelNotification(alarmId);
      _activeAlarms.removeWhere((alarm) => alarm.id == alarmId);

      // If this alarm is currently playing, stop the audio
      if (_currentlyPlayingAlarmId == alarmId) {
        await _audioService.stopAlarm();
        _currentlyPlayingAlarmId = null;
        _alarmTimer?.cancel();
        _alarmTimer = null;
      }

      _alarmStreamController.add('Alarm stopped: $alarmId');
      debugPrint('Alarm stopped: $alarmId');
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  /// Stop all currently playing alarms
  Future<void> stopAllAlarms() async {
    try {
      await _audioService.stopAlarm();
      _currentlyPlayingAlarmId = null;
      _alarmTimer?.cancel();
      _alarmTimer = null;

      // Cancel all active alarm notifications
      for (final alarm in _activeAlarms) {
        await _notificationService.cancelNotification(alarm.id);
      }

      _alarmStreamController.add('All alarms stopped');
      debugPrint('All alarms stopped');
    } catch (e) {
      debugPrint('Error stopping all alarms: $e');
    }
  }

  /// Snooze alarm for specified minutes
  Future<void> snoozeAlarm(String alarmId, int snoozeMinutes) async {
    try {
      final alarmIndex = _activeAlarms.indexWhere((a) => a.id == alarmId);
      if (alarmIndex == -1) return;

      final alarm = _activeAlarms[alarmIndex];
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));

      // Stop current alarm
      await stopAlarm(alarmId);

      // Schedule snoozed alarm
      final snoozedAlarm = AlarmItem(
        id: '${alarmId}_snooze_${DateTime.now().millisecondsSinceEpoch}',
        taskId: alarm.taskId,
        title: '${alarm.title} (Snoozed)',
        scheduledTime: snoozeTime,
        isRecurring: false,
        soundPath: alarm.soundPath,
        description: alarm.description,
      );

      _activeAlarms.add(snoozedAlarm);

      await _notificationService.scheduleTodoNotification(
        id: snoozedAlarm.id,
        title: '⏰ ${snoozedAlarm.title}',
        body: snoozedAlarm.description ?? 'Snoozed alarm',
        scheduledDate: snoozeTime,
      );

      _alarmStreamController.add('Alarm snoozed for $snoozeMinutes minutes');
      debugPrint('Alarm snoozed: ${alarm.title} for $snoozeMinutes minutes');
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
    }
  }

  /// Cancel a scheduled alarm
  Future<void> cancelAlarm(String alarmId) async {
    try {
      await _notificationService.cancelNotification(alarmId);
      _activeAlarms.removeWhere((alarm) => alarm.id == alarmId);

      _alarmStreamController.add('Alarm cancelled: $alarmId');
      debugPrint('Alarm cancelled: $alarmId');
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
    }
  }

  /// Get all active alarms
  List<AlarmItem> get activeAlarms => List.unmodifiable(_activeAlarms);

  /// Check if an alarm is currently playing
  bool get isAlarmPlaying => _currentlyPlayingAlarmId != null;

  /// Get the currently playing alarm ID
  String? get currentlyPlayingAlarmId => _currentlyPlayingAlarmId;

  /// Get the currently playing alarm
  AlarmItem? get currentlyPlayingAlarm {
    if (_currentlyPlayingAlarmId == null) return null;
    try {
      return _activeAlarms.firstWhere((a) => a.id == _currentlyPlayingAlarmId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _alarmTimer?.cancel();
    _alarmStreamController.close();
  }
}

class AlarmItem {
  final String id;
  final String? taskId;
  final String title;
  final DateTime scheduledTime;
  final bool isRecurring;
  final String soundPath;
  final String? description;

  AlarmItem({
    required this.id,
    this.taskId,
    required this.title,
    required this.scheduledTime,
    required this.isRecurring,
    required this.soundPath,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'scheduled_time': scheduledTime.toIso8601String(),
      'is_recurring': isRecurring,
      'sound_path': soundPath,
      'description': description,
    };
  }

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    return AlarmItem(
      id: json['id'],
      taskId: json['task_id'],
      title: json['title'],
      scheduledTime: DateTime.parse(json['scheduled_time']),
      isRecurring: json['is_recurring'] ?? false,
      soundPath: json['sound_path'] ?? 'assets/sounds/alarm.mp3',
      description: json['description'],
    );
  }
}
