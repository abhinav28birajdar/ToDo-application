import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  DateTime? completedDate;
  DateTime? notificationTime;
  bool isCompleted;
  int priority; // 1: High, 2: Medium, 3: Low
  String? categoryId;
  String? userId;
  String? recurrence; // daily, weekly, monthly, yearly, or null for one-time
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.completedDate,
    this.notificationTime,
    this.isCompleted = false,
    this.priority = 2,
    this.categoryId,
    this.userId,
    this.recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Creates a copy of the task with specified fields updated
  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? completedDate,
    DateTime? notificationTime,
    bool? isCompleted,
    int? priority,
    String? categoryId,
    String? userId,
    String? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      notificationTime: notificationTime ?? this.notificationTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Create a Task from a map/JSON object
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  // Convert Task to a map/JSON object for database storage
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  // For Supabase format
  Map<String, dynamic> toSupabase() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (dueDate != null) {
      data['due_date'] = dueDate!.toIso8601String();
    }

    if (completedDate != null) {
      data['completed_date'] = completedDate!.toIso8601String();
    }

    if (notificationTime != null) {
      data['notification_time'] = notificationTime!.toIso8601String();
    }

    if (categoryId != null) {
      data['category_id'] = categoryId;
    }

    if (recurrence != null) {
      data['recurrence'] = recurrence;
    }

    return data;
  }

  // Create a Task from Supabase
  factory Task.fromSupabase(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      completedDate: map['completed_date'] != null
          ? DateTime.parse(map['completed_date'] as String)
          : null,
      notificationTime: map['notification_time'] != null
          ? DateTime.parse(map['notification_time'] as String)
          : null,
      isCompleted: map['is_completed'] as bool? ?? false,
      priority: map['priority'] as int? ?? 2,
      categoryId: map['category_id'] as String?,
      userId: map['user_id'] as String?,
      recurrence: map['recurrence'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Computed properties
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isUpcoming {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final nextWeek = DateTime(now.year, now.month, now.day + 7);
    return dueDate!.isAfter(tomorrow) && dueDate!.isBefore(nextWeek);
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day) {
      return 'Today, ${DateFormat('h:mm a').format(dueDate!)}';
    }

    if (dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day) {
      return 'Tomorrow, ${DateFormat('h:mm a').format(dueDate!)}';
    }

    if (dueDate!.year == yesterday.year &&
        dueDate!.month == yesterday.month &&
        dueDate!.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dueDate!)}';
    }

    if (dueDate!.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(dueDate!);
    }

    return DateFormat('MMM d, y, h:mm a').format(dueDate!);
  }

  String get recurrenceLabel {
    if (recurrence == null) return 'One-time';

    switch (recurrence) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Custom';
    }
  }
}
