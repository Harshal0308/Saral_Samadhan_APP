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
      // Check if student already exists in cloud by roll_no, class_batch, and center_name
      final existing = await _supabase
          .from('students')
          .select('id')
          .eq('roll_no', student.rollNo)
          .eq('class_batch', student.classBatch)
          .eq('center_name', student.centerName)
          .maybeSingle();

      if (existing != null) {
        // Update existing student
        await _supabase.from('students').update({
          'name': student.name,
          'lessons_learned': student.lessonsLearned,
          'test_results': student.testResults,
          'embeddings': student.embeddings,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('✅ Student updated: ${student.name}');
      } else {
        // Insert new student (let Supabase generate ID)
        await _supabase.from('students').insert({
          // Don't send local ID - let Supabase generate it
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
      }
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

  /// Delete student from Supabase by roll_no, class, and center
  Future<bool> deleteStudentFromCloud(String rollNo, String classBatch, String centerName) async {
    try {
      await _supabase
          .from('students')
          .delete()
          .eq('roll_no', rollNo)
          .eq('class_batch', classBatch)
          .eq('center_name', centerName);
      print('✅ Student deleted from cloud: $rollNo');
      return true;
    } catch (e) {
      print('❌ Error deleting student: $e');
      return false;
    }
  }

  /// Delete multiple students from Supabase
  Future<bool> deleteMultipleStudentsFromCloud(List<Map<String, String>> students) async {
    try {
      for (var student in students) {
        await deleteStudentFromCloud(
          student['rollNo']!,
          student['classBatch']!,
          student['centerName']!,
        );
      }
      print('✅ Deleted ${students.length} students from cloud');
      return true;
    } catch (e) {
      print('❌ Error deleting multiple students: $e');
      return false;
    }
  }

  // ============================================================================
  // ATTENDANCE - Sync to Cloud
  // ============================================================================

  /// Upload attendance record to Supabase
  Future<bool> uploadAttendanceRecord(AttendanceRecord record) async {
    try {
      // ✅ attendance is already Map<String, bool> (roll numbers as keys)
      final attendanceMap = record.attendance;
      
      print('📤 Uploading attendance:');
      print('   Date: ${record.date.toLocal().toString().split(' ')[0]}');
      print('   Center: ${record.centerName}');
      print('   Students: ${attendanceMap.keys.join(", ")}');
      
      // Check if attendance record already exists by date and center
      final existing = await _supabase
          .from('attendance_records')
          .select('id')
          .eq('date', record.date.toIso8601String().split('T')[0]) // Date only
          .eq('center_name', record.centerName)
          .maybeSingle();

      if (existing != null) {
        // Fetch existing attendance data to merge
        final existingRecord = await _supabase
            .from('attendance_records')
            .select('attendance')
            .eq('id', existing['id'])
            .single();
        
        // Merge existing attendance with new attendance
        final existingAttendance = Map<String, dynamic>.from(existingRecord['attendance'] ?? {});
        final mergedAttendance = {...existingAttendance, ...attendanceMap};
        
        // Update with merged data
        await _supabase.from('attendance_records').update({
          'attendance': mergedAttendance,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('✅ Attendance record merged for ${record.centerName} (${attendanceMap.length} students added/updated)');
      } else {
        // Insert new attendance record (don't send local ID)
        await _supabase.from('attendance_records').insert({
          // Don't send local ID - let Supabase generate it
          'date': record.date.toIso8601String(),
          'center_name': record.centerName,
          'attendance': attendanceMap,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Attendance record uploaded for ${record.centerName}');
      }
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
      
      // ✅ FIX: Check if report already exists by created_at timestamp and center
      final createdAt = DateTime.fromMillisecondsSinceEpoch(report.id).toIso8601String();
      final existing = await _supabase
          .from('volunteer_reports')
          .select('id')
          .eq('created_at', createdAt)
          .eq('center_name', report.centerName)
          .eq('volunteer_name', report.volunteerName)
          .maybeSingle();
      
      if (existing != null) {
        print('⚠️ Volunteer report already exists (ID: ${existing['id']}), skipping upload');
        return true; // Already uploaded, consider it success
      }
      
      // Insert new report
      await _supabase.from('volunteer_reports').insert({
        // Don't send local ID - let Supabase generate it
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
        'created_at': createdAt,
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
        // Save with the correct date from cloud record
        await attendanceProvider.saveAttendance(
          cloudRecord.attendance,
          centerName,
          date: cloudRecord.date,
        );
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
