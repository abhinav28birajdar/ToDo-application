// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: fields[0] as String,
      sortOrder: fields[1] as String,
      filterOption: fields[2] as String,
      notificationsEnabled: fields[3] as bool,
      autoBackup: fields[4] as bool,
      defaultPriority: fields[5] as int,
      showCompletedTodos: fields[6] as bool,
      dateFormat: fields[7] as String,
      timeFormat: fields[8] as String,
      confirmBeforeDelete: fields[9] as bool,
      reminderMinutesBefore: fields[10] as int,
      groupByCategory: fields[11] as bool,
      defaultCategoryId: fields[12] as String,
      userId: fields[13] as String?,
      updatedAt: fields[14] as DateTime?,
      defaultView: fields[15] as String,
      enableSoundEffects: fields[16] as bool,
      languageCode: fields[17] as String,
      enableDataSync: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.sortOrder)
      ..writeByte(2)
      ..write(obj.filterOption)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.autoBackup)
      ..writeByte(5)
      ..write(obj.defaultPriority)
      ..writeByte(6)
      ..write(obj.showCompletedTodos)
      ..writeByte(7)
      ..write(obj.dateFormat)
      ..writeByte(8)
      ..write(obj.timeFormat)
      ..writeByte(9)
      ..write(obj.confirmBeforeDelete)
      ..writeByte(10)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(11)
      ..write(obj.groupByCategory)
      ..writeByte(12)
      ..write(obj.defaultCategoryId)
      ..writeByte(13)
      ..write(obj.userId)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.defaultView)
      ..writeByte(16)
      ..write(obj.enableSoundEffects)
      ..writeByte(17)
      ..write(obj.languageCode)
      ..writeByte(18)
      ..write(obj.enableDataSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      themeMode: json['theme_mode'] as String? ?? 'system',
      sortOrder: json['sort_order'] as String? ?? 'creation_date_desc',
      filterOption: json['filter_option'] as String? ?? 'all',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      autoBackup: json['auto_backup'] as bool? ?? true,
      defaultPriority: (json['default_priority'] as num?)?.toInt() ?? 2,
      showCompletedTodos: json['show_completed_tasks'] as bool? ?? true,
      dateFormat: json['date_format'] as String? ?? 'MM/dd/yyyy',
      timeFormat: json['time_format'] as String? ?? '12h',
      confirmBeforeDelete: json['confirm_before_delete'] as bool? ?? true,
      reminderMinutesBefore:
          (json['reminder_minutes_before'] as num?)?.toInt() ?? 60,
      groupByCategory: json['group_by_category'] as bool? ?? false,
      defaultCategoryId: json['default_category_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      defaultView: json['default_view'] as String? ?? 'tasks',
      enableSoundEffects: json['enable_sound_effects'] as bool? ?? true,
      languageCode: json['language_code'] as String? ?? 'en',
      enableDataSync: json['enable_data_sync'] as bool? ?? true,
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'theme_mode': instance.themeMode,
      'sort_order': instance.sortOrder,
      'filter_option': instance.filterOption,
      'notifications_enabled': instance.notificationsEnabled,
      'auto_backup': instance.autoBackup,
      'default_priority': instance.defaultPriority,
      'show_completed_tasks': instance.showCompletedTodos,
      'date_format': instance.dateFormat,
      'time_format': instance.timeFormat,
      'confirm_before_delete': instance.confirmBeforeDelete,
      'reminder_minutes_before': instance.reminderMinutesBefore,
      'group_by_category': instance.groupByCategory,
      'default_category_id': instance.defaultCategoryId,
      'user_id': instance.userId,
      'updated_at': instance.updatedAt.toIso8601String(),
      'default_view': instance.defaultView,
      'enable_sound_effects': instance.enableSoundEffects,
      'language_code': instance.languageCode,
      'enable_data_sync': instance.enableDataSync,
    };
