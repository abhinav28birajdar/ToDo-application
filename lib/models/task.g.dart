// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      completedDate: json['completedDate'] == null
          ? null
          : DateTime.parse(json['completedDate'] as String),
      notificationTime: json['notificationTime'] == null
          ? null
          : DateTime.parse(json['notificationTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 2,
      categoryId: json['categoryId'] as String?,
      userId: json['userId'] as String?,
      recurrence: json['recurrence'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate?.toIso8601String(),
      'completedDate': instance.completedDate?.toIso8601String(),
      'notificationTime': instance.notificationTime?.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'priority': instance.priority,
      'categoryId': instance.categoryId,
      'userId': instance.userId,
      'recurrence': instance.recurrence,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
