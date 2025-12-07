import 'package:flutter/material.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:sembast/sembast.dart';

class VolunteerReport {
  final int id;
  final String volunteerName;
  final List<int> selectedStudents; // Changed to List<int>
  final String classBatch;
  final String centerName; // NEW: Center for this report
  final String inTime;
  final String outTime;
  final String activityTaught;
  final bool testConducted;
  final String? testTopic;
  final String? marksGrade;
  final List<int> testStudents; // Students who took the test
  final Map<int, String> testMarks; // Map of studentId -> marks/grade

  VolunteerReport({
    required this.id,
    required this.volunteerName,
    required this.selectedStudents,
    required this.classBatch,
    required this.centerName, // NEW: Required parameter
    required this.inTime,
    required this.outTime,
    required this.activityTaught,
    required this.testConducted,
    this.testTopic,
    this.marksGrade,
    this.testStudents = const [],
    this.testMarks = const {},
  });

  factory VolunteerReport.fromMap(Map<String, dynamic> map, int id) {
    List<int> studentIds = [];
    final selectedStudentsData = map['selected_students'] ?? map['selectedStudents'];
    if (selectedStudentsData != null) {
      try {
        studentIds = (selectedStudentsData as List).map((e) => int.parse(e.toString())).toList();
      } catch (e) {
        studentIds = [];
        print("Could not parse selected students: $e");
      }
    }
    
    List<int> testStudentIds = [];
    final testStudentsData = map['test_students'] ?? map['testStudents'];
    if (testStudentsData != null) {
      try {
        testStudentIds = (testStudentsData as List).map((e) => int.parse(e.toString())).toList();
      } catch (e) {
        testStudentIds = [];
      }
    }
    
    Map<int, String> marksMap = {};
    final testMarksData = map['test_marks'] ?? map['testMarks'];
    if (testMarksData != null) {
      (testMarksData as Map).forEach((key, value) {
        marksMap[int.parse(key.toString())] = value.toString();
      });
    }
    
    return VolunteerReport(
      id: id,
      volunteerName: map['volunteer_name'] ?? map['volunteerName'] ?? '',
      selectedStudents: studentIds,
      classBatch: map['class_batch'] ?? map['classBatch'] ?? '',
      centerName: map['center_name'] ?? map['centerName'] ?? 'Unknown',
      inTime: map['in_time'] ?? map['inTime'] ?? '',
      outTime: map['out_time'] ?? map['outTime'] ?? '',
      activityTaught: map['activity_taught'] ?? map['activityTaught'] ?? '',
      testConducted: map['test_conducted'] ?? map['testConducted'] ?? false,
      testTopic: map['test_topic'] ?? map['testTopic'],
      marksGrade: map['marks_grade'] ?? map['marksGrade'],
      testStudents: testStudentIds,
      testMarks: marksMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerName': volunteerName,
      'selectedStudents': selectedStudents,
      'classBatch': classBatch,
      'centerName': centerName, // NEW: Include center
      'inTime': inTime,
      'outTime': outTime,
      'activityTaught': activityTaught,
      'testConducted': testConducted,
      'testTopic': testTopic,
      'marksGrade': marksGrade,
      'testStudents': testStudents,
      'testMarks': testMarks.map((key, value) => MapEntry(key.toString(), value)),
    };
  }
}

class VolunteerProvider with ChangeNotifier {
  final _reportStore = intMapStoreFactory.store('volunteer_reports');
  final DatabaseService _dbService = DatabaseService();

  List<VolunteerReport> _reports = [];
  List<VolunteerReport> get reports => _reports;

  Future<void> addReport(VolunteerReport report) async {
    final db = await _dbService.database;
    // Use the provided report.id (which is a timestamp) as the record key
    // so that stored reports keep their original DateTime identity.
    await _reportStore.record(report.id).put(db, report.toMap());
    print('DEBUG: Report saved with ID: ${report.id}, Volunteer: ${report.volunteerName}');
    await fetchReports(); // refetch to update the list
  }
  
  Future<void> updateReport(VolunteerReport report) async {
    final db = await _dbService.database;
    await _reportStore.update(db, report.toMap(), finder: Finder(filter: Filter.byKey(report.id)));
    await fetchReports();
  }
  
  Future<void> deleteMultipleReports(List<int> ids, {bool syncToCloud = true}) async {
    // Get report info before deleting (needed for cloud sync)
    final reportsToDelete = _reports.where((r) => ids.contains(r.id)).toList();
    
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Delete each report by its ID
      for (var id in ids) {
        await _reportStore.record(id).delete(txn);
      }
    });
    print('✅ Deleted ${ids.length} volunteer report(s)');
    await fetchReports();
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Import the sync service
        final cloudSyncV2 = CloudSyncServiceV2();
        
        // Queue each delete operation
        for (var report in reportsToDelete) {
          await cloudSyncV2.queueVolunteerReportDelete(report.id, report.centerName);
        }
        
        // Try to process immediately if online
        await cloudSyncV2.processSyncQueue();
      } catch (e) {
        print('⚠️ Failed to sync deletes to cloud: $e');
        // Deletes are queued, will sync later
      }
    }
  }

  Future<void> fetchReports() async {
    final db = await _dbService.database;
    final snapshots = await _reportStore.find(db);
    _reports = snapshots.map((snapshot) {
      return VolunteerReport.fromMap(snapshot.value, snapshot.key);
    }).toList();
    // Sort by date descending (newest first)
    _reports.sort((a, b) => b.id.compareTo(a.id));
    print('DEBUG: fetchReports - Found ${_reports.length} reports');
    for (var r in _reports) {
      print('DEBUG: Report - ID: ${r.id}, Date: ${DateTime.fromMillisecondsSinceEpoch(r.id)}, Volunteer: ${r.volunteerName}');
    }
    notifyListeners();
  }

  // NEW: Get reports filtered by center
  List<VolunteerReport> getReportsByCenter(String centerName) {
    return _reports.where((report) => report.centerName == centerName).toList();
  }
}
