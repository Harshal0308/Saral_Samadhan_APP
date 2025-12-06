import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/local_notification_service.dart';
import 'package:samadhan_app/models/reminder_settings.dart';
import 'package:samadhan_app/providers/schedule_provider.dart';

class ReminderProvider with ChangeNotifier {
  final _settingsStore = StoreRef<String, Map<String, dynamic>>.main();
  final DatabaseService _dbService = DatabaseService();
  final LocalNotificationService _notificationService = LocalNotificationService();

  ReminderSettings _settings = ReminderSettings();
  ReminderSettings get settings => _settings;

  static const String _settingsKey = 'reminder_settings';
  static const int _attendanceNotificationId = 999999;

  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadSettings();
  }

  Future<void> loadSettings() async {
    final db = await _dbService.database;
    final data = await _settingsStore.record(_settingsKey).get(db);
    if (data != null) {
      _settings = ReminderSettings.fromMap(data);
    }
    notifyListeners();
    
    // Reschedule attendance reminders
    await _scheduleAttendanceReminders();
  }

  Future<void> updateSettings(ReminderSettings newSettings) async {
    final db = await _dbService.database;
    await _settingsStore.record(_settingsKey).put(db, newSettings.toMap());
    _settings = newSettings;
    notifyListeners();

    // Reschedule attendance reminders
    await _scheduleAttendanceReminders();
  }

  // Schedule notification for a class schedule
  Future<void> scheduleClassReminder(ScheduleEntry schedule) async {
    if (!_settings.scheduleRemindersEnabled) return;

    final scheduledDateTime = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
      schedule.time.hour,
      schedule.time.minute,
    );

    final reminderDateTime = scheduledDateTime.subtract(
      Duration(minutes: _settings.scheduleReminderMinutesBefore),
    );

    // Only schedule if the reminder time is in the future
    if (reminderDateTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: schedule.id,
        title: 'Class Reminder',
        body: 'Class ${schedule.classBatch} on "${schedule.topic}" starts in ${_settings.scheduleReminderMinutesBefore} minutes',
        scheduledDate: reminderDateTime,
        payload: 'schedule_${schedule.id}',
      );
    }
  }

  // Cancel notification for a class schedule
  Future<void> cancelClassReminder(int scheduleId) async {
    await _notificationService.cancelNotification(scheduleId);
  }

  // Schedule attendance reminders based on settings
  Future<void> _scheduleAttendanceReminders() async {
    // Cancel existing attendance reminder
    await _notificationService.cancelNotification(_attendanceNotificationId);

    if (!_settings.attendanceRemindersEnabled) return;

    // Parse time
    final timeParts = _settings.attendanceReminderTime.split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    // Schedule daily notification
    // Note: This will show every day, but we'll check the day in the notification handler
    await _notificationService.scheduleDailyNotification(
      id: _attendanceNotificationId,
      title: 'Attendance Reminder',
      body: 'Don\'t forget to mark attendance for today\'s classes',
      time: time,
      payload: 'attendance_reminder',
    );
  }

  // Show immediate notification when schedule is added
  Future<void> showScheduleAddedNotification(ScheduleEntry schedule) async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'New Class Schedule Added',
      body: 'Class ${schedule.classBatch} scheduled for ${schedule.date.toString().split(' ')[0]} on topic "${schedule.topic}"',
      payload: 'schedule_added_${schedule.id}',
    );
  }

  // Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }
}
