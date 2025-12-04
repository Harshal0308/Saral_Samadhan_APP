import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';

/// Service to sync local data with Supabase cloud
/// Allows multiple teachers in the same center to access shared data
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  // ============================================================================
  // STUDENTS - Sync to Cloud
  // ============================================================================

  /// Upload student to Supabase
  Future<bool> uploadStudent(Student student) async {
    try {
      await _supabase.from('students').upsert({
        'id': student.id,
        'name': student.name,
        'roll_no': student.rollNo,
        'class_batch': student.classBatch,
        'center_name': student.centerName,
        'lessons_learned': student.lessonsLearned,
        'test_results': student.testResults,
        'embeddings': student.embeddings,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Student uploaded: ${student.name}');
      return true;
    } catch (e) {
      print('❌ Error uploading student: $e');
      return false;
    }
  }

  /// Download all students for a center from Supabase
  Future<List<Student>> downloadStudentsForCenter(String centerName) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('center_name', centerName);

      final students = <Student>[];
      for (var data in response) {
        students.add(Student.fromMap(data, data['id'] as int));
      }
      print('✅ Downloaded ${students.length} students for center: $centerName');
      return students;
    } catch (e) {
      print('❌ Error downloading students: $e');
      return [];
    }
  }

  /// Delete student from Supabase
  Future<bool> deleteStudentFromCloud(int studentId) async {
    try {
      await _supabase.from('students').delete().eq('id', studentId);
      print('✅ Student deleted from cloud: $studentId');
      return true;
    } catch (e) {
      print('❌ Error deleting student: $e');
      return false;
    }
  }

  // ============================================================================
  // ATTENDANCE - Sync to Cloud
  // ============================================================================

  /// Upload attendance record to Supabase
  Future<bool> uploadAttendanceRecord(AttendanceRecord record) async {
    try {
      // Convert attendance map with int keys to string keys for JSON encoding
      final attendanceMap = record.attendance.map((key, value) => 
        MapEntry(key.toString(), value)
      );
      
      await _supabase.from('attendance_records').insert({
        'id': record.id,
        'date': record.date.toIso8601String(),
        'center_name': record.centerName,
        'attendance': attendanceMap,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Attendance record uploaded for ${record.centerName}');
      return true;
    } catch (e) {
      print('❌ Error uploading attendance: $e');
      return false;
    }
  }

  /// Download attendance records for a center
  Future<List<AttendanceRecord>> downloadAttendanceForCenter(String centerName) async {
    try {
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('center_name', centerName)
          .order('date', ascending: false);

      final records = <AttendanceRecord>[];
      for (var data in response) {
        records.add(AttendanceRecord.fromMap(data, data['id'] as int));
      }
      print('✅ Downloaded ${records.length} attendance records for center: $centerName');
      return records;
    } catch (e) {
      print('❌ Error downloading attendance: $e');
      return [];
    }
  }

  // ============================================================================
  // VOLUNTEER REPORTS - Sync to Cloud
  // ============================================================================

  /// Upload volunteer report to Supabase
  Future<bool> uploadVolunteerReport(VolunteerReport report) async {
    try {
      // Convert test_marks map with int keys to string keys for JSON encoding
      final testMarksMap = report.testMarks.map((key, value) => 
        MapEntry(key.toString(), value)
      );
      
      await _supabase.from('volunteer_reports').insert({
        'id': report.id,
        'volunteer_name': report.volunteerName,
        'selected_students': report.selectedStudents,
        'class_batch': report.classBatch,
        'center_name': report.centerName,
        'in_time': report.inTime,
        'out_time': report.outTime,
        'activity_taught': report.activityTaught,
        'test_conducted': report.testConducted,
        'test_topic': report.testTopic,
        'marks_grade': report.marksGrade,
        'test_students': report.testStudents,
        'test_marks': testMarksMap,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Volunteer report uploaded for ${report.centerName}');
      return true;
    } catch (e) {
      print('❌ Error uploading volunteer report: $e');
      return false;
    }
  }

  /// Download volunteer reports for a center
  Future<List<VolunteerReport>> downloadVolunteerReportsForCenter(String centerName) async {
    try {
      final response = await _supabase
          .from('volunteer_reports')
          .select()
          .eq('center_name', centerName)
          .order('id', ascending: false);

      final reports = <VolunteerReport>[];
      for (var data in response) {
        reports.add(VolunteerReport.fromMap(data, data['id'] as int));
      }
      print('✅ Downloaded ${reports.length} volunteer reports for center: $centerName');
      return reports;
    } catch (e) {
      print('❌ Error downloading volunteer reports: $e');
      return [];
    }
  }

  // ============================================================================
  // FULL SYNC - Sync all data for a center
  // ============================================================================

  /// Full sync: Upload local data and download cloud data
  Future<bool> fullSyncForCenter(
    String centerName,
    StudentProvider studentProvider,
    AttendanceProvider attendanceProvider,
    VolunteerProvider volunteerProvider,
  ) async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress');
      return false;
    }

    _isSyncing = true;
    try {
      print('🔄 Starting full sync for center: $centerName');

      // 1. Upload local students
      final centerStudents = studentProvider.getStudentsByCenter(centerName);
      for (var student in centerStudents) {
        await uploadStudent(student);
      }

      // 2. Download students from cloud
      final cloudStudents = await downloadStudentsForCenter(centerName);
      // Merge with local students (cloud data takes precedence)
      for (var cloudStudent in cloudStudents) {
        final localIndex = centerStudents.indexWhere((s) => s.id == cloudStudent.id);
        if (localIndex == -1) {
          // New student from another teacher, add locally
          await studentProvider.addStudent(
            name: cloudStudent.name,
            rollNo: cloudStudent.rollNo,
            classBatch: cloudStudent.classBatch,
            centerName: cloudStudent.centerName,
            embeddings: cloudStudent.embeddings,
          );
        }
      }

      // 3. Upload local attendance records
      final centerAttendance = attendanceProvider.getAttendanceByCenter(centerName);
      for (var record in centerAttendance) {
        await uploadAttendanceRecord(record);
      }

      // 4. Download attendance from cloud
      final cloudAttendance = await downloadAttendanceForCenter(centerName);
      // Merge with local attendance
      for (var cloudRecord in cloudAttendance) {
        final localIndex = centerAttendance.indexWhere((r) => r.id == cloudRecord.id);
        if (localIndex == -1) {
          // New attendance record from another teacher
          await attendanceProvider.saveAttendance(cloudRecord.attendance, centerName);
        }
      }

      // 5. Upload local volunteer reports
      final centerReports = volunteerProvider.getReportsByCenter(centerName);
      for (var report in centerReports) {
        await uploadVolunteerReport(report);
      }

      // 6. Download volunteer reports from cloud
      final cloudReports = await downloadVolunteerReportsForCenter(centerName);
      // Merge with local reports
      for (var cloudReport in cloudReports) {
        final localIndex = centerReports.indexWhere((r) => r.id == cloudReport.id);
        if (localIndex == -1) {
          // New report from another teacher
          await volunteerProvider.addReport(cloudReport);
        }
      }

      print('✅ Full sync completed for center: $centerName');
      return true;
    } catch (e) {
      print('❌ Error during full sync: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Periodic sync (call this periodically to keep data in sync)
  Future<void> startPeriodicSync(
    String centerName,
    StudentProvider studentProvider,
    AttendanceProvider attendanceProvider,
    VolunteerProvider volunteerProvider,
  ) async {
    // Sync every 30 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      await fullSyncForCenter(
        centerName,
        studentProvider,
        attendanceProvider,
        volunteerProvider,
      );
    }
  }
}
