import 'dart:async';
import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';

class RealTimeNotificationManager {
  static final RealTimeNotificationManager _instance = RealTimeNotificationManager._internal();
  factory RealTimeNotificationManager() => _instance;
  RealTimeNotificationManager._internal();

  final NotificationService _notificationService = NotificationService.instance;
  final AudioService _audioService = AudioService();
  final StreamController<String> _notificationStreamController = StreamController<String>.broadcast();

  // Stream for real-time notification updates
  Stream<String> get notificationStream => _notificationStreamController.stream;

  /// Initialize the real-time notification manager
  Future<void> initialize() async {
    await _notificationService.initializeNotifications();
  }

  /// Show immediate completion notification with sound and visual feedback
  Future<void> showTaskCompletionNotification(Todo todo) async {
    try {
      // Play completion sound immediately
      await _audioService.playNotificationSound();

      // Show system notification
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'completed',
        description: todo.description.isNotEmpty ? todo.description : null,
      );

      // Emit real-time notification for UI updates
      _notificationStreamController.add('Task "${todo.title}" completed! 🎉');

      debugPrint('Real-time completion notification sent for: ${todo.title}');
    } catch (e) {
      debugPrint('Error showing completion notification: $e');
    }
  }

  /// Show real-time reminder notification
  Future<void> showTaskReminderNotification(Todo todo) async {
    try {
      // Play alarm sound for reminders
      await _audioService.playAlarmSound();

      // Show system notification
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'reminder',
        description: _getReminderMessage(todo),
      );

      // Emit real-time notification for UI updates
      _notificationStreamController.add('Reminder: "${todo.title}" is due soon! ⏰');

      debugPrint('Real-time reminder notification sent for: ${todo.title}');
    } catch (e) {
      debugPrint('Error showing reminder notification: $e');
    }
  }

  /// Show task creation notification
  Future<void> showTaskCreatedNotification(Todo todo) async {
    try {
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'created',
        description: todo.description.isNotEmpty ? todo.description : null,
      );

      _notificationStreamController.add('New task created: "${todo.title}" ✅');
    } catch (e) {
      debugPrint('Error showing creation notification: $e');
    }
  }

  /// Show task update notification
  Future<void> showTaskUpdatedNotification(Todo todo) async {
    try {
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'updated',
        description: todo.description.isNotEmpty ? todo.description : null,
      );

      _notificationStreamController.add('Task updated: "${todo.title}" 🔄');
    } catch (e) {
      debugPrint('Error showing update notification: $e');
    }
  }

  /// Show task deletion notification
  Future<void> showTaskDeletedNotification(Todo todo) async {
    try {
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'deleted',
        description: 'Task has been removed',
      );

      _notificationStreamController.add('Task deleted: "${todo.title}" 🗑️');
    } catch (e) {
      debugPrint('Error showing deletion notification: $e');
    }
  }

  /// Check for due tasks and send reminders
  Future<void> checkDueTasksAndNotify(List<Todo> todos) async {
    final now = DateTime.now();
    
    for (final todo in todos) {
      if (todo.isCompleted || todo.dueDate == null) continue;

      // Check if task is due within the next hour
      final timeDifference = todo.dueDate!.difference(now);
      
      if (timeDifference.inMinutes <= 60 && timeDifference.inMinutes > 0) {
        await showTaskReminderNotification(todo);
      }
      
      // Check if task is overdue
      else if (timeDifference.inMinutes < 0 && timeDifference.inHours >= -24) {
        await _showOverdueNotification(todo);
      }
    }
  }

  /// Show overdue task notification
  Future<void> _showOverdueNotification(Todo todo) async {
    try {
      await _audioService.playAlarmSound();
      
      await _notificationService.showTaskUpdateNotification(
        taskId: todo.id,
        title: todo.title,
        action: 'overdue',
        description: 'This task is overdue! ⚠️',
      );

      _notificationStreamController.add('Overdue task: "${todo.title}" ⚠️');
    } catch (e) {
      debugPrint('Error showing overdue notification: $e');
    }
  }

  /// Show daily summary notification
  Future<void> showDailySummary({
    required int totalTasks,
    required int completedTasks,
    required int pendingTasks,
  }) async {
    try {
      final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
      
      await _notificationService.showDailySummaryNotification(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        dueTodayTasks: pendingTasks,
        pendingTasks: pendingTasks,
      );

      _notificationStreamController.add(
        'Daily Summary: $completedTasks/$totalTasks tasks completed ($completionRate%) 📊'
      );
    } catch (e) {
      debugPrint('Error showing daily summary: $e');
    }
  }

  /// Show achievement notification
  Future<void> showAchievementNotification(String achievement) async {
    try {
      await _audioService.playNotificationSound();
      
      _notificationStreamController.add('Achievement unlocked: $achievement 🏆');
    } catch (e) {
      debugPrint('Error showing achievement notification: $e');
    }
  }

  /// Get reminder message based on todo details
  String _getReminderMessage(Todo todo) {
    if (todo.dueDate == null) return 'Reminder for your task';

    final now = DateTime.now();
    final difference = todo.dueDate!.difference(now);

    if (difference.inMinutes <= 0) {
      return 'This task is due now!';
    } else if (difference.inMinutes <= 15) {
      return 'Due in ${difference.inMinutes} minutes';
    } else if (difference.inHours <= 1) {
      return 'Due in about ${difference.inMinutes} minutes';
    } else if (difference.inHours <= 24) {
      return 'Due in ${difference.inHours} hours';
    } else {
      return 'Due on ${todo.dueDate!.day}/${todo.dueDate!.month}';
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}