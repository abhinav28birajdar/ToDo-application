import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2) // Unique ID for AppSettings model
class AppSettings extends HiveObject {
  @HiveField(0)
  String themeMode; // 'light', 'dark', 'system'

  @HiveField(1)
  String
      sortOrder; // 'creation_date_asc', 'creation_date_desc', 'due_date_asc', 'due_date_desc', 'priority', 'title'

  @HiveField(2)
  String filterOption; // 'all', 'active', 'completed'

  @HiveField(3)
  bool notificationsEnabled;

  @HiveField(4)
  bool autoBackup;

  @HiveField(5)
  int defaultPriority; // 1=High, 2=Medium, 3=Low

  @HiveField(6)
  bool showCompletedTodos;

  @HiveField(7)
  String dateFormat; // 'MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'

  @HiveField(8)
  String timeFormat; // '12h', '24h'

  @HiveField(9)
  bool confirmBeforeDelete;

  @HiveField(10)
  int reminderMinutesBefore; // Minutes before due date to show reminder

  @HiveField(11)
  bool groupByCategory;

  @HiveField(12)
  String defaultCategoryId;

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
  });

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
    );
  }

  @override
  String toString() {
    return 'AppSettings{themeMode: $themeMode, sortOrder: $sortOrder, filterOption: $filterOption}';
  }
}
