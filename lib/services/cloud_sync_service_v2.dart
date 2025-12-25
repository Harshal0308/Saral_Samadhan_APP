import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/sync_queue_service.dart';
import 'package:samadhan_app/models/sync_queue_item.dart';
import 'package:samadhan_app/models/baseline_assessment.dart'; // For TopicEvaluation
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enhanced cloud sync service with queue-based synchronization
/// Prevents data loss and provides better error handling
class CloudSyncServiceV2 {
  static final CloudSyncServiceV2 _instance = CloudSyncServiceV2._internal();
  factory CloudSyncServiceV2() => _instance;
  CloudSyncServiceV2._internal();

  final _supabase = Supabase.instance.client;
  final _syncQueue = SyncQueueService();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  
  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.mobile) || 
             result.contains(ConnectivityResult.wifi);
    } catch (e) {
      print('⚠️ Error checking connectivity: $e');
      return false; // Assume offline if check fails
    }
  }

  // ============================================================================
  // QUEUE-BASED OPERATIONS
  // ============================================================================

  /// Add student to sync queue (doesn't upload immediately)
  Future<void> queueStudentUpload(Student student) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.student,
      operation: SyncOperation.create,
      entityId: student.id,
      data: {
        'id': student.id,
        'name': student.name,
        'roll_no': student.rollNo,
        'class_batch': student.classBatch,
        'center_name': student.centerName,
        'lessons_learned': student.lessonsLearned,
        'test_results': student.testResults,
        'embeddings': student.embeddings,
      },
      centerName: student.centerName,
    );
  }

  /// Add student update to sync queue
  Future<void> queueStudentUpdate(Student student) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.student,
      operation: SyncOperation.update,
      entityId: student.id,
      data: {
        'id': student.id,
        'name': student.name,
        'roll_no': student.rollNo,
        'class_batch': student.classBatch,
        'center_name': student.centerName,
        'lessons_learned': student.lessonsLearned,
        'test_results': student.testResults,
        'embeddings': student.embeddings,
      },
      centerName: student.centerName,
    );
  }

  /// Add attendance to sync queue
  Future<void> queueAttendanceUpload(AttendanceRecord record) async {
    final attendanceMap = record.attendance.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    await _syncQueue.addToQueue(
      entityType: SyncEntityType.attendance,
      operation: SyncOperation.create,
      entityId: record.id,
      data: {
        'id': record.id,
        'date': record.date.toIso8601String(),
        'center_name': record.centerName,
        'attendance': attendanceMap,
      },
      centerName: record.centerName,
    );
  }

  /// Add volunteer report to sync queue
  Future<void> queueVolunteerReportUpload(VolunteerReport report) async {
    final testMarksMap = report.testMarks.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    await _syncQueue.addToQueue(
      entityType: SyncEntityType.volunteerReport,
      operation: SyncOperation.create,
      entityId: report.id,
      data: {
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
      },
      centerName: report.centerName,
    );
  }

  /// Add student deletion to sync queue
  Future<void> queueStudentDelete(String rollNo, String classBatch, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.student,
      operation: SyncOperation.delete,
      entityId: 0, // Not used for deletes
      data: {
        'roll_no': rollNo,
        'class_batch': classBatch,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  /// Add volunteer report deletion to sync queue
  Future<void> queueVolunteerReportDelete(int reportId, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.volunteerReport,
      operation: SyncOperation.delete,
      entityId: reportId,
      data: {
        'id': reportId,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  /// Add attendance deletion to sync queue
  Future<void> queueAttendanceDelete(DateTime date, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.attendance,
      operation: SyncOperation.delete,
      entityId: 0,
      data: {
        'date': date.toIso8601String(),
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  /// Add topic evaluation to sync queue
  Future<void> queueTopicEvaluationUpload(TopicEvaluation evaluation, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.topicEvaluation,
      operation: SyncOperation.create,
      entityId: 0, // Evaluations don't have IDs until created in DB
      data: {
        'student_id': evaluation.studentId,
        'subject': evaluation.subject,
        'topic': evaluation.topic,
        'evaluation': evaluation.evaluation.name,
        'evaluated_by': evaluation.evaluatedBy,
        'evaluated_on': evaluation.evaluatedOn.toIso8601String(),
      },
      centerName: centerName,
    );
  }

  // ============================================================================
  // PROCESS SYNC QUEUE
  // ============================================================================

  /// Process all pending items in sync queue
  Future<Map<String, dynamic>> processSyncQueue() async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress');
      return {'success': false, 'message': 'Sync already in progress'};
    }

    // Check connectivity before attempting sync
    final online = await isOnline();
    if (!online) {
      print('⚠️ Device is offline - skipping sync');
      return {
        'success': false,
        'message': 'Device is offline. Changes will sync when online.',
        'successCount': 0,
        'failureCount': 0,
      };
    }

    _isSyncing = true;
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    try {
      print('🔄 Starting sync queue processing...');

      // Get all pending items
      final pendingItems = await _syncQueue.getPendingItems();
      print('📋 Found ${pendingItems.length} pending items in queue');

      if (pendingItems.isEmpty) {
        return {
          'success': true,
          'message': 'No pending items to sync',
          'successCount': 0,
          'failureCount': 0,
        };
      }

      // Process each item
      for (var item in pendingItems) {
        try {
          await _syncQueue.markInProgress(item.id);

          // Upload/delete based on entity type and operation
          bool uploaded = false;
          switch (item.entityType) {
            case SyncEntityType.student:
              if (item.operation == SyncOperation.delete) {
                uploaded = await _deleteStudentFromQueue(item);
              } else if (item.operation == SyncOperation.update) {
                uploaded = await _updateStudentFromQueue(item);
              } else {
                uploaded = await _uploadStudentFromQueue(item);
              }
              break;
            case SyncEntityType.attendance:
              if (item.operation == SyncOperation.delete) {
                uploaded = await _deleteAttendanceFromQueue(item);
              } else {
                uploaded = await _uploadAttendanceFromQueue(item);
              }
              break;
            case SyncEntityType.volunteerReport:
              if (item.operation == SyncOperation.delete) {
                uploaded = await _deleteVolunteerReportFromQueue(item);
              } else {
                uploaded = await _uploadVolunteerReportFromQueue(item);
              }
              break;
            case SyncEntityType.topicEvaluation:
              uploaded = await _uploadTopicEvaluationFromQueue(item);
              break;
          }

          if (uploaded) {
            await _syncQueue.markCompleted(item.id);
            successCount++;
          } else {
            await _syncQueue.markFailed(item.id, 'Upload failed');
            failureCount++;
            errors.add('${item.entityType.name} ${item.entityId}: Upload failed');
          }
        } catch (e) {
          await _syncQueue.markFailed(item.id, e.toString());
          failureCount++;
          errors.add('${item.entityType.name} ${item.entityId}: $e');
          print('❌ Error syncing item ${item.id}: $e');
        }

        // Small delay to prevent rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✅ Sync queue processing completed');
      print('   Success: $successCount, Failed: $failureCount');

      return {
        'success': failureCount == 0,
        'message': 'Synced $successCount items, $failureCount failed',
        'successCount': successCount,
        'failureCount': failureCount,
        'errors': errors,
      };
    } catch (e) {
      print('❌ Error processing sync queue: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'successCount': successCount,
        'failureCount': failureCount,
        'errors': errors,
      };
    } finally {
      _isSyncing = false;
    }
  }

  // ============================================================================
  // UPLOAD HELPERS
  // ============================================================================

  Future<bool> _uploadStudentFromQueue(SyncQueueItem item) async {
    try {
      // Check if student already exists in cloud by roll_no, class_batch, and center_name
      final existing = await _supabase
          .from('students')
          .select('id')
          .eq('roll_no', item.data['roll_no'])
          .eq('class_batch', item.data['class_batch'])
          .eq('center_name', item.data['center_name'])
          .maybeSingle();

      if (existing != null) {
        // Update existing student
        await _supabase.from('students').update({
          'name': item.data['name'],
          'lessons_learned': item.data['lessons_learned'],
          'test_results': item.data['test_results'],
          'embeddings': item.data['embeddings'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('✅ Updated student: ${item.data['name']}');
      } else {
        // Insert new student (don't send local ID - let Supabase generate it)
        final dataToInsert = Map<String, dynamic>.from(item.data);
        dataToInsert.remove('id'); // Remove local ID
        dataToInsert['created_at'] = DateTime.now().toIso8601String();
        
        await _supabase.from('students').insert(dataToInsert);
        print('✅ Uploaded student: ${item.data['name']}');
      }
      return true;
    } catch (e) {
      print('❌ Error uploading student: $e');
      return false;
    }
  }

  Future<bool> _updateStudentFromQueue(SyncQueueItem item) async {
    try {
      // Find student by composite key and update
      final existing = await _supabase
          .from('students')
          .select('id')
          .eq('roll_no', item.data['roll_no'])
          .eq('class_batch', item.data['class_batch'])
          .eq('center_name', item.data['center_name'])
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('students').update({
          'name': item.data['name'],
          'lessons_learned': item.data['lessons_learned'],
          'test_results': item.data['test_results'],
          'embeddings': item.data['embeddings'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('✅ Updated student in cloud: ${item.data['name']}');
        return true;
      } else {
        print('⚠️ Student not found in cloud for update, will create instead');
        return await _uploadStudentFromQueue(item);
      }
    } catch (e) {
      print('❌ Error updating student: $e');
      return false;
    }
  }

  Future<bool> _deleteStudentFromQueue(SyncQueueItem item) async {
    try {
      await _supabase
          .from('students')
          .delete()
          .eq('roll_no', item.data['roll_no'])
          .eq('class_batch', item.data['class_batch'])
          .eq('center_name', item.data['center_name']);
      print('✅ Deleted student from cloud: ${item.data['roll_no']}');
      return true;
    } catch (e) {
      print('❌ Error deleting student: $e');
      return false;
    }
  }

  Future<bool> _uploadAttendanceFromQueue(SyncQueueItem item) async {
    try {
      // Extract and normalize the date
      final dateString = item.data['date'].toString().split('T')[0]; // Date only (YYYY-MM-DD)
      final centerName = item.data['center_name'];
      
      print('📤 Uploading attendance:');
      print('   Date: $dateString');
      print('   Center: $centerName');
      print('   Students: ${(item.data['attendance'] as Map).length}');
      
      // Check if attendance record already exists by date and center
      final existing = await _supabase
          .from('attendance_records')
          .select('id, date, attendance')
          .eq('date', dateString)
          .eq('center_name', centerName)
          .maybeSingle();

      if (existing != null) {
        print('⚠️ Found existing record for $dateString:');
        print('   Existing ID: ${existing['id']}');
        print('   Existing date: ${existing['date']}');
        print('   Existing students: ${(existing['attendance'] as Map).length}');
        
        // Merge existing attendance with new attendance
        final existingAttendance = Map<String, dynamic>.from(existing['attendance'] ?? {});
        final newAttendance = Map<String, dynamic>.from(item.data['attendance']);
        
        // ✅ FIX: Convert old format to new format before merging
        // Old format: {"1": true, "2": false} → just roll numbers
        // New format: {"1_Class5": true, "2_Class6": false} → composite keys
        final normalizedExisting = <String, dynamic>{};
        existingAttendance.forEach((key, value) {
          // If key doesn't contain underscore, it's old format - keep as is for now
          // New format keys will override old format keys during merge
          normalizedExisting[key] = value;
        });
        
        final mergedAttendance = {...normalizedExisting, ...newAttendance};
        
        // Update with merged data
        await _supabase.from('attendance_records').update({
          'attendance': mergedAttendance,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('✅ Merged attendance for $centerName on $dateString');
        print('   Total after merge: ${mergedAttendance.length} students');
        print('   Old format keys: ${existingAttendance.keys.take(3).join(", ")}');
        print('   New format keys: ${newAttendance.keys.take(3).join(", ")}');
      } else {
        print('📝 No existing record for $dateString, creating new...');
        
        // Insert new attendance record (don't send local ID)
        final dataToInsert = Map<String, dynamic>.from(item.data);
        dataToInsert.remove('id'); // Remove local ID
        dataToInsert.remove('user_id'); // Remove user_id if present
        dataToInsert['date'] = dateString; // Ensure clean date format
        dataToInsert['created_at'] = DateTime.now().toIso8601String();
        
        await _supabase.from('attendance_records').insert(dataToInsert);
        print('✅ Created new attendance record for $centerName on $dateString');
      }
      return true;
    } catch (e) {
      print('❌ Error uploading attendance: $e');
      return false;
    }
  }

  Future<bool> _uploadVolunteerReportFromQueue(SyncQueueItem item) async {
    try {
      // Insert new volunteer report (don't send local ID)
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id'); // Remove local ID
      dataToInsert.remove('user_id'); // Remove user_id if present (we'll add the correct one)
      
      // Use the ID as timestamp for created_at
      if (item.entityId > 1000000000000) {
        // ID is a timestamp
        dataToInsert['created_at'] = DateTime.fromMillisecondsSinceEpoch(item.entityId).toIso8601String();
      } else {
        dataToInsert['created_at'] = DateTime.now().toIso8601String();
      }
      
      // Add current user ID for RLS
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        dataToInsert['user_id'] = currentUserId;
      }
      
      try {
        await _supabase.from('volunteer_reports').insert(dataToInsert);
        print('✅ Uploaded volunteer report for ${item.data['center_name']}');
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // Duplicate - already exists, skip
          print('⚠️ Volunteer report already exists, skipping');
        } else {
          rethrow;
        }
      }
      return true;
    } catch (e) {
      print('❌ Error uploading volunteer report: $e');
      return false;
    }
  }

  Future<bool> _deleteVolunteerReportFromQueue(SyncQueueItem item) async {
    try {
      // Delete by timestamp-based created_at
      if (item.entityId > 1000000000000) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(item.entityId).toIso8601String();
        await _supabase
            .from('volunteer_reports')
            .delete()
            .eq('created_at', createdAt)
            .eq('center_name', item.data['center_name']);
        print('✅ Deleted volunteer report from cloud');
      } else {
        print('⚠️ Cannot delete volunteer report: invalid ID');
      }
      return true;
    } catch (e) {
      print('❌ Error deleting volunteer report: $e');
      return false;
    }
  }

  Future<bool> _deleteAttendanceFromQueue(SyncQueueItem item) async {
    try {
      await _supabase
          .from('attendance_records')
          .delete()
          .eq('date', item.data['date'].toString().split('T')[0])
          .eq('center_name', item.data['center_name']);
      print('✅ Deleted attendance record from cloud');
      return true;
    } catch (e) {
      print('❌ Error deleting attendance: $e');
      return false;
    }
  }

  // ============================================================================
  // DOWNLOAD OPERATIONS (unchanged from original)
  // ============================================================================

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
  // FULL SYNC WITH QUEUE
  // ============================================================================

  /// Full sync: Process queue (upload) then download cloud data
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

      // STEP 1: Process sync queue (upload pending changes)
      print('📤 Step 1: Processing sync queue...');
      final queueResult = await processSyncQueue();
      print('   Queue result: ${queueResult['message']}');

      // STEP 2: Download students from cloud
      print('📥 Step 2: Downloading students...');
      final cloudStudents = await downloadStudentsForCenter(centerName);
      final centerStudents = studentProvider.getStudentsByCenter(centerName);
      
      // ✅ FIX: Use composite key (rollNo + classBatch + centerName) instead of ID
      for (var cloudStudent in cloudStudents) {
        final localIndex = centerStudents.indexWhere((s) => 
          s.rollNo == cloudStudent.rollNo && 
          s.classBatch == cloudStudent.classBatch &&
          s.centerName == cloudStudent.centerName
        );
        
        if (localIndex == -1) {
          // Student doesn't exist locally, add it
          await studentProvider.addStudent(
            name: cloudStudent.name,
            rollNo: cloudStudent.rollNo,
            classBatch: cloudStudent.classBatch,
            centerName: cloudStudent.centerName,
            embeddings: cloudStudent.embeddings,
          );
          print('   ➕ Added new student from cloud: ${cloudStudent.name}');
        } else {
          // Student exists, update if cloud has newer data (including embeddings)
          final localStudent = centerStudents[localIndex];
          if (cloudStudent.embeddings != null && cloudStudent.embeddings!.isNotEmpty) {
            // Update local student with cloud embeddings if they exist
            localStudent.embeddings = cloudStudent.embeddings;
            localStudent.lessonsLearned = cloudStudent.lessonsLearned;
            localStudent.testResults = cloudStudent.testResults;
            await studentProvider.updateStudent(localStudent);
            print('   🔄 Updated student from cloud: ${cloudStudent.name}');
          }
        }
      }

      // STEP 3: Download attendance from cloud
      print('📥 Step 3: Downloading attendance...');
      final cloudAttendance = await downloadAttendanceForCenter(centerName);
      final centerAttendance = attendanceProvider.getAttendanceByCenter(centerName);
      
      for (var cloudRecord in cloudAttendance) {
        // Save with the correct date from cloud record
        await attendanceProvider.saveAttendance(
          cloudRecord.attendance,
          centerName,
          date: cloudRecord.date,
        );
      }

      // STEP 4: Download volunteer reports from cloud
      print('📥 Step 4: Downloading volunteer reports...');
      final cloudReports = await downloadVolunteerReportsForCenter(centerName);
      final centerReports = volunteerProvider.getReportsByCenter(centerName);
      
      for (var cloudReport in cloudReports) {
        final localIndex = centerReports.indexWhere((r) => r.id == cloudReport.id);
        if (localIndex == -1) {
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

  // ============================================================================
  // QUEUE MANAGEMENT
  // ============================================================================

  /// Get sync queue statistics
  Future<Map<String, int>> getSyncQueueStats() async {
    return await _syncQueue.getSyncStats();
  }

  /// Retry failed items
  Future<void> retryFailedItems() async {
    final retryableItems = await _syncQueue.getRetryableItems();
    print('🔄 Retrying ${retryableItems.length} failed items...');
    
    for (var item in retryableItems) {
      // Reset to pending status
      await _syncQueue.updateItemStatus(
        itemId: item.id,
        status: SyncStatus.pending,
      );
    }
    
    // Process the queue
    await processSyncQueue();
  }

  /// Clear old completed items
  Future<void> cleanupOldItems() async {
    await _syncQueue.clearOldCompletedItems(daysOld: 7);
  }

  Future<bool> _uploadTopicEvaluationFromQueue(SyncQueueItem item) async {
    try {
      // Insert new topic evaluation
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert['created_at'] = DateTime.now().toIso8601String();
      dataToInsert['updated_at'] = DateTime.now().toIso8601String();
      
      // Add current user ID for RLS
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        dataToInsert['user_id'] = currentUserId;
      }
      
      await _supabase.from('topic_evaluations').insert(dataToInsert);
      print('✅ Uploaded topic evaluation for student ${item.data['student_id']}');
      return true;
    } catch (e) {
      print('❌ Error uploading topic evaluation: $e');
      return false;
    }
  }
}
