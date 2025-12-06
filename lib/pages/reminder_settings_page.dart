import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/reminder_provider.dart';
import 'package:samadhan_app/models/reminder_settings.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  late bool _scheduleRemindersEnabled;
  late int _scheduleReminderMinutes;
  late bool _attendanceRemindersEnabled;
  late TimeOfDay _attendanceReminderTime;
  late Set<int> _attendanceReminderDays;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReminderProvider>().settings;
    _scheduleRemindersEnabled = settings.scheduleRemindersEnabled;
    _scheduleReminderMinutes = settings.scheduleReminderMinutesBefore;
    _attendanceRemindersEnabled = settings.attendanceRemindersEnabled;
    
    final timeParts = settings.attendanceReminderTime.split(':');
    _attendanceReminderTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    _attendanceReminderDays = settings.attendanceReminderDays.toSet();
  }

  Future<void> _saveSettings() async {
    final newSettings = ReminderSettings(
      scheduleRemindersEnabled: _scheduleRemindersEnabled,
      scheduleReminderMinutesBefore: _scheduleReminderMinutes,
      attendanceRemindersEnabled: _attendanceRemindersEnabled,
      attendanceReminderTime: '${_attendanceReminderTime.hour.toString().padLeft(2, '0')}:${_attendanceReminderTime.minute.toString().padLeft(2, '0')}',
      attendanceReminderDays: _attendanceReminderDays.toList()..sort(),
    );

    await context.read<ReminderProvider>().updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder settings saved successfully')),
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _attendanceReminderTime,
    );
    if (picked != null) {
      setState(() {
        _attendanceReminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Schedule Reminders Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Class Schedule Reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Schedule Reminders'),
                    subtitle: const Text('Get notified before scheduled classes'),
                    value: _scheduleRemindersEnabled,
                    onChanged: (value) {
                      setState(() {
                        _scheduleRemindersEnabled = value;
                      });
                    },
                  ),
                  if (_scheduleRemindersEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Remind me before'),
                      subtitle: Text('$_scheduleReminderMinutes minutes before class'),
                      trailing: DropdownButton<int>(
                        value: _scheduleReminderMinutes,
                        items: [5, 10, 15, 30, 60, 120].map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes min'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _scheduleReminderMinutes = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attendance Reminders Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Attendance Reminders'),
                    subtitle: const Text('Daily reminder to mark attendance'),
                    value: _attendanceRemindersEnabled,
                    onChanged: (value) {
                      setState(() {
                        _attendanceRemindersEnabled = value;
                      });
                    },
                  ),
                  if (_attendanceRemindersEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: Text(_attendanceReminderTime.format(context)),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: _selectTime,
                      ),
                      onTap: _selectTime,
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remind me on:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: List.generate(7, (index) {
                              final dayNumber = index + 1;
                              final isSelected = _attendanceReminderDays.contains(dayNumber);
                              return FilterChip(
                                label: Text(_dayNames[index]),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _attendanceReminderDays.add(dayNumber);
                                    } else {
                                      _attendanceReminderDays.remove(dayNumber);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reminders work offline and will be shown even when the app is closed.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
