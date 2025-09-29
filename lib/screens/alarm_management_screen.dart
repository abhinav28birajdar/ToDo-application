import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

class AlarmManagementScreen extends StatefulWidget {
  const AlarmManagementScreen({Key? key}) : super(key: key);

  @override
  _AlarmManagementScreenState createState() => _AlarmManagementScreenState();
}

class _AlarmManagementScreenState extends State<AlarmManagementScreen> {
  final AlarmService _alarmService = AlarmService();

  @override
  void initState() {
    super.initState();
    _alarmService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_alarmService.isAlarmPlaying)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () async {
                await _alarmService.stopAllAlarms();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All alarms stopped')),
                );
              },
              tooltip: 'Stop All Alarms',
            ),
        ],
      ),
      body: Column(
        children: [
          // Currently Playing Alarm Card
          if (_alarmService.isAlarmPlaying)
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alarm, color: Colors.red, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALARM RINGING',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _alarmService.currentlyPlayingAlarm?.title ??
                                      'Unknown Alarm',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final alarmId =
                                  _alarmService.currentlyPlayingAlarmId;
                              if (alarmId != null) {
                                await _alarmService.stopAlarm(alarmId);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Alarm stopped')),
                                );
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final alarmId =
                                  _alarmService.currentlyPlayingAlarmId;
                              if (alarmId != null) {
                                await _alarmService.snoozeAlarm(alarmId, 5);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Alarm snoozed for 5 minutes')),
                                );
                              }
                            },
                            icon: const Icon(Icons.snooze),
                            label: const Text('Snooze 5min'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Active Alarms List
          Expanded(
            child: _alarmService.activeAlarms.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No active alarms',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alarmService.activeAlarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarmService.activeAlarms[index];
                      final isPlaying =
                          alarm.id == _alarmService.currentlyPlayingAlarmId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isPlaying ? Colors.red.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isPlaying ? Colors.red : Colors.orange,
                            child: Icon(
                              isPlaying ? Icons.volume_up : Icons.alarm,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            alarm.title,
                            style: TextStyle(
                              fontWeight: isPlaying
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled: ${_formatDateTime(alarm.scheduledTime)}',
                              ),
                              if (alarm.description != null)
                                Text(
                                  alarm.description!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'stop':
                                  await _alarmService.stopAlarm(alarm.id);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Stopped: ${alarm.title}')),
                                  );
                                  break;
                                case 'cancel':
                                  await _alarmService.cancelAlarm(alarm.id);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Cancelled: ${alarm.title}')),
                                  );
                                  break;
                                case 'snooze':
                                  await _alarmService.snoozeAlarm(alarm.id, 10);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Snoozed: ${alarm.title} for 10 minutes')),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (isPlaying)
                                const PopupMenuItem(
                                  value: 'stop',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.stop, color: Colors.red),
                                    title: Text('Stop Alarm'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              if (isPlaying)
                                const PopupMenuItem(
                                  value: 'snooze',
                                  child: ListTile(
                                    leading: Icon(Icons.snooze,
                                        color: Colors.orange),
                                    title: Text('Snooze 10min'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: ListTile(
                                  leading:
                                      Icon(Icons.cancel, color: Colors.grey),
                                  title: Text('Cancel Alarm'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add_alarm, color: Colors.white),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAddAlarmDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(minutes: 5));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Alarm Time'),
                  subtitle: Text(_formatDateTime(selectedDateTime)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an alarm title')),
                  );
                  return;
                }

                await _alarmService.scheduleCustomAlarm(
                  title: titleController.text.trim(),
                  scheduledTime: selectedDateTime,
                  soundPath: 'assets/sounds/alarm.mp3',
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Alarm scheduled: ${titleController.text.trim()}')),
                );
              },
              child: const Text('Schedule Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
