import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDataProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _volunteerReports = [];
  List<Map<String, dynamic>> _volunteers = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _schedules = [];
  
  // Stats
  Map<String, int> _stats = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get attendance => _attendance;
  List<Map<String, dynamic>> get volunteerReports => _volunteerReports;
  List<Map<String, dynamic>> get volunteers => _volunteers;
  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get schedules => _schedules;
  Map<String, int> get stats => _stats;

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchStudents(),
        fetchTeachers(),
        fetchAttendance(),
        fetchVolunteerReports(),
        fetchVolunteers(),
        fetchEvents(),
        fetchSchedules(),
      ]);
      _updateStats();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateStats() {
    _stats = {
      'students': _students.length,
      'teachers': _teachers.length,
      'attendance': _attendance.length,
      'volunteerReports': _volunteerReports.length,
      'volunteers': _volunteers.length,
      'events': _events.length,
      'schedules': _schedules.length,
    };
  }

  Future<void> fetchStudents() async {
    try {
      final response = await _supabase.from('students').select().order('created_at', ascending: false);
      _students = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> fetchTeachers() async {
    try {
      final response = await _supabase.from('teachers').select().order('created_at', ascending: false);
      _teachers = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  Future<void> fetchAttendance() async {
    try {
      final response = await _supabase.from('attendance').select().order('date', ascending: false);
      _attendance = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }

  Future<void> fetchVolunteerReports() async {
    try {
      final response = await _supabase.from('volunteer_reports').select().order('created_at', ascending: false);
      _volunteerReports = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching volunteer reports: $e');
    }
  }

  Future<void> fetchVolunteers() async {
    try {
      final response = await _supabase.from('volunteers').select().order('created_at', ascending: false);
      _volunteers = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching volunteers: $e');
    }
  }

  Future<void> fetchEvents() async {
    try {
      final response = await _supabase.from('events').select().order('date', ascending: false);
      _events = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> fetchSchedules() async {
    try {
      final response = await _supabase.from('schedules').select().order('date', ascending: false);
      _schedules = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching schedules: $e');
    }
  }

  // CRUD Operations
  Future<bool> deleteRecord(String table, dynamic id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      await loadAllData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(String table, dynamic id, Map<String, dynamic> data) async {
    try {
      await _supabase.from(table).update(data).eq('id', id);
      await loadAllData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> insertRecord(String table, Map<String, dynamic> data) async {
    try {
      await _supabase.from(table).insert(data);
      await loadAllData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<String> getUniqueCenters() {
    final centers = <String>{};
    for (var s in _students) {
      if (s['center_name'] != null) centers.add(s['center_name']);
    }
    return centers.toList()..sort();
  }

  List<String> getUniqueClasses() {
    final classes = <String>{};
    for (var s in _students) {
      if (s['class_batch'] != null) classes.add(s['class_batch']);
    }
    return classes.toList()..sort();
  }
}
