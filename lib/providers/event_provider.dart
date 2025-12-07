import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:intl/intl.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final String attendanceSummary;
  final List<String> photoPaths;

  // NEW: richer context to connect to student reports
  final String classBatch;              // e.g. "6"
  final String centerName;              // e.g. "Center A"
  final List<String> presentStudentRolls; // roll numbers present in this session
  final List<String> topics;            // topics taught in this session

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.attendanceSummary = 'N/A',
    this.photoPaths = const [],
    this.classBatch = '',
    this.centerName = '',
    this.presentStudentRolls = const [],
    this.topics = const [],
  });

  factory Event.fromMap(Map<String, dynamic> map, int id) {
    TimeOfDay parsedTime;

    try {
      // Try parsing as HH:MM (e.g., "15:30")
      final parts = (map['time'] as String).split(':');
      parsedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      // If HH:MM fails, try parsing as h:mm a (e.g., "3:30 PM")
      try {
        final dateTime = DateFormat('h:mm a').parse(map['time'] as String);
        parsedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } catch (e2) {
        // Fallback
        parsedTime = TimeOfDay.now();
      }
    }

    return Event(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      time: parsedTime,
      attendanceSummary: (map['attendanceSummary'] as String?) ?? 'N/A',
      photoPaths: List<String>.from((map['photoPaths'] as List?) ?? const []),

      // NEW (safe defaults for old records)
      classBatch: map['classBatch'] as String? ?? '',
      centerName: map['centerName'] as String? ?? '',
      presentStudentRolls:
          List<String>.from((map['presentStudentRolls'] as List?) ?? const []),
      topics: List<String>.from((map['topics'] as List?) ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}', // Always HH:MM
      'attendanceSummary': attendanceSummary,
      'photoPaths': photoPaths,

      // NEW
      'classBatch': classBatch,
      'centerName': centerName,
      'presentStudentRolls': presentStudentRolls,
      'topics': topics,
    };
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    String? attendanceSummary,
    List<String>? photoPaths,
    String? classBatch,
    String? centerName,
    List<String>? presentStudentRolls,
    List<String>? topics,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      photoPaths: photoPaths ?? this.photoPaths,
      classBatch: classBatch ?? this.classBatch,
      centerName: centerName ?? this.centerName,
      presentStudentRolls: presentStudentRolls ?? this.presentStudentRolls,
      topics: topics ?? this.topics,
    );
  }
}

class EventProvider with ChangeNotifier {
  final _eventStore = intMapStoreFactory.store('events');
  final DatabaseService _dbService = DatabaseService();

  List<Event> _events = [];
  List<Event> get events => _events;

  // NEW: in-memory draft sessions for the current volunteer/day
  final List<Event> _draftEvents = [];
  List<Event> get draftEvents => List.unmodifiable(_draftEvents);

  Future<void> loadEvents() async {
    final db = await _dbService.database;
    final snapshots = await _eventStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('date', false)]),
    );
    _events = snapshots
        .map((snapshot) => Event.fromMap(snapshot.value, snapshot.key))
        .toList();
    notifyListeners();
  }

  /// Existing "fire-and-forget" event creation (still used if you don't want preview).
  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    String attendanceSummary = 'N/A',
    List<String> photoPaths = const [],
    String classBatch = '',
    String centerName = '',
    List<String> presentStudentRolls = const [],
    List<String> topics = const [],
  }) async {
    final db = await _dbService.database;
    final newEvent = Event(
      id: 0, // Sembast generates ID
      title: title,
      description: description,
      date: date,
      time: time,
      attendanceSummary: attendanceSummary,
      photoPaths: photoPaths,
      classBatch: classBatch,
      centerName: centerName,
      presentStudentRolls: presentStudentRolls,
      topics: topics,
    );
    await _eventStore.add(db, newEvent.toMap());
    await loadEvents();
  }

  /// NEW: Add a teaching session to the in-memory daily report (not yet committed to DB).
  void addDraftSession({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required String classBatch,
    required String centerName,
    List<String> presentStudentRolls = const [],
    List<String> topics = const [],
    String attendanceSummary = 'N/A',
    List<String> photoPaths = const [],
  }) {
    final tempId = -(_draftEvents.length + 1); // temporary in-memory ID

    final draftEvent = Event(
      id: tempId,
      title: title,
      description: description,
      date: date,
      time: time,
      attendanceSummary: attendanceSummary,
      photoPaths: photoPaths,
      classBatch: classBatch,
      centerName: centerName,
      presentStudentRolls: presentStudentRolls,
      topics: topics,
    );

    _draftEvents.add(draftEvent);
    notifyListeners();
  }

  /// NEW: Remove a specific draft session (e.g. from preview screen).
  void removeDraftSession(Event event) {
    _draftEvents.removeWhere((e) => e.id == event.id);
    notifyListeners();
  }

  /// NEW: Clear all drafts (e.g. when user cancels the daily report).
  void clearDrafts() {
    _draftEvents.clear();
    notifyListeners();
  }

  /// NEW: Commit all draft sessions as a single "daily report".
  /// This is where student reports & attendance can be updated.
  Future<void> submitDailyReport() async {
    if (_draftEvents.isEmpty) return;

    final db = await _dbService.database;

    // Write each draft session into the persistent events store
    await db.transaction((txn) async {
    for (final draft in _draftEvents) {
      // 1. Save the event/session itself
      await _eventStore.add(txn, draft.toMap());

      // 2. UPDATE ATTENDANCE STORE
      final attendanceStore = stringMapStoreFactory.store('attendance_store');

      final sessionDate = DateFormat('yyyy-MM-dd').format(draft.date);

      for (final roll in draft.presentStudentRolls) {
        final key = "${roll}_${draft.classBatch}_$sessionDate";

        await attendanceStore.record(key).put(txn, {
          'studentRollNo': roll,
          'classBatch': draft.classBatch,
          'date': sessionDate,
          'status': 'present',
        });
      }
    }
  });

    // Clear drafts after commit
    _draftEvents.clear();

    // Reload events to keep UI up-to-date
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    final db = await _dbService.database;
    await _eventStore.update(
      db,
      event.toMap(),
      finder: Finder(filter: Filter.byKey(event.id)),
    );
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    final db = await _dbService.database;
    await _eventStore.delete(
      db,
      finder: Finder(filter: Filter.byKey(id)),
    );
    await loadEvents();
  }
}
