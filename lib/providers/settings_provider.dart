import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  static String get _settingsBoxName =>
      dotenv.env['SETTINGS_BOX_NAME'] ?? 'settings';
  static const String _settingsKey = 'app_settings';

  late Box<AppSettings> _settingsBox;
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  // Theme getters
  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode => _settings.themeMode == 'dark';
  bool get isLightMode => _settings.themeMode == 'light';
  bool get isSystemMode => _settings.themeMode == 'system';

  SettingsProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
      } else {
        _settingsBox = Hive.box<AppSettings>(_settingsBoxName);
      }

      // Load settings or create default
      _settings = _settingsBox.get(_settingsKey) ?? AppSettings();
      await _saveSettings(); // Save default settings if they don't exist

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Settings Hive box: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsBox.put(_settingsKey, _settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }

  // Theme settings
  Future<void> setThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> toggleTheme() async {
    String newMode;
    switch (_settings.themeMode) {
      case 'light':
        newMode = 'dark';
        break;
      case 'dark':
        newMode = 'system';
        break;
      case 'system':
      default:
        newMode = 'light';
        break;
    }
    await setThemeMode(newMode);
  }

  // Sort and filter settings
  Future<void> setSortOrder(String order) async {
    _settings = _settings.copyWith(sortOrder: order);
    await _saveSettings();
  }

  Future<void> setFilterOption(String filter) async {
    _settings = _settings.copyWith(filterOption: filter);
    await _saveSettings();
  }

  // Notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setReminderMinutesBefore(int minutes) async {
    _settings = _settings.copyWith(reminderMinutesBefore: minutes);
    await _saveSettings();
  }

  // Backup settings
  Future<void> setAutoBackup(bool enabled) async {
    _settings = _settings.copyWith(autoBackup: enabled);
    await _saveSettings();
  }

  // Display settings
  Future<void> setShowCompletedTodos(bool show) async {
    _settings = _settings.copyWith(showCompletedTodos: show);
    await _saveSettings();
  }

  Future<void> setGroupByCategory(bool group) async {
    _settings = _settings.copyWith(groupByCategory: group);
    await _saveSettings();
  }

  // Default settings
  Future<void> setDefaultPriority(int priority) async {
    _settings = _settings.copyWith(defaultPriority: priority);
    await _saveSettings();
  }

  Future<void> setDefaultCategoryId(String categoryId) async {
    _settings = _settings.copyWith(defaultCategoryId: categoryId);
    await _saveSettings();
  }

  // Date and time format settings
  Future<void> setDateFormat(String format) async {
    _settings = _settings.copyWith(dateFormat: format);
    await _saveSettings();
  }

  Future<void> setTimeFormat(String format) async {
    _settings = _settings.copyWith(timeFormat: format);
    await _saveSettings();
  }

  // Confirmation settings
  Future<void> setConfirmBeforeDelete(bool confirm) async {
    _settings = _settings.copyWith(confirmBeforeDelete: confirm);
    await _saveSettings();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _settings = AppSettings();
    await _saveSettings();
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'settings': {
        'themeMode': _settings.themeMode,
        'sortOrder': _settings.sortOrder,
        'filterOption': _settings.filterOption,
        'notificationsEnabled': _settings.notificationsEnabled,
        'autoBackup': _settings.autoBackup,
        'defaultPriority': _settings.defaultPriority,
        'showCompletedTodos': _settings.showCompletedTodos,
        'dateFormat': _settings.dateFormat,
        'timeFormat': _settings.timeFormat,
        'confirmBeforeDelete': _settings.confirmBeforeDelete,
        'reminderMinutesBefore': _settings.reminderMinutesBefore,
        'groupByCategory': _settings.groupByCategory,
        'defaultCategoryId': _settings.defaultCategoryId,
      },
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> data) async {
    try {
      final settingsData = data['settings'] as Map<String, dynamic>;

      _settings = AppSettings(
        themeMode: settingsData['themeMode'] ?? 'system',
        sortOrder: settingsData['sortOrder'] ?? 'creation_date_desc',
        filterOption: settingsData['filterOption'] ?? 'all',
        notificationsEnabled: settingsData['notificationsEnabled'] ?? true,
        autoBackup: settingsData['autoBackup'] ?? true,
        defaultPriority: settingsData['defaultPriority'] ?? 2,
        showCompletedTodos: settingsData['showCompletedTodos'] ?? true,
        dateFormat: settingsData['dateFormat'] ?? 'MM/dd/yyyy',
        timeFormat: settingsData['timeFormat'] ?? '12h',
        confirmBeforeDelete: settingsData['confirmBeforeDelete'] ?? true,
        reminderMinutesBefore: settingsData['reminderMinutesBefore'] ?? 60,
        groupByCategory: settingsData['groupByCategory'] ?? false,
        defaultCategoryId: settingsData['defaultCategoryId'] ?? '',
      );

      await _saveSettings();
    } catch (e) {
      debugPrint('Error importing settings: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _settingsBox.close();
    super.dispose();
  }
}
