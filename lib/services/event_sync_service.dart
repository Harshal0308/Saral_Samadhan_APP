import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/event_provider.dart';

/// Service to sync events with Supabase
class EventSyncService {
  static final EventSyncService _instance = EventSyncService._internal();
  factory EventSyncService() => _instance;
  EventSyncService._internal();

  final _supabase = Supabase.instance.client;

  /// Upload event to Supabase
  Future<bool> uploadEvent(Event event, List<String> photoUrls) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      final eventData = {
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String().split('T')[0],
        'time': '${event.time.hour}:${event.time.minute}',
        'attendance_summary': event.attendanceSummary,
        'center_name': event.centerName,
        'class_batch': event.classBatch,
        'present_student_rolls': event.presentStudentRolls,
        'topics': event.topics,
        'photo_urls': photoUrls,
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('events').insert(eventData);

      print('✅ Event uploaded to Supabase: ${event.title}');
      return true;
    } catch (e) {
      print('❌ Error uploading event: $e');
      return false;
    }
  }

  /// Download events for a specific center
  Future<List<Event>> downloadEventsForCenter(String centerName) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('center_name', centerName)
          .order('date', ascending: false);

      final events = <Event>[];
      for (var data in response) {
        events.add(_eventFromSupabase(data));
      }

      print('✅ Downloaded ${events.length} events for center: $centerName');
      return events;
    } catch (e) {
      print('❌ Error downloading events: $e');
      return [];
    }
  }

  /// Download all events (for admin/multi-center view)
  Future<List<Event>> downloadAllEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('date', ascending: false);

      final events = <Event>[];
      for (var data in response) {
        events.add(_eventFromSupabase(data));
      }

      print('✅ Downloaded ${events.length} total events');
      return events;
    } catch (e) {
      print('❌ Error downloading all events: $e');
      return [];
    }
  }

  /// Convert Supabase data to Event object
  Event _eventFromSupabase(Map<String, dynamic> data) {
    // Parse time
    final timeParts = (data['time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    // Parse photo URLs - handle both old (photoPaths) and new (photo_urls) format
    List<String> photoUrls = [];
    if (data['photo_urls'] != null) {
      photoUrls = List<String>.from(data['photo_urls']);
    }

    return Event(
      id: data['id'] as int,
      title: data['title'] as String,
      description: data['description'] as String,
      date: DateTime.parse(data['date'] as String),
      time: time,
      attendanceSummary: data['attendance_summary'] as String? ?? 'N/A',
      photoPaths: photoUrls, // Store URLs in photoPaths for compatibility
      centerName: data['center_name'] as String? ?? '',
      classBatch: data['class_batch'] as String? ?? '',
      presentStudentRolls: data['present_student_rolls'] != null
          ? List<String>.from(data['present_student_rolls'])
          : [],
      topics: data['topics'] != null ? List<String>.from(data['topics']) : [],
    );
  }

  /// Delete event from Supabase
  Future<bool> deleteEvent(int eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);

      print('✅ Event deleted from Supabase: $eventId');
      return true;
    } catch (e) {
      print('❌ Error deleting event: $e');
      return false;
    }
  }
}
