import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@JsonSerializable()
@HiveType(typeId: 2) // Unique ID for AppSettings model
class AppSettings extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'theme_mode')
  String themeMode; // 'light', 'dark', 'system'

  @HiveField(1)
  @JsonKey(name: 'sort_order')
  String
      sortOrder; // 'creation_date_asc', 'creation_date_desc', 'due_date_asc', 'due_date_desc', 'priority', 'title'

  @HiveField(2)
  @JsonKey(name: 'filter_option')
  String filterOption; // 'all', 'active', 'completed'

  @HiveField(3)
  @JsonKey(name: 'notifications_enabled')
  bool notificationsEnabled;

  @HiveField(4)
  @JsonKey(name: 'auto_backup')
  bool autoBackup;

  @HiveField(5)
  @JsonKey(name: 'default_priority')
  int defaultPriority; // 1=High, 2=Medium, 3=Low

  @HiveField(6)
  @JsonKey(name: 'show_completed_tasks')
  bool showCompletedTodos;

  @HiveField(7)
  @JsonKey(name: 'date_format')
  String dateFormat; // 'MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'

  @HiveField(8)
  @JsonKey(name: 'time_format')
  String timeFormat; // '12h', '24h'

  @HiveField(9)
  @JsonKey(name: 'confirm_before_delete')
  bool confirmBeforeDelete;

  @HiveField(10)
  @JsonKey(name: 'reminder_minutes_before')
  int reminderMinutesBefore; // Minutes before due date to show reminder

  @HiveField(11)
  @JsonKey(name: 'group_by_category')
  bool groupByCategory;

  @HiveField(12)
  @JsonKey(name: 'default_category_id')
  String defaultCategoryId;

  @HiveField(13)
  @JsonKey(name: 'user_id')
  String? userId;

  @HiveField(14)
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  @HiveField(15)
  @JsonKey(name: 'default_view')
  String defaultView; // 'tasks', 'notes', 'calendar'

  @HiveField(16)
  @JsonKey(name: 'enable_sound_effects')
  bool enableSoundEffects;

  @HiveField(17)
  @JsonKey(name: 'language_code')
  String languageCode;

  @HiveField(18)
  @JsonKey(name: 'enable_data_sync')
  bool enableDataSync;

  AppSettings({
    this.themeMode = 'system',
    this.sortOrder = 'creation_date_desc',
    this.filterOption = 'all',
    this.notificationsEnabled = true,
    this.autoBackup = true,
    this.defaultPriority = 2,
    this.showCompletedTodos = true,
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12h',
    this.confirmBeforeDelete = true,
    this.reminderMinutesBefore = 60,
    this.groupByCategory = false,
    this.defaultCategoryId = '',
    this.userId,
    DateTime? updatedAt,
    this.defaultView = 'tasks',
    this.enableSoundEffects = true,
    this.languageCode = 'en',
    this.enableDataSync = true,
  }) : updatedAt = updatedAt ?? DateTime.now();

  AppSettings copyWith({
    String? themeMode,
    String? sortOrder,
    String? filterOption,
    bool? notificationsEnabled,
    bool? autoBackup,
    int? defaultPriority,
    bool? showCompletedTodos,
    String? dateFormat,
    String? timeFormat,
    bool? confirmBeforeDelete,
    int? reminderMinutesBefore,
    bool? groupByCategory,
    String? defaultCategoryId,
    String? userId,
    DateTime? updatedAt,
    String? defaultView,
    bool? enableSoundEffects,
    String? languageCode,
    bool? enableDataSync,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      sortOrder: sortOrder ?? this.sortOrder,
      filterOption: filterOption ?? this.filterOption,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoBackup: autoBackup ?? this.autoBackup,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      showCompletedTodos: showCompletedTodos ?? this.showCompletedTodos,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      groupByCategory: groupByCategory ?? this.groupByCategory,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? DateTime.now(),
      defaultView: defaultView ?? this.defaultView,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      languageCode: languageCode ?? this.languageCode,
      enableDataSync: enableDataSync ?? this.enableDataSync,
    );
  }

  // Create AppSettings from a map/JSON object
  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  // Convert AppSettings to a map/JSON object
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  // For Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'theme_mode': themeMode,
      'sort_order': sortOrder,
      'filter_option': filterOption,
      'notifications_enabled': notificationsEnabled,
      'auto_backup': autoBackup,
      'default_priority': defaultPriority,
      'show_completed_tasks': showCompletedTodos,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'confirm_before_delete': confirmBeforeDelete,
      'reminder_minutes_before': reminderMinutesBefore,
      'group_by_category': groupByCategory,
      'default_category_id': defaultCategoryId,
      'updated_at': updatedAt.toIso8601String(),
      'default_view': defaultView,
      'enable_sound_effects': enableSoundEffects,
      'language_code': languageCode,
      'enable_data_sync': enableDataSync,
    };
  }

  // Create AppSettings from Supabase
  factory AppSettings.fromSupabase(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: map['theme_mode'] as String? ?? 'system',
      sortOrder: map['sort_order'] as String? ?? 'creation_date_desc',
      filterOption: map['filter_option'] as String? ?? 'all',
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      autoBackup: map['auto_backup'] as bool? ?? true,
      defaultPriority: map['default_priority'] as int? ?? 2,
      showCompletedTodos: map['show_completed_tasks'] as bool? ?? true,
      dateFormat: map['date_format'] as String? ?? 'MM/dd/yyyy',
      timeFormat: map['time_format'] as String? ?? '12h',
      confirmBeforeDelete: map['confirm_before_delete'] as bool? ?? true,
      reminderMinutesBefore: map['reminder_minutes_before'] as int? ?? 60,
      groupByCategory: map['group_by_category'] as bool? ?? false,
      defaultCategoryId: map['default_category_id'] as String? ?? '',
      userId: map['user_id'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      defaultView: map['default_view'] as String? ?? 'tasks',
      enableSoundEffects: map['enable_sound_effects'] as bool? ?? true,
      languageCode: map['language_code'] as String? ?? 'en',
      enableDataSync: map['enable_data_sync'] as bool? ?? true,
    );
  }

  // Provide the theme mode based on settings
  ThemeMode getThemeMode() {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // Helper to create default settings for a user
  factory AppSettings.createDefault(String userId) {
    return AppSettings(
      themeMode: 'system',
      sortOrder: 'due_date_asc',
      filterOption: 'all',
      notificationsEnabled: true,
      autoBackup: true,
      defaultPriority: 2,
      showCompletedTodos: true,
      dateFormat: 'MM/dd/yyyy',
      timeFormat: '12h',
      confirmBeforeDelete: true,
      reminderMinutesBefore: 60,
      groupByCategory: true,
      defaultCategoryId: '',
      userId: userId,
      defaultView: 'tasks',
      enableSoundEffects: true,
      languageCode: 'en',
      enableDataSync: true,
    );
  }

  @override
  String toString() {
    return 'AppSettings{themeMode: $themeMode, sortOrder: $sortOrder, filterOption: $filterOption}';
  }
}
