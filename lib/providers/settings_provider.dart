import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

/// Settings Provider for managing app settings
/// Version: 2.0.0 (September 8, 2025)
class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseService _supabaseService = SupabaseService();

  // Default values
  ThemeMode _themeMode = ThemeMode.system;
  String _accentColor = '#C026D3';
  String _sortOrder = 'due_date_asc';
  String _filterOption = 'all';
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoBackup = true;
  String _backupFrequency = 'daily';
  int _defaultPriority = 2;
  bool _showCompletedTasks = true;
  String _dateFormat = 'MM/dd/yyyy';
  String _timeFormat = '12h';
  int _firstDayOfWeek = 0;
  bool _confirmBeforeDelete = true;
  int _reminderMinutesBefore = 60;
  bool _groupByCategory = true;
  String? _defaultCategoryId;
  String _defaultView = 'tasks';
  String _languageCode = 'en';
  bool _enableSoundEffects = true;
  bool _enableHapticFeedback = true;
  bool _enableDataSync = true;
  bool _privacyMode = false;
  bool _twoFactorEnabled = false;
  int _sessionTimeout = 30;
  int _autoSaveInterval = 30;
  int _maxFileSize = 10;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  // Settings object for backward compatibility
  Map<String, dynamic> get settings => {
        'theme_mode': _themeMode,
        'accent_color': _accentColor,
        'sort_order': _sortOrder,
        'filter_option': _filterOption,
        'notifications_enabled': _notificationsEnabled,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
        'auto_backup': _autoBackup,
        'backup_frequency': _backupFrequency,
        'default_priority': _defaultPriority,
        'show_completed_tasks': _showCompletedTasks,
        'date_format': _dateFormat,
        'time_format': _timeFormat,
        'first_day_of_week': _firstDayOfWeek,
        'confirm_before_delete': _confirmBeforeDelete,
        'reminder_minutes_before': _reminderMinutesBefore,
        'group_by_category': _groupByCategory,
        'default_category_id': _defaultCategoryId,
        'default_view': _defaultView,
        'language_code': _languageCode,
        'enable_sound_effects': _enableSoundEffects,
        'enable_haptic_feedback': _enableHapticFeedback,
        'enable_data_sync': _enableDataSync,
        'privacy_mode': _privacyMode,
        'two_factor_enabled': _twoFactorEnabled,
        'session_timeout': _sessionTimeout,
        'auto_save_interval': _autoSaveInterval,
        'max_file_size': _maxFileSize,
      };

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get accentColor => _accentColor;
  String get sortOrder => _sortOrder;
  String get filterOption => _filterOption;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get autoBackup => _autoBackup;
  String get backupFrequency => _backupFrequency;
  int get defaultPriority => _defaultPriority;
  bool get showCompletedTasks => _showCompletedTasks;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get confirmBeforeDelete => _confirmBeforeDelete;
  int get reminderMinutesBefore => _reminderMinutesBefore;
  bool get groupByCategory => _groupByCategory;
  String? get defaultCategoryId => _defaultCategoryId;
  String get defaultView => _defaultView;
  String get languageCode => _languageCode;
  bool get enableSoundEffects => _enableSoundEffects;
  bool get enableHapticFeedback => _enableHapticFeedback;
  bool get enableDataSync => _enableDataSync;
  bool get privacyMode => _privacyMode;
  bool get twoFactorEnabled => _twoFactorEnabled;
  int get sessionTimeout => _sessionTimeout;
  int get autoSaveInterval => _autoSaveInterval;
  int get maxFileSize => _maxFileSize;

  // Theme getters for backward compatibility
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Load settings from SharedPreferences and Supabase
  Future<void> _loadSettings() async {
    // Load from SharedPreferences first (offline cache)
    _themeMode = ThemeMode.values[_prefs.getInt('theme_mode') ?? 0];
    _accentColor = _prefs.getString('accent_color') ?? '#C026D3';
    _sortOrder = _prefs.getString('sort_order') ?? 'due_date_asc';
    _filterOption = _prefs.getString('filter_option') ?? 'all';
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _emailNotifications = _prefs.getBool('email_notifications') ?? true;
    _pushNotifications = _prefs.getBool('push_notifications') ?? true;
    _autoBackup = _prefs.getBool('auto_backup') ?? true;
    _backupFrequency = _prefs.getString('backup_frequency') ?? 'daily';
    _defaultPriority = _prefs.getInt('default_priority') ?? 2;
    _showCompletedTasks = _prefs.getBool('show_completed_tasks') ?? true;
    _dateFormat = _prefs.getString('date_format') ?? 'MM/dd/yyyy';
    _timeFormat = _prefs.getString('time_format') ?? '12h';
    _firstDayOfWeek = _prefs.getInt('first_day_of_week') ?? 0;
    _confirmBeforeDelete = _prefs.getBool('confirm_before_delete') ?? true;
    _reminderMinutesBefore = _prefs.getInt('reminder_minutes_before') ?? 60;
    _groupByCategory = _prefs.getBool('group_by_category') ?? true;
    _defaultCategoryId = _prefs.getString('default_category_id');
    _defaultView = _prefs.getString('default_view') ?? 'tasks';
    _languageCode = _prefs.getString('language_code') ?? 'en';
    _enableSoundEffects = _prefs.getBool('enable_sound_effects') ?? true;
    _enableHapticFeedback = _prefs.getBool('enable_haptic_feedback') ?? true;
    _enableDataSync = _prefs.getBool('enable_data_sync') ?? true;
    _privacyMode = _prefs.getBool('privacy_mode') ?? false;
    _twoFactorEnabled = _prefs.getBool('two_factor_enabled') ?? false;
    _sessionTimeout = _prefs.getInt('session_timeout') ?? 30;
    _autoSaveInterval = _prefs.getInt('auto_save_interval') ?? 30;
    _maxFileSize = _prefs.getInt('max_file_size') ?? 10;

    notifyListeners();

    // Try to sync with Supabase if user is authenticated
    if (_supabaseService.isAuthenticated && _enableDataSync) {
      try {
        final remoteSettings = await _supabaseService.getSettings();
        if (remoteSettings != null) {
          _syncWithRemoteSettings(remoteSettings);
        }
      } catch (e) {
        debugPrint('Failed to load remote settings: $e');
      }
    }
  }

  // Sync with remote settings
  void _syncWithRemoteSettings(Map<String, dynamic> remoteSettings) {
    _themeMode = _parseThemeMode(remoteSettings['theme_mode']);
    _accentColor = remoteSettings['accent_color'] ?? _accentColor;
    _sortOrder = remoteSettings['sort_order'] ?? _sortOrder;
    _filterOption = remoteSettings['filter_option'] ?? _filterOption;
    _notificationsEnabled =
        remoteSettings['notifications_enabled'] ?? _notificationsEnabled;
    _emailNotifications =
        remoteSettings['email_notifications'] ?? _emailNotifications;
    _pushNotifications =
        remoteSettings['push_notifications'] ?? _pushNotifications;
    _autoBackup = remoteSettings['auto_backup'] ?? _autoBackup;
    _backupFrequency = remoteSettings['backup_frequency'] ?? _backupFrequency;
    _defaultPriority = remoteSettings['default_priority'] ?? _defaultPriority;
    _showCompletedTasks =
        remoteSettings['show_completed_tasks'] ?? _showCompletedTasks;
    _dateFormat = remoteSettings['date_format'] ?? _dateFormat;
    _timeFormat = remoteSettings['time_format'] ?? _timeFormat;
    _firstDayOfWeek = remoteSettings['first_day_of_week'] ?? _firstDayOfWeek;
    _confirmBeforeDelete =
        remoteSettings['confirm_before_delete'] ?? _confirmBeforeDelete;
    _reminderMinutesBefore =
        remoteSettings['reminder_minutes_before'] ?? _reminderMinutesBefore;
    _groupByCategory = remoteSettings['group_by_category'] ?? _groupByCategory;
    _defaultCategoryId = remoteSettings['default_category_id'];
    _defaultView = remoteSettings['default_view'] ?? _defaultView;
    _languageCode = remoteSettings['language_code'] ?? _languageCode;
    _enableSoundEffects =
        remoteSettings['enable_sound_effects'] ?? _enableSoundEffects;
    _enableHapticFeedback =
        remoteSettings['enable_haptic_feedback'] ?? _enableHapticFeedback;
    _enableDataSync = remoteSettings['enable_data_sync'] ?? _enableDataSync;
    _privacyMode = remoteSettings['privacy_mode'] ?? _privacyMode;
    _twoFactorEnabled =
        remoteSettings['two_factor_enabled'] ?? _twoFactorEnabled;
    _sessionTimeout = remoteSettings['session_timeout'] ?? _sessionTimeout;
    _autoSaveInterval =
        remoteSettings['auto_save_interval'] ?? _autoSaveInterval;
    _maxFileSize = remoteSettings['max_file_size'] ?? _maxFileSize;

    // Save to local storage
    _saveToLocal();
    notifyListeners();
  }

  // Parse theme mode from string
  ThemeMode _parseThemeMode(String? themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // Convert theme mode to string
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Save settings to local storage
  Future<void> _saveToLocal() async {
    await _prefs.setInt('theme_mode', _themeMode.index);
    await _prefs.setString('accent_color', _accentColor);
    await _prefs.setString('sort_order', _sortOrder);
    await _prefs.setString('filter_option', _filterOption);
    await _prefs.setBool('notifications_enabled', _notificationsEnabled);
    await _prefs.setBool('email_notifications', _emailNotifications);
    await _prefs.setBool('push_notifications', _pushNotifications);
    await _prefs.setBool('auto_backup', _autoBackup);
    await _prefs.setString('backup_frequency', _backupFrequency);
    await _prefs.setInt('default_priority', _defaultPriority);
    await _prefs.setBool('show_completed_tasks', _showCompletedTasks);
    await _prefs.setString('date_format', _dateFormat);
    await _prefs.setString('time_format', _timeFormat);
    await _prefs.setInt('first_day_of_week', _firstDayOfWeek);
    await _prefs.setBool('confirm_before_delete', _confirmBeforeDelete);
    await _prefs.setInt('reminder_minutes_before', _reminderMinutesBefore);
    await _prefs.setBool('group_by_category', _groupByCategory);
    if (_defaultCategoryId != null) {
      await _prefs.setString('default_category_id', _defaultCategoryId!);
    }
    await _prefs.setString('default_view', _defaultView);
    await _prefs.setString('language_code', _languageCode);
    await _prefs.setBool('enable_sound_effects', _enableSoundEffects);
    await _prefs.setBool('enable_haptic_feedback', _enableHapticFeedback);
    await _prefs.setBool('enable_data_sync', _enableDataSync);
    await _prefs.setBool('privacy_mode', _privacyMode);
    await _prefs.setBool('two_factor_enabled', _twoFactorEnabled);
    await _prefs.setInt('session_timeout', _sessionTimeout);
    await _prefs.setInt('auto_save_interval', _autoSaveInterval);
    await _prefs.setInt('max_file_size', _maxFileSize);
  }

  // Save settings to remote (Supabase)
  Future<void> _saveToRemote() async {
    if (!_supabaseService.isAuthenticated || !_enableDataSync) return;

    try {
      final settingsMap = {
        'theme_mode': _themeModeToString(_themeMode),
        'accent_color': _accentColor,
        'sort_order': _sortOrder,
        'filter_option': _filterOption,
        'notifications_enabled': _notificationsEnabled,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
        'auto_backup': _autoBackup,
        'backup_frequency': _backupFrequency,
        'default_priority': _defaultPriority,
        'show_completed_tasks': _showCompletedTasks,
        'date_format': _dateFormat,
        'time_format': _timeFormat,
        'first_day_of_week': _firstDayOfWeek,
        'confirm_before_delete': _confirmBeforeDelete,
        'reminder_minutes_before': _reminderMinutesBefore,
        'group_by_category': _groupByCategory,
        'default_category_id': _defaultCategoryId,
        'default_view': _defaultView,
        'language_code': _languageCode,
        'enable_sound_effects': _enableSoundEffects,
        'enable_haptic_feedback': _enableHapticFeedback,
        'enable_data_sync': _enableDataSync,
        'privacy_mode': _privacyMode,
        'two_factor_enabled': _twoFactorEnabled,
        'session_timeout': _sessionTimeout,
        'auto_save_interval': _autoSaveInterval,
        'max_file_size': _maxFileSize,
      };

      await _supabaseService.updateSettings(settingsMap);
    } catch (e) {
      debugPrint('Failed to save remote settings: $e');
    }
  }

  // Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Backward compatibility methods
  Future<void> setThemeMode(String mode) async {
    final themeMode = _parseThemeMode(mode);
    await updateThemeMode(themeMode);
  }

  Future<void> toggleTheme() async {
    ThemeMode newMode;
    switch (_themeMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
    }
    await updateThemeMode(newMode);
  }

  // Update accent color
  Future<void> updateAccentColor(String color) async {
    _accentColor = color;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Update notifications setting
  Future<void> updateNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Backward compatibility
  Future<void> setNotificationsEnabled(bool enabled) async {
    await updateNotificationsEnabled(enabled);
  }

  // Update data sync setting
  Future<void> updateDataSync(bool enabled) async {
    _enableDataSync = enabled;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Update sort order
  Future<void> updateSortOrder(String sortOrder) async {
    _sortOrder = sortOrder;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Backward compatibility
  Future<void> setSortOrder(String order) async {
    await updateSortOrder(order);
  }

  // Update filter option
  Future<void> updateFilterOption(String filterOption) async {
    _filterOption = filterOption;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Backward compatibility
  Future<void> setFilterOption(String filter) async {
    await updateFilterOption(filter);
  }

  // Update default view
  Future<void> updateDefaultView(String view) async {
    _defaultView = view;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Additional setter methods for backward compatibility
  Future<void> setShowCompletedTodos(bool value) async {
    _showCompletedTasks = value;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setGroupByCategory(bool value) async {
    _groupByCategory = value;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setConfirmBeforeDelete(bool value) async {
    _confirmBeforeDelete = value;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setAutoBackup(bool value) async {
    _autoBackup = value;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setDefaultPriority(int priority) async {
    _defaultPriority = priority;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setDefaultCategoryId(String? categoryId) async {
    _defaultCategoryId = categoryId;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setReminderMinutesBefore(int minutes) async {
    _reminderMinutesBefore = minutes;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  Future<void> setTimeFormat(String format) async {
    _timeFormat = format;
    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _accentColor = '#C026D3';
    _sortOrder = 'due_date_asc';
    _filterOption = 'all';
    _notificationsEnabled = true;
    _emailNotifications = true;
    _pushNotifications = true;
    _autoBackup = true;
    _backupFrequency = 'daily';
    _defaultPriority = 2;
    _showCompletedTasks = true;
    _dateFormat = 'MM/dd/yyyy';
    _timeFormat = '12h';
    _firstDayOfWeek = 0;
    _confirmBeforeDelete = true;
    _reminderMinutesBefore = 60;
    _groupByCategory = true;
    _defaultCategoryId = null;
    _defaultView = 'tasks';
    _languageCode = 'en';
    _enableSoundEffects = true;
    _enableHapticFeedback = true;
    _enableDataSync = true;
    _privacyMode = false;
    _twoFactorEnabled = false;
    _sessionTimeout = 30;
    _autoSaveInterval = 30;
    _maxFileSize = 10;

    await _saveToLocal();
    await _saveToRemote();
    notifyListeners();
  }
}
