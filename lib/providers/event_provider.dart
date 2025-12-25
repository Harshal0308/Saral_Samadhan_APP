import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/event_storage_service.dart';
import 'package:samadhan_app/services/event_sync_service.dart';
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
    
    print('📝 Adding event: $title');
    print('   Photos to upload: ${photoPaths.length}');
    
    // 1. Save locally first (with local paths)
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
    final localId = await _eventStore.add(db, newEvent.toMap());
    print('✅ Event saved locally with ID: $localId');
    
    // 2. Upload photos to Supabase Storage
    List<String> photoUrls = [];
    if (photoPaths.isNotEmpty) {
      try {
        final storageService = EventStorageService();
        final photoFiles = photoPaths.map((path) => File(path)).toList();
        photoUrls = await storageService.uploadPhotos(photoFiles, localId.toString());
        print('✅ Uploaded ${photoUrls.length} photos to cloud');
        
        // Update local record with cloud URLs
        final eventWithUrls = newEvent.copyWith(
          id: localId,
          photoPaths: photoUrls,
        );
        await _eventStore.update(db, eventWithUrls.toMap(), finder: Finder(filter: Filter.byKey(localId)));
        print('✅ Updated local event with photo URLs');
      } catch (e) {
        print('⚠️ Error uploading photos: $e');
        // Continue without photos
      }
    }
    
    // 3. Sync event to Supabase database
    try {
      final syncService = EventSyncService();
      final eventToSync = newEvent.copyWith(
        id: localId,
        photoPaths: photoUrls.isNotEmpty ? photoUrls : photoPaths,
      );
      await syncService.uploadEvent(eventToSync, photoUrls);
      print('✅ Event synced to Supabase');
    } catch (e) {
      print('⚠️ Event saved locally, will sync later: $e');
    }
    
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

  /// Sync events from Supabase for a specific center
  Future<void> syncEventsFromCloud(String centerName) async {
    if (centerName.isEmpty) return;
    
    try {
      print('🔄 Syncing events from cloud for: $centerName');
      final syncService = EventSyncService();
      final cloudEvents = await syncService.downloadEventsForCenter(centerName);
      
      final db = await _dbService.database;
      
      // Merge cloud events with local
      for (var cloudEvent in cloudEvents) {
        // Check if event already exists locally by title and date
        final existing = await _eventStore.findFirst(
          db,
          finder: Finder(
            filter: Filter.and([
              Filter.equals('title', cloudEvent.title),
              Filter.equals('date', cloudEvent.date.toIso8601String()),
            ]),
          ),
        );
        
        if (existing == null) {
          // New event from cloud, add locally
          await _eventStore.add(db, cloudEvent.toMap());
          print('✅ Added event from cloud: ${cloudEvent.title}');
        } else {
          // Event exists, update if cloud has photos and local doesn't
          final localEvent = Event.fromMap(existing.value, existing.key);
          if (cloudEvent.photoPaths.isNotEmpty && localEvent.photoPaths.isEmpty) {
            await _eventStore.update(
              db,
              cloudEvent.toMap(),
              finder: Finder(filter: Filter.byKey(existing.key)),
            );
            print('✅ Updated event with cloud photos: ${cloudEvent.title}');
          }
        }
      }
      
      await loadEvents();
      print('✅ Event sync completed');
    } catch (e) {
      print('❌ Error syncing events from cloud: $e');
    }
  }
}
