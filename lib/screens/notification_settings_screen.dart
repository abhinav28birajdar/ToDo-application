import 'package:flutter/material.dart';
import '../services/firebase_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedSound = 'default';
  bool _vibrationEnabled = true;
  int _reminderMinutes = 15;

  final List<int> _reminderOptions = [5, 10, 15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final firebaseService = FirebaseNotificationService.instance;
    setState(() {
      _notificationsEnabled = firebaseService.notificationsEnabled;
      _selectedSound = firebaseService.selectedSound;
      _vibrationEnabled = firebaseService.vibrationEnabled;
      _reminderMinutes = firebaseService.reminderMinutes;
    });
  }

  Future<void> _updateSettings() async {
    final firebaseService = FirebaseNotificationService.instance;
    await firebaseService.updateSettings(
      notificationsEnabled: _notificationsEnabled,
      selectedSound: _selectedSound,
      vibrationEnabled: _vibrationEnabled,
      reminderMinutes: _reminderMinutes,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Notification settings updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testNotification({bool isAlarm = false}) async {
    final firebaseService = FirebaseNotificationService.instance;
    await firebaseService.testNotification(isAlarm: isAlarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isAlarm ? '🚨 Test alarm sent!' : '🔔 Test notification sent!'),
          backgroundColor: isAlarm ? Colors.orange : Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _updateSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Preferences',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize how you receive task reminders and alerts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Enabled Toggle
          _buildSettingsCard(
            title: 'Enable Notifications',
            icon: Icons.notifications,
            child: Switch.adaptive(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Reminder Time
          _buildSettingsCard(
            title: 'Reminder Time',
            subtitle: 'How many minutes before the due time',
            icon: Icons.schedule,
            child: DropdownButton<int>(
              value: _reminderMinutes,
              onChanged: _notificationsEnabled
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _reminderMinutes = value;
                        });
                      }
                    }
                  : null,
              underline: const SizedBox(),
              items: _reminderOptions.map((minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text('$minutes minutes'),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Notification Sound
          _buildSettingsCard(
            title: 'Notification Sound',
            subtitle: 'Choose your preferred alert sound',
            icon: Icons.volume_up,
            child: DropdownButton<String>(
              value: _selectedSound,
              onChanged: _notificationsEnabled
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSound = value;
                        });
                      }
                    }
                  : null,
              underline: const SizedBox(),
              items: FirebaseNotificationService.availableSounds.map((sound) {
                return DropdownMenuItem<String>(
                  value: sound,
                  child: Text(_formatSoundName(sound)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Vibration Toggle
          _buildSettingsCard(
            title: 'Vibration',
            subtitle: 'Enable haptic feedback for notifications',
            icon: Icons.vibration,
            child: Switch.adaptive(
              value: _vibrationEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                    }
                  : null,
              activeColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Test Notifications Section
          if (_notificationsEnabled) ...[
            Text(
              'Test Notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testNotification(isAlarm: false),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testNotification(isAlarm: true),
                    icon: const Icon(Icons.alarm),
                    label: const Text('Test Alarm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // FCM Token Info (for debugging)
          if (FirebaseNotificationService.instance.initialized) ...[
            ExpansionTile(
              title: const Text('Developer Info'),
              leading: const Icon(Icons.developer_mode),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FCM Token:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FirebaseNotificationService.instance.fcmToken ??
                            'Not available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _notificationsEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _notificationsEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  String _formatSoundName(String sound) {
    switch (sound) {
      case 'default':
        return 'Default';
      case 'alarm_gentle':
        return 'Gentle Alarm';
      case 'alarm_classic':
        return 'Classic Alarm';
      case 'chime':
        return 'Chime';
      case 'bell':
        return 'Bell';
      case 'notification':
        return 'Notification';
      default:
        return sound;
    }
  }
}
