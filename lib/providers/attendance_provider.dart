import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

class AttendanceRecord {
  final int id;
  final DateTime date;
  final String centerName;
  final Map<String, bool> attendance; // compositeKey -> isPresent
  final Map<String, Map<String, int>> sessionMeta; 
  // compositeKey -> {'attended': int, 'total': int}

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.centerName,
    required this.attendance,
    required this.sessionMeta,
    });

    factory AttendanceRecord.fromMap(Map<String, dynamic> map, int id) {
      final attendanceData = map['attendance'] as Map<String, dynamic>? ?? {};
      final attendance = attendanceData.map(
        (key, value) => MapEntry(key.toString(), value as bool),
      );

      // Parse sessionMeta if present; otherwise empty map
      final rawMeta = map['sessionMeta'] as Map<String, dynamic>? ?? {};
      final Map<String, Map<String, int>> sessionMeta = {};

      rawMeta.forEach((key, value) {
        final inner = <String, int>{};
        if (value is Map) {
          value.forEach((k, v) {
            if (v is num) {
              inner[k.toString()] = v.toInt();
            }
          });
        }
        sessionMeta[key.toString()] = inner;
      });

      return AttendanceRecord(
        id: id,
        date: DateTime.parse(
          map['date'] ?? DateTime.now().toIso8601String(),
        ),
        centerName: map['center_name'] ?? map['centerName'] ?? 'Unknown',
        attendance: attendance,
        sessionMeta: sessionMeta,
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'date': date.toIso8601String(),
        'center_name': centerName,
        'centerName': centerName,
        'attendance': attendance,
        'sessionMeta': sessionMeta,
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
    
    print('\n═══════════════════════════════════════════════════════');
    print('📝 SAVING ATTENDANCE');
    print('═══════════════════════════════════════════════════════');
    print('   Date: ${attendanceDate.toLocal().toString().split(' ')[0]}');
    print('   Time: ${attendanceDate.toLocal().toString().split(' ')[1]}');
    print('   Center: "$centerName"');
    print('   Students: ${attendance.length}');
    
    // Count present/absent for verification
    final presentCount = attendance.values.where((v) => v == true).length;
    final absentCount = attendance.values.where((v) => v == false).length;
    print('   ✅ Present: $presentCount, ❌ Absent: $absentCount');
    print('   Composite Keys: ${attendance.keys.take(3).join(", ")}${attendance.length > 3 ? "..." : ""}');
    
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
      print('⚠️ Found existing attendance record (ID: ${existing.key}), merging...');
      final existingRecord = AttendanceRecord.fromMap(existing.value, existing.key);
      print('   Existing students: ${existingRecord.attendance.length}');
      print('   Existing present: ${existingRecord.attendance.values.where((v) => v == true).length}');
      final mergedAttendance = {...existingRecord.attendance, ...attendance};
      print('   After merge: ${mergedAttendance.length} students');
      print('   After merge present: ${mergedAttendance.values.where((v) => v == true).length}');
      
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
      print('✅ MERGED attendance record (ID: ${existing.key})');
    } else {
      // Create new attendance record
      print('📝 No existing record found, creating new...');
      final record = AttendanceRecord(
        id: 0,
        date: attendanceDate,
        centerName: centerName,
        attendance: attendance,
        sessionMeta: {}, // no session meta when using this path
      );
      final savedId = await _attendanceStore.add(db, record.toMap());
      print('✅ CREATED new attendance record (ID: $savedId)');
      
      // Verify what was saved
      final saved = await _attendanceStore.record(savedId).get(db);
      if (saved != null) {
        final verifyRecord = AttendanceRecord.fromMap(saved, savedId);
        print('   ✓ Verified: ${verifyRecord.attendance.length} students saved');
        print('   ✓ Date: ${verifyRecord.date.toLocal().toString().split(' ')[0]}');
        print('   ✓ Center: "${verifyRecord.centerName}"');
      }
    }
    
    print('═══════════════════════════════════════════════════════\n');
    
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

  /// Delete attendance record
  Future<void> deleteAttendanceRecord(int id, String centerName, DateTime date, {bool syncToCloud = true}) async {
    final db = await _dbService.database;
    await _attendanceStore.delete(db, finder: Finder(filter: Filter.byKey(id)));
    await fetchAttendanceRecords();
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        final cloudSyncV2 = CloudSyncServiceV2();
        
        // Queue the delete operation
        await cloudSyncV2.queueAttendanceDelete(date, centerName);
        
        // Try to process immediately if online
        await cloudSyncV2.processSyncQueue();
      } catch (e) {
        print('⚠️ Failed to sync delete to cloud: $e');
        // Delete is queued, will sync later
      }
    }
  }
}
