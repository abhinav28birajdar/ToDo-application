import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../services/backup_service.dart';
import '../models/app_settings.dart';
import '../models/task.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildThemeSettings(context, settingsProvider),
              const SizedBox(height: 24),

              // Default Settings Section
              _buildSectionHeader('Default Settings'),
              _buildDefaultSettings(context, settingsProvider),
              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              _buildNotificationSettings(context, settingsProvider),
              const SizedBox(height: 24),

              // Display Settings Section
              _buildSectionHeader('Display'),
              _buildDisplaySettings(context, settingsProvider),
              const SizedBox(height: 24),

              // Data Management Section
              _buildSectionHeader('Data Management'),
              _buildDataSettings(context, settingsProvider),
              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              _buildAboutSettings(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    });
  }

  Widget _buildThemeSettings(
      BuildContext context, SettingsProvider settingsProvider) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showThemeDialog(context, settingsProvider),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.palette,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeText(settingsProvider.themeMode)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          ListTile(
            leading: Icon(
              Icons.brightness_6,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Quick Theme Toggle'),
            subtitle: const Text('Tap to cycle through themes'),
            trailing: IconButton(
              icon: Icon(
                settingsProvider.isDarkMode
                    ? Icons.dark_mode
                    : settingsProvider.isLightMode
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => settingsProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSettings(
      BuildContext context, SettingsProvider settingsProvider) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPriorityDialog(context, settingsProvider),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.flag,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Default Priority'),
                subtitle:
                    Text(_getPriorityText(settingsProvider.defaultPriority)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          Consumer<HybridCategoryProvider>(
            builder: (context, categoryProvider, child) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDefaultCategoryDialog(
                    context,
                    settingsProvider,
                    categoryProvider,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      Icons.category,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Default Category'),
                    subtitle: Text(_getDefaultCategoryText(
                      categoryProvider,
                      settingsProvider.defaultCategoryId ?? '',
                    )),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
      BuildContext context, SettingsProvider settingsProvider) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.notifications,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders for due todos'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) =>
                settingsProvider.setNotificationsEnabled(value),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showReminderTimeDialog(context, settingsProvider),
              child: ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Default Reminder Time'),
                subtitle: Text(
                    '${settingsProvider.reminderMinutesBefore} minutes before due'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.notifications_active,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Advanced Notification Settings'),
                subtitle: const Text(
                    'Configure Firebase notifications, sounds & alarms'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettings(
      BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.visibility),
            title: const Text('Show Completed Todos'),
            subtitle: const Text('Display completed todos in lists'),
            value: settingsProvider.showCompletedTasks,
            onChanged: (value) => settingsProvider.setShowCompletedTodos(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.group_work),
            title: const Text('Group by Category'),
            subtitle: const Text('Group todos by their categories'),
            value: settingsProvider.groupByCategory,
            onChanged: (value) => settingsProvider.setGroupByCategory(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.warning),
            title: const Text('Confirm Before Delete'),
            subtitle: const Text('Ask for confirmation before deleting'),
            value: settingsProvider.confirmBeforeDelete,
            onChanged: (value) =>
                settingsProvider.setConfirmBeforeDelete(value),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Date Format'),
            subtitle: Text(settingsProvider.dateFormat),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showDateFormatDialog(context, settingsProvider),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time Format'),
            subtitle: Text(settingsProvider.timeFormat),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showTimeFormatDialog(context, settingsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings(
      BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.backup),
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup data'),
            value: settingsProvider.autoBackup,
            onChanged: (value) => settingsProvider.setAutoBackup(value),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export all your todos and settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Data'),
            subtitle: const Text('Import todos and settings from backup'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _importData(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Reset All Data'),
            subtitle: const Text('Delete all todos and reset settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help using the app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showHelpDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            subtitle: const Text('Help us improve the app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showBugReportDialog(context),
          ),
        ],
      ),
    );
  }

  // Helper methods for text display
  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

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

  String _getPriorityText(int priority) {
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

  String _getDefaultCategoryText(
      HybridCategoryProvider categoryProvider, String categoryId) {
    if (categoryId.isEmpty) return 'No default category';
    final category = categoryProvider.getCategoryById(categoryId);
    return category?.name ?? 'Unknown category';
  }

  // Dialog methods
  void _showThemeDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _themeModeToString(settingsProvider.themeMode),
              onChanged: (value) {
                settingsProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _themeModeToString(settingsProvider.themeMode),
              onChanged: (value) {
                settingsProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: _themeModeToString(settingsProvider.themeMode),
              onChanged: (value) {
                settingsProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('High'),
              value: 1,
              groupValue: settingsProvider.defaultPriority,
              onChanged: (value) {
                settingsProvider.setDefaultPriority(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Medium'),
              value: 2,
              groupValue: settingsProvider.defaultPriority,
              onChanged: (value) {
                settingsProvider.setDefaultPriority(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('Low'),
              value: 3,
              groupValue: settingsProvider.defaultPriority,
              onChanged: (value) {
                settingsProvider.setDefaultPriority(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultCategoryDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('No default category'),
                value: '',
                groupValue: settingsProvider.defaultCategoryId,
                onChanged: (value) {
                  settingsProvider.setDefaultCategoryId(value!);
                  Navigator.pop(context);
                },
              ),
              ...categoryProvider.categories.map(
                (category) => RadioListTile<String>(
                  title: Text(category.name),
                  value: category.id,
                  groupValue: settingsProvider.defaultCategoryId,
                  onChanged: (value) {
                    settingsProvider.setDefaultCategoryId(value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderTimeDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    final controller = TextEditingController(
      text: settingsProvider.reminderMinutesBefore.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Reminder Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Minutes before due time:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 60;
              settingsProvider.setReminderMinutesBefore(minutes);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDateFormatDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('MM/dd/yyyy'),
              value: 'MM/dd/yyyy',
              groupValue: settingsProvider.dateFormat,
              onChanged: (value) {
                settingsProvider.setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('dd/MM/yyyy'),
              value: 'dd/MM/yyyy',
              groupValue: settingsProvider.dateFormat,
              onChanged: (value) {
                settingsProvider.setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('yyyy-MM-dd'),
              value: 'yyyy-MM-dd',
              groupValue: settingsProvider.dateFormat,
              onChanged: (value) {
                settingsProvider.setDateFormat(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeFormatDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('12-hour (AM/PM)'),
              value: '12h',
              groupValue: settingsProvider.timeFormat,
              onChanged: (value) {
                settingsProvider.setTimeFormat(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('24-hour'),
              value: '24h',
              groupValue: settingsProvider.timeFormat,
              onChanged: (value) {
                settingsProvider.setTimeFormat(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final taskProvider = context.read<HybridTaskProvider>();
      final categoryProvider = context.read<HybridCategoryProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // Export functionality is handled by BackupService

      // Create an instance of BackupService
      final backupService = BackupService();
      final settingsObject = AppSettings(
        themeMode: settingsProvider.themeMode.name,
        sortOrder: settingsProvider.sortOrder,
        filterOption: settingsProvider.filterOption,
        notificationsEnabled: settingsProvider.notificationsEnabled,
        autoBackup: settingsProvider.autoBackup,
        defaultPriority: settingsProvider.defaultPriority,
        showCompletedTodos: settingsProvider.showCompletedTasks,
        dateFormat: settingsProvider.dateFormat,
        timeFormat: settingsProvider.timeFormat,
        confirmBeforeDelete: settingsProvider.confirmBeforeDelete,
        reminderMinutesBefore: settingsProvider.reminderMinutesBefore,
        groupByCategory: settingsProvider.groupByCategory,
        defaultCategoryId: settingsProvider.defaultCategoryId ?? '',
        defaultView: settingsProvider.defaultView,
        enableSoundEffects: settingsProvider.enableSoundEffects,
        languageCode: settingsProvider.languageCode,
        enableDataSync: settingsProvider.enableDataSync,
      );
      final backupPath = await backupService.createBackup(
        tasks: taskProvider.todos
            .map((todo) => Task.fromJson(todo.toJson()))
            .toList(),
        notes: [], // Assuming we don't have notes yet
        categories: categoryProvider.categories,
        settings: settingsObject,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to: $backupPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    // TODO: Implement file picker for import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon!')),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your todos, categories, and reset all settings to default. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement reset functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Reset functionality coming soon!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Todo App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.check_circle, size: 48),
      children: [
        const Text(
            'A complete Flutter Todo application with Provider and Hive persistence.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Add, edit, and delete todos'),
        const Text('• Categories and tags'),
        const Text('• Priority levels'),
        const Text('• Due dates and notifications'),
        const Text('• Search and filtering'),
        const Text('• Dark/Light theme'),
        const Text('• Backup and restore'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to use the app:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Tap the + button to add a new todo'),
              Text('2. Set priority, category, and due date'),
              Text('3. Use the search bar to find specific todos'),
              Text('4. Tap on a todo to edit it'),
              Text('5. Swipe or use the delete button to remove todos'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Use categories to organize your todos'),
              Text('• Set due dates to get notifications'),
              Text('• Use tags for better searching'),
              Text('• Enable auto-backup in settings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'Found a bug or have a suggestion? Please contact us at:\n\ntodoapp@example.com\n\nInclude details about what you were doing when the issue occurred.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
