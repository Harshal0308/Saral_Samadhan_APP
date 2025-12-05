import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';

class AttendanceRecord {
  final int id;
  final DateTime date;
  final String centerName; // NEW: Center for this attendance record
  final Map<String, bool> attendance; // ✅ FIXED: rollNo -> isPresent (stable identifier)

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.centerName, // NEW: Required parameter
    required this.attendance,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, int id) {
    final attendanceData = map['attendance'] as Map<String, dynamic>? ?? {};
    final attendance = attendanceData.map((key, value) => 
      MapEntry(key.toString(), value as bool) // ✅ Keep as string (roll number)
    );
    
    return AttendanceRecord(
      id: id,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      centerName: map['center_name'] ?? map['centerName'] ?? 'Unknown',
      attendance: attendance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'center_name': centerName, // Use Supabase field name
      'centerName': centerName, // Keep for compatibility
      'attendance': attendance, // Already Map<String, bool>
    };
  }
}

class AttendanceProvider with ChangeNotifier {
  final _attendanceStore = intMapStoreFactory.store('attendance');
  final DatabaseService _dbService = DatabaseService();

  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;

  Future<void> saveAttendance(Map<String, bool> attendance, String centerName, {DateTime? date}) async {
    final db = await _dbService.database;
    final attendanceDate = date ?? DateTime.now();
    
    print('📝 Saving attendance:');
    print('   Date: ${attendanceDate.toLocal()}');
    print('   Center: $centerName');
    print('   Students: ${attendance.length}');
    print('   Data: $attendance');
    
    // Count present/absent for verification
    final presentCount = attendance.values.where((v) => v == true).length;
    final absentCount = attendance.values.where((v) => v == false).length;
    print('   ✅ Present: $presentCount, ❌ Absent: $absentCount');
    
    // Check if attendance already exists for this date and center
    // Check both field names for compatibility
    final existingFinder = Finder(
      filter: Filter.and([
        Filter.or([
          Filter.equals('centerName', centerName),
          Filter.equals('center_name', centerName),
        ]),
        Filter.greaterThanOrEquals('date', DateTime(attendanceDate.year, attendanceDate.month, attendanceDate.day).toIso8601String()),
        Filter.lessThanOrEquals('date', DateTime(attendanceDate.year, attendanceDate.month, attendanceDate.day, 23, 59, 59).toIso8601String()),
      ]),
    );
    
    final existing = await _attendanceStore.findFirst(db, finder: existingFinder);
    
    if (existing != null) {
      // Merge with existing attendance
      print('⚠️ Found existing attendance record, merging...');
      final existingRecord = AttendanceRecord.fromMap(existing.value, existing.key);
      print('   Existing data: ${existingRecord.attendance}');
      final mergedAttendance = {...existingRecord.attendance, ...attendance};
      print('   Merged data: $mergedAttendance');
      
      await _attendanceStore.update(
        db,
        {
          'date': attendanceDate.toIso8601String(),
          'center_name': centerName,
          'centerName': centerName,
          'attendance': mergedAttendance, // Already Map<String, bool>
        },
        finder: Finder(filter: Filter.byKey(existing.key)),
      );
      print('✅ Merged attendance locally for $centerName on ${attendanceDate.toLocal().toString().split(' ')[0]}');
    } else {
      // Create new attendance record
      print('📝 Creating new attendance record...');
      final record = AttendanceRecord(
        id: 0,
        date: attendanceDate,
        centerName: centerName,
        attendance: attendance,
      );
      final savedId = await _attendanceStore.add(db, record.toMap());
      print('✅ Saved new attendance locally with ID: $savedId for $centerName on ${attendanceDate.toLocal().toString().split(' ')[0]}');
      
      // Verify what was saved
      final saved = await _attendanceStore.record(savedId).get(db);
      print('   Verification - Saved data: $saved');
    }
    
    await fetchAttendanceRecords(); // Refetch to keep the list in sync
  }

  Future<void> fetchAttendanceRecords() async {
    final db = await _dbService.database;
    final snapshots = await _attendanceStore.find(db, finder: Finder(sortOrders: [SortOrder(Field.key, false)])); // Sort by date descending
    _attendanceRecords = snapshots.map((snapshot) {
      return AttendanceRecord.fromMap(snapshot.value, snapshot.key);
    }).toList();
    notifyListeners();
  }

  Future<List<AttendanceRecord>> fetchAttendanceRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbService.database;
    // Normalize range to include entire days (inclusive)
    final DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    final Finder finder = Finder(
      filter: Filter.and([
        Filter.greaterThanOrEquals('date', startOfDay.toIso8601String()),
        Filter.lessThanOrEquals('date', endOfDay.toIso8601String()),
      ]),
      sortOrders: [SortOrder('date', false)],
    );
    final snapshots = await _attendanceStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return AttendanceRecord.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  // NEW: Get attendance records for a specific center
  List<AttendanceRecord> getAttendanceByCenter(String centerName) {
    return _attendanceRecords.where((record) => record.centerName == centerName).toList();
  }

  // NEW: Get attendance records for a specific center and date range
  Future<List<AttendanceRecord>> fetchAttendanceRecordsByCenterAndDateRange(
    String centerName,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbService.database;
    final DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    final Finder finder = Finder(
      filter: Filter.and([
        Filter.equals('centerName', centerName), // NEW: Filter by center
        Filter.greaterThanOrEquals('date', startOfDay.toIso8601String()),
        Filter.lessThanOrEquals('date', endOfDay.toIso8601String()),
      ]),
      sortOrders: [SortOrder('date', false)],
    );
    final snapshots = await _attendanceStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return AttendanceRecord.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }
}
