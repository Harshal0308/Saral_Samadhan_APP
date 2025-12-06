import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:samadhan_app/providers/reminder_provider.dart';

class ScheduleEntry {
  final int id;
  final String classBatch;
  final DateTime date;
  final TimeOfDay time;
  final String topic;

  ScheduleEntry({
    required this.id,
    required this.classBatch,
    required this.date,
    required this.time,
    required this.topic,
  });

  factory ScheduleEntry.fromMap(Map<String, dynamic> map, int id) {
    TimeOfDay parsedTime;
    try {
      // Try parsing as HH:MM (e.g., "15:30")
      final parts = map['time'].split(':');
      parsedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      // If HH:MM fails, try parsing as h:mm a (e.g., "3:30 PM")
      try {
        final dateTime = DateFormat('h:mm a').parse(map['time']);
        parsedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } catch (e2) {
        // Fallback or rethrow if even 'h:mm a' fails
        print('Warning: Could not parse time string "${map['time']}". Error: $e2');
        parsedTime = TimeOfDay.now(); // Fallback to current time
      }
    }

    return ScheduleEntry(
      id: id,
      classBatch: map['classBatch'] as String,
      date: DateTime.parse(map['date'] as String),
      time: parsedTime,
      topic: map['topic'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classBatch': classBatch,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}', // Always store in HH:MM format
      'topic': topic,
    };
  }

  ScheduleEntry copyWith({
    int? id,
    String? classBatch,
    DateTime? date,
    TimeOfDay? time,
    String? topic,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      classBatch: classBatch ?? this.classBatch,
      date: date ?? this.date,
      time: time ?? this.time,
      topic: topic ?? this.topic,
    );
  }
}

class ScheduleProvider with ChangeNotifier {
  final _scheduleStore = intMapStoreFactory.store('schedules');
  final DatabaseService _dbService = DatabaseService();

  List<ScheduleEntry> _schedules = [];
  List<ScheduleEntry> get schedules => _schedules;
  
  ReminderProvider? _reminderProvider;
  
  void setReminderProvider(ReminderProvider provider) {
    _reminderProvider = provider;
  }

  Future<void> loadSchedules() async {
    final db = await _dbService.database;
    final snapshots = await _scheduleStore.find(db, finder: Finder(sortOrders: [SortOrder('date', false)])); // Sort by date descending
    _schedules = snapshots.map((snapshot) {
      return ScheduleEntry.fromMap(snapshot.value, snapshot.key);
    }).toList();
    notifyListeners();
  }

  Future<void> addSchedule({
    required String classBatch,
    required DateTime date,
    required TimeOfDay time,
    required String topic,
  }) async {
    final db = await _dbService.database;
    final newEntry = ScheduleEntry(
      id: 0, // Sembast generates ID
      classBatch: classBatch,
      date: date,
      time: time,
      topic: topic,
    );
    final id = await _scheduleStore.add(db, newEntry.toMap());
    await loadSchedules();
    
    // Schedule reminder notification
    final addedEntry = _schedules.firstWhere((s) => s.id == id);
    if (_reminderProvider != null) {
      await _reminderProvider!.scheduleClassReminder(addedEntry);
      await _reminderProvider!.showScheduleAddedNotification(addedEntry);
    }
  }

  Future<void> updateSchedule(ScheduleEntry entry) async {
    final db = await _dbService.database;
    await _scheduleStore.update(db, entry.toMap(), finder: Finder(filter: Filter.byKey(entry.id)));
    await loadSchedules();
    
    // Reschedule reminder notification
    if (_reminderProvider != null) {
      await _reminderProvider!.cancelClassReminder(entry.id);
      await _reminderProvider!.scheduleClassReminder(entry);
    }
  }

  Future<void> deleteSchedule(int id) async {
    final db = await _dbService.database;
    await _scheduleStore.delete(db, finder: Finder(filter: Filter.byKey(id)));
    await loadSchedules();
    
    // Cancel reminder notification
    if (_reminderProvider != null) {
      await _reminderProvider!.cancelClassReminder(id);
    }
  }
}
