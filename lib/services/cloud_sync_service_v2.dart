import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/schedule_provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/services/sync_queue_service.dart';
import 'package:samadhan_app/services/teacher_service.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/models/sync_queue_item.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/models/teacher.dart';
import 'package:samadhan_app/models/volunteer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sembast/sembast.dart';
import 'dart:async';

/// Enhanced cloud sync service with queue-based synchronization
class CloudSyncServiceV2 {
  static final CloudSyncServiceV2 _instance = CloudSyncServiceV2._internal();
  factory CloudSyncServiceV2() => _instance;
  CloudSyncServiceV2._internal();

  final _supabase = Supabase.instance.client;
  final _syncQueue = SyncQueueService();
  final _teacherService = TeacherService();
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isSyncing => _isSyncing;
  SupabaseClient get supabase => _supabase;

  /// Initialize connectivity monitoring for immediate sync
  void initializeConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.contains(ConnectivityResult.mobile) || 
                      results.contains(ConnectivityResult.wifi);
      
      if (isOnline && !_isSyncing) {
        print('🌐 Network connected - triggering immediate sync');
        _triggerImmediateSync();
      }
    });
  }

  /// Trigger immediate sync when connectivity is restored
  Future<void> _triggerImmediateSync() async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Brief delay to ensure connection is stable
      final result = await processSyncQueue();
      if (result['successCount'] > 0) {
        print('✅ Immediate sync completed: ${result['successCount']} items synced');
      }
    } catch (e) {
      print('⚠️ Immediate sync failed: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
    } catch (e) {
      print('⚠️ Error checking connectivity: $e');
      return false;
    }
  }

  // QUEUE-BASED OPERATIONS

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


  Future<void> queueAttendanceUpload(AttendanceRecord record) async {
    // Ensure attendance data is properly formatted for JSONB
    final attendanceMap = <String, dynamic>{};
    record.attendance.forEach((key, value) {
      // Ensure keys are strings and values are properly typed booleans
      attendanceMap[key.toString()] = value is bool ? value : (value.toString().toLowerCase() == 'true');
    });

    print('📋 Queuing attendance upload:');
    print('   Date: ${record.date.toIso8601String().split('T')[0]}');
    print('   Center: ${record.centerName}');
    print('   Students: ${attendanceMap.length}');
    print('   Sample: ${attendanceMap.entries.take(3).map((e) => '${e.key}:${e.value}').join(', ')}');

    await _syncQueue.addToQueue(
      entityType: SyncEntityType.attendance,
      operation: SyncOperation.create,
      entityId: record.id,
      data: {
        'id': record.id,
        'date': record.date.toIso8601String().split('T')[0],
        'center_name': record.centerName,
        'attendance': attendanceMap,
      },
      centerName: record.centerName,
    );
  }

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

  Future<void> queueVolunteerUpload(Volunteer volunteer) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.volunteer,
      operation: SyncOperation.create,
      entityId: volunteer.id,
      data: {
        'id': volunteer.id,
        'name': volunteer.name,
        'center_name': volunteer.centerName,
        'attendance_count': volunteer.attendanceCount,
        'first_report_date': volunteer.firstReportDate.toIso8601String().split('T')[0],
        'last_report_date': volunteer.lastReportDate.toIso8601String().split('T')[0],
      },
      centerName: volunteer.centerName,
    );
  }

  Future<void> queueVolunteerUpdate(Volunteer volunteer) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.volunteer,
      operation: SyncOperation.update,
      entityId: volunteer.id,
      data: {
        'id': volunteer.id,
        'name': volunteer.name,
        'center_name': volunteer.centerName,
        'attendance_count': volunteer.attendanceCount,
        'first_report_date': volunteer.firstReportDate.toIso8601String().split('T')[0],
        'last_report_date': volunteer.lastReportDate.toIso8601String().split('T')[0],
      },
      centerName: volunteer.centerName,
    );
  }

  Future<void> queueStudentDelete(String rollNo, String classBatch, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.student,
      operation: SyncOperation.delete,
      entityId: 0,
      data: {
        'roll_no': rollNo,
        'class_batch': classBatch,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

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

  Future<void> queueTopicEvaluationUpload(TopicEvaluation evaluation, String centerName, {String? rollNo, String? classBatch}) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.topicEvaluation,
      operation: SyncOperation.create,
      entityId: 0,
      data: {
        'student_id': evaluation.studentId, // Local ID, will be replaced during upload
        'roll_no': rollNo, // Store for lookup
        'class_batch': classBatch, // Store for lookup
        'center_name': centerName, // Store for lookup
        'subject': evaluation.subject,
        'topic': evaluation.topic,
        'evaluation': evaluation.evaluation.name,
        'evaluated_by': evaluation.evaluatedBy,
        'evaluated_on': evaluation.evaluatedOn.toIso8601String(),
      },
      centerName: centerName,
    );
  }

  Future<void> queueScheduleUpload(ScheduleEntry schedule, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.schedule,
      operation: SyncOperation.create,
      entityId: schedule.id,
      data: {
        'id': schedule.id,
        'class_batch': schedule.classBatch,
        'date': schedule.date.toIso8601String(),
        'time': '${schedule.time.hour}:${schedule.time.minute}',
        'topic': schedule.topic,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  Future<void> queueScheduleUpdate(ScheduleEntry schedule, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.schedule,
      operation: SyncOperation.update,
      entityId: schedule.id,
      data: {
        'id': schedule.id,
        'class_batch': schedule.classBatch,
        'date': schedule.date.toIso8601String(),
        'time': '${schedule.time.hour}:${schedule.time.minute}',
        'topic': schedule.topic,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  Future<void> queueScheduleDelete(int scheduleId, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.schedule,
      operation: SyncOperation.delete,
      entityId: scheduleId,
      data: {
        'id': scheduleId,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  Future<void> queueEventUpload(Event event) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.event,
      operation: SyncOperation.create,
      entityId: event.id,
      data: {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'time': '${event.time.hour}:${event.time.minute}',
        'attendance_summary': event.attendanceSummary,
        'class_batch': event.classBatch,
        'center_name': event.centerName,
        'present_student_rolls': event.presentStudentRolls,
        'topics': event.topics,
        'photo_paths': event.photoPaths,
      },
      centerName: event.centerName,
    );
  }

  Future<void> queueEventUpdate(Event event) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.event,
      operation: SyncOperation.update,
      entityId: event.id,
      data: {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'time': '${event.time.hour}:${event.time.minute}',
        'attendance_summary': event.attendanceSummary,
        'class_batch': event.classBatch,
        'center_name': event.centerName,
        'present_student_rolls': event.presentStudentRolls,
        'topics': event.topics,
        'photo_paths': event.photoPaths,
      },
      centerName: event.centerName,
    );
  }

  Future<void> queueEventDelete(int eventId, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.event,
      operation: SyncOperation.delete,
      entityId: eventId,
      data: {
        'id': eventId,
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  Future<void> queueNotificationUpload(AppNotification notification, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.notification,
      operation: SyncOperation.create,
      entityId: notification.id,
      data: {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type,
        'is_read': notification.isRead,
        'date': notification.date.toIso8601String(),
        'center_name': centerName,
      },
      centerName: centerName,
    );
  }

  Future<void> queueUserSettingsUpload(UserSettings settings, String centerName) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.userSettings,
      operation: SyncOperation.create,
      entityId: 0,
      data: {
        'name': settings.name,
        'phone_number': settings.phoneNumber,
        'center_name': centerName,
        'language': settings.language,
        'selected_center': settings.selectedCenter,
      },
      centerName: centerName,
    );
  }

  /// Queue teacher profile update for sync
  Future<void> queueTeacherProfileUpdate(Teacher teacher) async {
    await _syncQueue.addToQueue(
      entityType: SyncEntityType.userSettings, // Reusing userSettings for teacher profile
      operation: SyncOperation.update,
      entityId: 0,
      data: {
        'id': teacher.id,
        'email': teacher.email,
        'name': teacher.name,
        'phone_number': teacher.phoneNumber,
        'center_name': teacher.centerName,
        'role': teacher.role,
        'is_active': teacher.isActive,
      },
      centerName: teacher.centerName,
    );
  }

  /// Save topic evaluation with immediate sync when online
  Future<void> saveTopicEvaluationWithSync(TopicEvaluation evaluation, String centerName, {String? rollNo, String? classBatch}) async {
    try {
      // Check if online
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of topic evaluation to cloud');
        
        // Try immediate upload
        await queueTopicEvaluationUpload(evaluation, centerName, rollNo: rollNo, classBatch: classBatch);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Topic evaluation immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - topic evaluation queued for sync when online');
        
        // Queue for later sync when online
        await queueTopicEvaluationUpload(evaluation, centerName, rollNo: rollNo, classBatch: classBatch);
        print('📋 Topic evaluation queued for sync when online');
      }
    } catch (e) {
      print('⚠️ Failed to sync topic evaluation: $e');
      // Evaluation is queued, will sync later
    }
  }

  /// Save student with immediate sync when online
  Future<void> saveStudentWithSync(Student student) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of student to cloud');
        await queueStudentUpload(student);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Student immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - student queued for sync when online');
        await queueStudentUpload(student);
      }
    } catch (e) {
      print('⚠️ Failed to sync student: $e');
    }
  }

  /// Save attendance with immediate sync when online
  Future<void> saveAttendanceWithSync(AttendanceRecord record) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of attendance to cloud');
        await queueAttendanceUpload(record);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Attendance immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - attendance queued for sync when online');
        await queueAttendanceUpload(record);
      }
    } catch (e) {
      print('⚠️ Failed to sync attendance: $e');
    }
  }

  /// Save volunteer report with immediate sync when online
  Future<void> saveVolunteerReportWithSync(VolunteerReport report) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of volunteer report to cloud');
        await queueVolunteerReportUpload(report);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Volunteer report immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - volunteer report queued for sync when online');
        await queueVolunteerReportUpload(report);
      }
    } catch (e) {
      print('⚠️ Failed to sync volunteer report: $e');
    }
  }

  /// Save schedule with immediate sync when online
  Future<void> saveScheduleWithSync(ScheduleEntry schedule, String centerName) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of schedule to cloud');
        await queueScheduleUpload(schedule, centerName);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Schedule immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - schedule queued for sync when online');
        await queueScheduleUpload(schedule, centerName);
      }
    } catch (e) {
      print('⚠️ Failed to sync schedule: $e');
    }
  }

  /// Save event with immediate sync when online
  Future<void> saveEventWithSync(Event event) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of event to cloud');
        await queueEventUpload(event);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Event immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - event queued for sync when online');
        await queueEventUpload(event);
      }
    } catch (e) {
      print('⚠️ Failed to sync event: $e');
    }
  }

  /// Save notification with immediate sync when online
  Future<void> saveNotificationWithSync(AppNotification notification, String centerName) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of notification to cloud');
        await queueNotificationUpload(notification, centerName);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Notification immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - notification queued for sync when online');
        await queueNotificationUpload(notification, centerName);
      }
    } catch (e) {
      print('⚠️ Failed to sync notification: $e');
    }
  }

  /// Save user settings with immediate sync when online
  Future<void> saveUserSettingsWithSync(UserSettings settings, String centerName) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of user settings to cloud');
        await queueUserSettingsUpload(settings, centerName);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ User settings immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - user settings queued for sync when online');
        await queueUserSettingsUpload(settings, centerName);
      }
    } catch (e) {
      print('⚠️ Failed to sync user settings: $e');
    }
  }

  /// Save teacher profile with immediate sync when online
  Future<void> saveTeacherProfileWithSync(Teacher teacher) async {
    try {
      final isOnline = await this.isOnline();
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of teacher profile to cloud');
        await queueTeacherProfileUpdate(teacher);
        final syncResult = await processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Teacher profile immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - teacher profile queued for sync when online');
        await queueTeacherProfileUpdate(teacher);
      }
    } catch (e) {
      print('⚠️ Failed to sync teacher profile: $e');
    }
  }


  // PROCESS SYNC QUEUE

  Future<Map<String, dynamic>> processSyncQueue() async {
    if (_isSyncing) {
      return {'success': false, 'message': 'Sync already in progress'};
    }

    final online = await isOnline();
    if (!online) {
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
      final pendingItems = await _syncQueue.getPendingItems();
      if (pendingItems.isEmpty) {
        return {
          'success': true,
          'message': 'No pending items to sync',
          'successCount': 0,
          'failureCount': 0,
        };
      }

      for (var item in pendingItems) {
        try {
          await _syncQueue.markInProgress(item.id);

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
            case SyncEntityType.volunteer:
              if (item.operation == SyncOperation.update) {
                uploaded = await _updateVolunteerFromQueue(item);
              } else {
                uploaded = await _uploadVolunteerFromQueue(item);
              }
              break;
            case SyncEntityType.topicEvaluation:
              uploaded = await _uploadTopicEvaluationFromQueue(item);
              break;
            case SyncEntityType.schedule:
              if (item.operation == SyncOperation.delete) {
                uploaded = await _deleteScheduleFromQueue(item);
              } else if (item.operation == SyncOperation.update) {
                uploaded = await _updateScheduleFromQueue(item);
              } else {
                uploaded = await _uploadScheduleFromQueue(item);
              }
              break;
            case SyncEntityType.event:
              if (item.operation == SyncOperation.delete) {
                uploaded = await _deleteEventFromQueue(item);
              } else if (item.operation == SyncOperation.update) {
                uploaded = await _updateEventFromQueue(item);
              } else {
                uploaded = await _uploadEventFromQueue(item);
              }
              break;
            case SyncEntityType.notification:
              uploaded = await _uploadNotificationFromQueue(item);
              break;
            case SyncEntityType.userSettings:
              uploaded = await _uploadUserSettingsFromQueue(item);
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
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      return {
        'success': failureCount == 0,
        'message': 'Synced $successCount items, $failureCount failed',
        'successCount': successCount,
        'failureCount': failureCount,
        'errors': errors,
      };
    } catch (e) {
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


  // UPLOAD HELPERS

  Future<bool> _uploadStudentFromQueue(SyncQueueItem item) async {
    try {
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
      } else {
        final dataToInsert = Map<String, dynamic>.from(item.data);
        dataToInsert.remove('id');
        dataToInsert['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('students').insert(dataToInsert);
      }
      return true;
    } catch (e) {
      print('❌ Error uploading student: $e');
      return false;
    }
  }

  Future<bool> _updateStudentFromQueue(SyncQueueItem item) async {
    try {
      final existing = await _supabase
          .from('students')
          .select('id, lessons_learned, test_results, embeddings')
          .eq('roll_no', item.data['roll_no'])
          .eq('class_batch', item.data['class_batch'])
          .eq('center_name', item.data['center_name'])
          .maybeSingle();

      if (existing != null) {
        final existingLessons = List<String>.from(existing['lessons_learned'] ?? []);
        final newLessons = List<String>.from(item.data['lessons_learned'] ?? []);
        final mergedLessons = {...existingLessons, ...newLessons}.toList();

        final existingTests = Map<String, dynamic>.from(existing['test_results'] ?? {});
        final newTests = Map<String, dynamic>.from(item.data['test_results'] ?? {});
        final mergedTests = {...existingTests, ...newTests};

        final newEmbeddings = item.data['embeddings'];
        final finalEmbeddings = (newEmbeddings != null && (newEmbeddings as List).isNotEmpty)
            ? newEmbeddings
            : existing['embeddings'];

        await _supabase.from('students').update({
          'name': item.data['name'],
          'lessons_learned': mergedLessons,
          'test_results': mergedTests,
          'embeddings': finalEmbeddings,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        return true;
      } else {
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
      return true;
    } catch (e) {
      print('❌ Error deleting student: $e');
      return false;
    }
  }


  Future<bool> _uploadAttendanceFromQueue(SyncQueueItem item) async {
    try {
      // Check authentication first
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated - cannot upload attendance');
        print('   Please ensure user is logged in before syncing');
        return false;
      }

      print('\n📤 UPLOADING ATTENDANCE TO SUPABASE');
      print('═══════════════════════════════════════════════════════');
      print('   User: ${user.email}');
      print('   User ID: ${user.id}');
      
      // Ensure attendance data is properly formatted as JSONB
      final attendanceData = item.data['attendance'];
      Map<String, dynamic> formattedAttendance;
      
      if (attendanceData is Map) {
        // Convert all values to proper types for JSONB
        formattedAttendance = Map<String, dynamic>.from(attendanceData);
        // Ensure boolean values are properly typed
        formattedAttendance = formattedAttendance.map((key, value) {
          if (value is bool) {
            return MapEntry(key.toString(), value);
          } else if (value is String) {
            // Handle string representations of booleans
            if (value.toLowerCase() == 'true') return MapEntry(key.toString(), true);
            if (value.toLowerCase() == 'false') return MapEntry(key.toString(), false);
          }
          return MapEntry(key.toString(), value);
        });
      } else {
        print('⚠️ Invalid attendance data format: $attendanceData');
        return false;
      }

      print('   Date: ${item.data['date']}');
      print('   Center: ${item.data['center_name']}');
      print('   Students: ${formattedAttendance.length}');
      print('   Present: ${formattedAttendance.values.where((v) => v == true).length}');
      print('   Absent: ${formattedAttendance.values.where((v) => v == false).length}');
      print('   Sample data: ${formattedAttendance.entries.take(3).map((e) => '${e.key}:${e.value}').join(', ')}');

      // Check if record already exists
      print('🔍 Checking for existing attendance record...');
      final existing = await _supabase
          .from('attendance_records')
          .select('id, attendance')
          .eq('date', item.data['date'].toString().split('T')[0])
          .eq('center_name', item.data['center_name'])
          .maybeSingle();

      if (existing != null) {
        print('📝 Found existing record (ID: ${existing['id']}) - merging data');
        final existingAttendance = Map<String, dynamic>.from(existing['attendance'] ?? {});
        print('   Existing students: ${existingAttendance.length}');
        final mergedAttendance = {...existingAttendance, ...formattedAttendance};
        print('   After merge: ${mergedAttendance.length} students');
        
        final updateData = {
          'attendance': mergedAttendance,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('🔄 Updating existing record...');
        await _supabase.from('attendance_records').update(updateData).eq('id', existing['id']);
        print('✅ Successfully updated attendance record in Supabase');
      } else {
        print('📝 No existing record found - creating new record');
        final dataToInsert = {
          'date': item.data['date'].toString().split('T')[0],
          'center_name': item.data['center_name'],
          'attendance': formattedAttendance,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        print('➕ Inserting new record...');
        await _supabase.from('attendance_records').insert(dataToInsert);
        print('✅ Successfully created attendance record in Supabase');
      }
      
      print('═══════════════════════════════════════════════════════\n');
      return true;
    } catch (e, stackTrace) {
      print('\n❌ ERROR UPLOADING ATTENDANCE TO SUPABASE');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      if (e.toString().contains('42501')) {
        print('❌ Row-level security policy violation');
        print('   This usually means:');
        print('   1. User is not authenticated');
        print('   2. RLS policy doesn\'t allow this operation');
        print('   3. User doesn\'t have permission for this center');
        print('   Current user: ${_supabase.auth.currentUser?.email ?? 'Not authenticated'}');
      }
      
      if (e is PostgrestException) {
        print('❌ Postgrest error details:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      
      print('═══════════════════════════════════════════════════════\n');
      return false;
    }
  }

  Future<bool> _uploadVolunteerReportFromQueue(SyncQueueItem item) async {
    try {
      print('\n📤 UPLOADING VOLUNTEER REPORT TO SUPABASE');
      print('═══════════════════════════════════════════════════════');
      
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id');

      String createdAtStr;
      if (item.entityId > 1000000000000) {
        createdAtStr = DateTime.fromMillisecondsSinceEpoch(item.entityId).toIso8601String();
        dataToInsert['created_at'] = createdAtStr;
      } else {
        createdAtStr = DateTime.now().toIso8601String();
        dataToInsert['created_at'] = createdAtStr;
      }

      print('   Volunteer: ${dataToInsert['volunteer_name']}');
      print('   Center: ${dataToInsert['center_name']}');
      print('   Created At: $createdAtStr');

      // Check if report already exists to prevent duplicates
      final existing = await _supabase
          .from('volunteer_reports')
          .select('id')
          .eq('created_at', createdAtStr)
          .eq('center_name', dataToInsert['center_name'])
          .maybeSingle();

      if (existing != null) {
        print('⏭️ Report already exists in Supabase (ID: ${existing['id']}) - skipping upload');
        print('═══════════════════════════════════════════════════════\n');
        return true; // Already exists, mark as successful
      }

      print('➕ Inserting new volunteer report...');
      try {
        await _supabase.from('volunteer_reports').insert(dataToInsert);
        print('✅ Successfully uploaded volunteer report');
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // Duplicate key - already exists, skip
          print('⏭️ Duplicate detected by database - skipping');
        } else {
          rethrow;
        }
      }
      
      print('═══════════════════════════════════════════════════════\n');
      return true;
    } catch (e) {
      print('❌ Error uploading volunteer report: $e');
      print('═══════════════════════════════════════════════════════\n');
      return false;
    }
  }

  Future<bool> _deleteVolunteerReportFromQueue(SyncQueueItem item) async {
    try {
      if (item.entityId > 1000000000000) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(item.entityId).toIso8601String();
        await _supabase
            .from('volunteer_reports')
            .delete()
            .eq('created_at', createdAt)
            .eq('center_name', item.data['center_name']);
      }
      return true;
    } catch (e) {
      print('❌ Error deleting volunteer report: $e');
      return false;
    }
  }

  Future<bool> _uploadVolunteerFromQueue(SyncQueueItem item) async {
    try {
      print('\n📤 UPLOADING VOLUNTEER TO SUPABASE');
      print('═══════════════════════════════════════════════════════');
      
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id'); // Let database generate ID
      
      print('   Volunteer: ${dataToInsert['name']}');
      print('   Center: ${dataToInsert['center_name']}');
      print('   Attendance Count: ${dataToInsert['attendance_count']}');

      // Check if volunteer already exists to prevent duplicates
      final existing = await _supabase
          .from('volunteers')
          .select('id, attendance_count')
          .eq('name', dataToInsert['name'])
          .eq('center_name', dataToInsert['center_name'])
          .maybeSingle();

      if (existing != null) {
        // Update existing volunteer with higher attendance count
        final newCount = dataToInsert['attendance_count'] as int;
        final existingCount = existing['attendance_count'] as int;
        
        if (newCount > existingCount) {
          await _supabase.from('volunteers').update({
            'attendance_count': newCount,
            'last_report_date': dataToInsert['last_report_date'],
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);
          print('✅ Updated existing volunteer with higher attendance count');
        } else {
          print('⏭️ Volunteer already exists with same or higher attendance count - skipping');
        }
      } else {
        // Insert new volunteer
        await _supabase.from('volunteers').insert(dataToInsert);
        print('✅ Successfully uploaded new volunteer');
      }
      
      print('═══════════════════════════════════════════════════════\n');
      return true;
    } catch (e) {
      print('❌ Error uploading volunteer: $e');
      print('═══════════════════════════════════════════════════════\n');
      return false;
    }
  }

  Future<bool> _updateVolunteerFromQueue(SyncQueueItem item) async {
    try {
      print('\n📤 UPDATING VOLUNTEER IN SUPABASE');
      print('═══════════════════════════════════════════════════════');
      
      final updateData = Map<String, dynamic>.from(item.data);
      updateData.remove('id');
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      print('   Volunteer: ${updateData['name']}');
      print('   Center: ${updateData['center_name']}');
      print('   New Attendance Count: ${updateData['attendance_count']}');

      // Find volunteer by name and center
      final existing = await _supabase
          .from('volunteers')
          .select('id')
          .eq('name', updateData['name'])
          .eq('center_name', updateData['center_name'])
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('volunteers').update(updateData).eq('id', existing['id']);
        print('✅ Successfully updated volunteer');
      } else {
        // If volunteer doesn't exist, create it
        print('⚠️ Volunteer not found, creating new record');
        return await _uploadVolunteerFromQueue(item);
      }
      
      print('═══════════════════════════════════════════════════════\n');
      return true;
    } catch (e) {
      print('❌ Error updating volunteer: $e');
      print('═══════════════════════════════════════════════════════\n');
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
      return true;
    } catch (e) {
      print('❌ Error deleting attendance: $e');
      return false;
    }
  }

  Future<bool> _uploadTopicEvaluationFromQueue(SyncQueueItem item) async {
    try {
      print('\n📤 UPLOADING TOPIC EVALUATION TO SUPABASE');
      print('═══════════════════════════════════════════════════════');
      
      final rollNo = item.data['roll_no'];
      final classBatch = item.data['class_batch'];
      final centerName = item.data['center_name'];
      
      print('   Roll No: $rollNo');
      print('   Class: $classBatch');
      print('   Center: $centerName');
      
      // Find the Supabase student ID using roll_no, class_batch, and center_name
      final supabaseStudent = await _supabase
          .from('students')
          .select('id')
          .eq('roll_no', rollNo)
          .eq('class_batch', classBatch)
          .eq('center_name', centerName)
          .maybeSingle();
      
      if (supabaseStudent == null) {
        print('❌ Student not found in Supabase');
        print('   Roll No: $rollNo, Class: $classBatch, Center: $centerName');
        print('   This student needs to be synced to Supabase first');
        print('═══════════════════════════════════════════════════════\n');
        return false;
      }
      
      final supabaseStudentId = supabaseStudent['id'];
      print('   Supabase student ID: $supabaseStudentId');
      
      // Create data with Supabase student ID
      final dataToInsert = {
        'student_id': supabaseStudentId, // Use Supabase ID
        'subject': item.data['subject'],
        'topic': item.data['topic'],
        'evaluation': item.data['evaluation'],
        'evaluated_by': item.data['evaluated_by'],
        'evaluated_on': item.data['evaluated_on'],
      };
      
      print('   Subject: ${dataToInsert['subject']}');
      print('   Topic: ${dataToInsert['topic']}');
      print('   Evaluation: ${dataToInsert['evaluation']}');
      
      await _supabase.from('topic_evaluations').insert(dataToInsert);
      print('✅ Successfully uploaded topic evaluation');
      print('═══════════════════════════════════════════════════════\n');
      return true;
    } catch (e, stackTrace) {
      print('\n❌ ERROR UPLOADING TOPIC EVALUATION');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════\n');
      return false;
    }
  }

  Future<bool> _uploadScheduleFromQueue(SyncQueueItem item) async {
    try {
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id');
      dataToInsert['created_at'] = DateTime.now().toIso8601String();
      
      await _supabase.from('schedules').insert(dataToInsert);
      return true;
    } catch (e) {
      print('❌ Error uploading schedule: $e');
      return false;
    }
  }

  Future<bool> _updateScheduleFromQueue(SyncQueueItem item) async {
    try {
      final updateData = Map<String, dynamic>.from(item.data);
      updateData.remove('id');
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase.from('schedules').update(updateData).eq('id', item.entityId);
      return true;
    } catch (e) {
      print('❌ Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> _deleteScheduleFromQueue(SyncQueueItem item) async {
    try {
      await _supabase.from('schedules').delete().eq('id', item.entityId);
      return true;
    } catch (e) {
      print('❌ Error deleting schedule: $e');
      return false;
    }
  }

  Future<bool> _uploadEventFromQueue(SyncQueueItem item) async {
    try {
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id');
      dataToInsert['created_at'] = DateTime.now().toIso8601String();
      
      await _supabase.from('events').insert(dataToInsert);
      return true;
    } catch (e) {
      print('❌ Error uploading event: $e');
      return false;
    }
  }

  Future<bool> _updateEventFromQueue(SyncQueueItem item) async {
    try {
      final updateData = Map<String, dynamic>.from(item.data);
      updateData.remove('id');
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase.from('events').update(updateData).eq('id', item.entityId);
      return true;
    } catch (e) {
      print('❌ Error updating event: $e');
      return false;
    }
  }

  Future<bool> _deleteEventFromQueue(SyncQueueItem item) async {
    try {
      await _supabase.from('events').delete().eq('id', item.entityId);
      return true;
    } catch (e) {
      print('❌ Error deleting event: $e');
      return false;
    }
  }

  Future<bool> _uploadNotificationFromQueue(SyncQueueItem item) async {
    try {
      final dataToInsert = Map<String, dynamic>.from(item.data);
      dataToInsert.remove('id');
      
      await _supabase.from('notifications').insert(dataToInsert);
      return true;
    } catch (e) {
      print('❌ Error uploading notification: $e');
      return false;
    }
  }

  Future<bool> _uploadUserSettingsFromQueue(SyncQueueItem item) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated - cannot upload user settings');
        return false;
      }

      // Note: user_settings table doesn't exist in current schema
      // Settings are stored locally only for now
      print('⚠️ User settings sync skipped - table not available in schema');
      return true; // Return true to mark as completed and remove from queue
    } catch (e) {
      print('❌ Error uploading user settings: $e');
      return true; // Return true to prevent retry since table doesn't exist
    }
  }


  // DOWNLOAD OPERATIONS

  Future<List<Student>> downloadStudentsForCenter(String centerName) async {
    try {
      print('🔍 Downloading students for center: "$centerName"');
      
      final response = await _supabase
          .from('students')
          .select()
          .eq('center_name', centerName);

      print('📊 Raw response from students table: $response');
      print('📊 Number of students found: ${response.length}');

      final students = <Student>[];
      for (var data in response) {
        print('👤 Processing student data: $data');
        try {
          students.add(Student.fromMap(data, data['id'] as int));
          print('✅ Successfully parsed student: ${data['name']}');
        } catch (e) {
          print('❌ Error parsing student ${data['name']}: $e');
        }
      }
      
      print('📋 Total students parsed: ${students.length}');
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
      return records;
    } catch (e) {
      print('❌ Error downloading attendance: $e');
      return [];
    }
  }

  Future<List<VolunteerReport>> downloadVolunteerReportsForCenter(String centerName) async {
    try {
      print('📥 Downloading volunteer reports for center: "$centerName"');
      
      final response = await _supabase
          .from('volunteer_reports')
          .select()
          .eq('center_name', centerName)
          .order('created_at', ascending: false);

      print('📊 Found ${response.length} volunteer reports in Supabase');

      final reports = <VolunteerReport>[];
      int skippedInvalid = 0;
      
      for (var data in response) {
        try {
          // Use created_at timestamp as ID to maintain consistency
          // Parse created_at and convert to milliseconds
          final createdAtStr = data['created_at'] as String;
          final createdAt = DateTime.parse(createdAtStr);
          final timestampId = createdAt.millisecondsSinceEpoch;
          
          // Skip reports with invalid timestamps (before year 2000)
          // These are likely corrupted or test data
          if (timestampId < 946684800000) { // Jan 1, 2000
            print('⏭️ Skipping invalid report with old timestamp: ${data['volunteer_name']} (ID: ${data['id']}, Date: $createdAt)');
            skippedInvalid++;
            continue;
          }
          
          print('   📄 Report: ${data['volunteer_name']} - Supabase ID: ${data['id']}, Timestamp ID: $timestampId, Date: $createdAt');
          
          reports.add(VolunteerReport.fromMap(data, timestampId));
        } catch (e) {
          print('❌ Error parsing volunteer report: $e');
          skippedInvalid++;
        }
      }
      
      print('✅ Successfully parsed ${reports.length} volunteer reports (skipped $skippedInvalid invalid)');
      return reports;
    } catch (e) {
      print('❌ Error downloading volunteer reports: $e');
      return [];
    }
  }

  Future<List<Volunteer>> downloadVolunteersForCenter(String centerName) async {
    try {
      print('👥 Downloading volunteers for center: "$centerName"');
      
      final response = await _supabase
          .from('volunteers')
          .select()
          .eq('center_name', centerName)
          .order('attendance_count', ascending: false);

      print('📊 Found ${response.length} volunteers in cloud');

      final volunteers = <Volunteer>[];
      for (var data in response) {
        try {
          volunteers.add(Volunteer.fromMap(data));
          print('✅ Parsed volunteer: ${data['name']} (attendance: ${data['attendance_count']})');
        } catch (e) {
          print('❌ Error parsing volunteer ${data['name']}: $e');
        }
      }
      
      print('📋 Total volunteers parsed: ${volunteers.length}');
      return volunteers;
    } catch (e) {
      print('❌ Error downloading volunteers: $e');
      return [];
    }
  }

  Future<List<TopicEvaluation>> downloadTopicEvaluationsForCenter(String centerName) async {
    try {
      final students = await downloadStudentsForCenter(centerName);
      final studentIds = students.map((s) => s.id).toList();

      if (studentIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('topic_evaluations')
          .select()
          .inFilter('student_id', studentIds)
          .order('evaluated_on', ascending: false);

      final evaluations = <TopicEvaluation>[];
      for (var data in response) {
        evaluations.add(TopicEvaluation(
          subject: data['subject'],
          topic: data['topic'],
          studentId: data['student_id'],
          evaluation: EvaluationLevel.values.firstWhere(
            (e) => e.name == data['evaluation'],
            orElse: () => EvaluationLevel.average,
          ),
          evaluatedOn: DateTime.parse(data['evaluated_on']),
          evaluatedBy: data['evaluated_by'],
        ));
      }
      return evaluations;
    } catch (e) {
      print('❌ Error downloading topic evaluations: $e');
      return [];
    }
  }

  Future<List<ScheduleEntry>> downloadSchedulesForCenter(String centerName) async {
    try {
      print('📅 Downloading schedules for center: "$centerName"');
      
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('center_name', centerName)
          .order('date', ascending: false);

      print('📊 Found ${response.length} schedules in cloud');

      final schedules = <ScheduleEntry>[];
      for (var data in response) {
        try {
          // Parse time from HH:MM format
          final timeParts = (data['time'] as String).split(':');
          final time = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );

          schedules.add(ScheduleEntry(
            id: data['id'] as int,
            classBatch: data['class_batch'] as String,
            date: DateTime.parse(data['date'] as String),
            time: time,
            topic: data['topic'] as String,
          ));
          print('✅ Parsed schedule: ${data['topic']} on ${data['date']}');
        } catch (e) {
          print('❌ Error parsing schedule ${data['id']}: $e');
        }
      }
      
      print('📋 Total schedules parsed: ${schedules.length}');
      return schedules;
    } catch (e) {
      print('❌ Error downloading schedules: $e');
      return [];
    }
  }

  Future<List<Event>> downloadEventsForCenter(String centerName) async {
    try {
      print('🎉 Downloading events for center: "$centerName"');
      
      final response = await _supabase
          .from('events')
          .select()
          .eq('center_name', centerName)
          .order('date', ascending: false);

      print('📊 Found ${response.length} events in cloud');

      final events = <Event>[];
      for (var data in response) {
        try {
          // Parse time from HH:MM format
          final timeParts = (data['time'] as String).split(':');
          final time = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );

          events.add(Event(
            id: data['id'] as int,
            title: data['title'] as String,
            description: data['description'] as String,
            date: DateTime.parse(data['date'] as String),
            time: time,
            attendanceSummary: data['attendance_summary'] as String? ?? 'N/A',
            classBatch: data['class_batch'] as String? ?? '',
            centerName: data['center_name'] as String,
            presentStudentRolls: List<String>.from(data['present_student_rolls'] ?? []),
            topics: List<String>.from(data['topics'] ?? []),
            photoPaths: List<String>.from(data['photo_paths'] ?? []),
          ));
          print('✅ Parsed event: ${data['title']} on ${data['date']}');
        } catch (e) {
          print('❌ Error parsing event ${data['id']}: $e');
        }
      }
      
      print('📋 Total events parsed: ${events.length}');
      return events;
    } catch (e) {
      print('❌ Error downloading events: $e');
      return [];
    }
  }

  Future<List<AppNotification>> downloadNotificationsForCenter(String centerName) async {
    try {
      print('🔔 Downloading notifications for center: "$centerName"');
      
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('center_name', centerName)
          .order('date', ascending: false);

      print('📊 Found ${response.length} notifications in cloud');

      final notifications = <AppNotification>[];
      for (var data in response) {
        try {
          notifications.add(AppNotification(
            id: data['id'] as int,
            title: data['title'] as String,
            message: data['message'] as String,
            type: data['type'] as String,
            date: DateTime.parse(data['date'] as String),
            isRead: data['is_read'] as bool? ?? false,
          ));
          print('✅ Parsed notification: ${data['title']}');
        } catch (e) {
          print('❌ Error parsing notification ${data['id']}: $e');
        }
      }
      
      print('📋 Total notifications parsed: ${notifications.length}');
      return notifications;
    } catch (e) {
      print('❌ Error downloading notifications: $e');
      return [];
    }
  }


  // FULL SYNC

  Future<bool> fullSyncForCenter(
    String centerName,
    StudentProvider studentProvider,
    AttendanceProvider attendanceProvider,
    VolunteerProvider volunteerProvider, {
    ScheduleProvider? scheduleProvider,
    EventProvider? eventProvider,
    NotificationProvider? notificationProvider,
  }) async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress, skipping');
      return false;
    }

    _isSyncing = true;
    try {
      print('🔄 Starting full sync for center: "$centerName"');
      
      // DEBUG: Check what's in the database
      await debugAllStudents();
      await debugSelectedCenter();
      
      // Step 1: Process sync queue (uploads and deletes)
      print('📤 Processing sync queue (including any pending deletes)...');
      final syncResult = await processSyncQueue();
      final successCount = syncResult['successCount'] ?? 0;
      final failureCount = syncResult['failureCount'] ?? 0;
      print('📊 Sync queue result: $successCount succeeded, $failureCount failed');
      if (failureCount > 0) {
        print('⚠️ Some sync operations failed: ${syncResult['errors']}');
      }

      // Step 2: Download students
      print('👥 Downloading students from cloud...');
      final cloudStudents = await downloadStudentsForCenter(centerName);
      print('☁️ Found ${cloudStudents.length} students in cloud for center "$centerName"');
      
      final centerStudents = studentProvider.getStudentsByCenter(centerName);
      print('📱 Found ${centerStudents.length} local students for center "$centerName"');

      for (var cloudStudent in cloudStudents) {
        print('🔍 Processing cloud student: ${cloudStudent.name} (${cloudStudent.rollNo}) from center "${cloudStudent.centerName}"');
        final localIndex = centerStudents.indexWhere((s) =>
            s.rollNo == cloudStudent.rollNo &&
            s.classBatch == cloudStudent.classBatch &&
            s.centerName == cloudStudent.centerName);

        if (localIndex == -1) {
          print('➕ Adding new student: ${cloudStudent.name} to local database');
          try {
            await studentProvider.addStudent(
              name: cloudStudent.name,
              rollNo: cloudStudent.rollNo,
              classBatch: cloudStudent.classBatch,
              centerName: cloudStudent.centerName,
              embeddings: cloudStudent.embeddings,
              syncToCloud: false, // Don't sync back to cloud since it came from cloud
            );
            print('✅ Successfully added student: ${cloudStudent.name}');
          } catch (e) {
            print('❌ Error adding student ${cloudStudent.name}: $e');
          }
        } else {
          print('🔄 Updating existing student: ${cloudStudent.name}');
          final localStudent = centerStudents[localIndex];
          final mergedLessons = {...localStudent.lessonsLearned, ...cloudStudent.lessonsLearned}.toList();
          final mergedTests = {...localStudent.testResults, ...cloudStudent.testResults};
          final finalEmbeddings = (cloudStudent.embeddings != null && cloudStudent.embeddings!.isNotEmpty)
              ? cloudStudent.embeddings
              : localStudent.embeddings;

          localStudent.lessonsLearned = mergedLessons;
          localStudent.testResults = mergedTests;
          localStudent.embeddings = finalEmbeddings;

          await studentProvider.updateStudent(localStudent, syncToCloud: false);
          print('✅ Successfully updated student: ${cloudStudent.name}');
        }
      }

      // Step 3: Download attendance
      print('📊 Downloading attendance records...');
      final cloudAttendance = await downloadAttendanceForCenter(centerName);
      for (var cloudRecord in cloudAttendance) {
        await attendanceProvider.saveAttendance(
          cloudRecord.attendance,
          centerName,
          date: cloudRecord.date,
        );
      }

      // Step 4: Download volunteer reports
      print('📝 Downloading volunteer reports...');
      
      // First, clean up any invalid local reports
      print('🧹 Cleaning up invalid local reports...');
      await volunteerProvider.cleanupInvalidReports();
      
      final cloudReports = await downloadVolunteerReportsForCenter(centerName);
      print('☁️ Found ${cloudReports.length} volunteer reports in cloud');
      
      final centerReports = volunteerProvider.getReportsByCenter(centerName);
      print('📱 Found ${centerReports.length} local volunteer reports');

      int addedCount = 0;
      int skippedCount = 0;
      
      // Track which reports we've already processed to avoid duplicates
      final processedTimestamps = <int>{};
      
      for (var cloudReport in cloudReports) {
        // Skip if we've already processed a report with this timestamp
        if (processedTimestamps.contains(cloudReport.id)) {
          print('⏭️ Skipping duplicate cloud report: ${cloudReport.volunteerName} (ID: ${cloudReport.id})');
          skippedCount++;
          continue;
        }
        
        // Check if report already exists locally by comparing timestamp ID
        final localIndex = centerReports.indexWhere((r) {
          // Compare timestamp IDs directly
          if (r.id > 1000000000000 && cloudReport.id > 1000000000000) {
            // Exact match on timestamp
            return r.id == cloudReport.id;
          }
          // Fallback: compare by volunteer name, center, and approximate time
          // (within 5 seconds to account for slight timing differences)
          return r.volunteerName == cloudReport.volunteerName &&
                 r.centerName == cloudReport.centerName &&
                 (r.id - cloudReport.id).abs() < 5000; // Within 5 seconds
        });
        
        if (localIndex == -1) {
          print('➕ Adding volunteer report from cloud: ${cloudReport.volunteerName} (ID: ${cloudReport.id})');
          await volunteerProvider.addReport(cloudReport, syncToCloud: false);
          addedCount++;
          processedTimestamps.add(cloudReport.id);
        } else {
          print('⏭️ Skipping duplicate volunteer report: ${cloudReport.volunteerName} (ID: ${cloudReport.id})');
          skippedCount++;
          processedTimestamps.add(cloudReport.id);
        }
      }
      
      print('✅ Volunteer reports sync: ${addedCount} added, ${skippedCount} skipped');

      // Step 5: Download topic evaluations
      print('📚 Downloading topic evaluations...');
      final cloudEvaluations = await downloadTopicEvaluationsForCenter(centerName);
      for (var evaluation in cloudEvaluations) {
        final studentIndex = studentProvider.students.indexWhere((s) => s.id == evaluation.studentId);
        if (studentIndex != -1) {
          final student = studentProvider.students[studentIndex];
          student.topicEvaluations[evaluation.key] = evaluation;
          await studentProvider.updateStudent(student, syncToCloud: false);
        }
      }

      // Step 6: Download schedules
      if (scheduleProvider != null) {
        print('📅 Downloading schedules...');
        final cloudSchedules = await downloadSchedulesForCenter(centerName);
        print('☁️ Found ${cloudSchedules.length} schedules in cloud');
        
        final db = await DatabaseService().database;
        final scheduleStore = intMapStoreFactory.store('schedules');
        
        for (var cloudSchedule in cloudSchedules) {
          // Check if schedule already exists locally by matching date, time, and topic
          final existing = await scheduleStore.findFirst(
            db,
            finder: Finder(
              filter: Filter.and([
                Filter.equals('date', cloudSchedule.date.toIso8601String()),
                Filter.equals('time', '${cloudSchedule.time.hour}:${cloudSchedule.time.minute}'),
                Filter.equals('topic', cloudSchedule.topic),
              ]),
            ),
          );
          
          if (existing == null) {
            // New schedule from cloud, add locally
            await scheduleStore.add(db, cloudSchedule.toMap());
            print('✅ Added schedule from cloud: ${cloudSchedule.topic}');
          }
        }
        
        await scheduleProvider.loadSchedules();
        print('✅ Schedules synced successfully');
      }

      // Step 7: Download events
      if (eventProvider != null) {
        print('🎉 Downloading events...');
        final cloudEvents = await downloadEventsForCenter(centerName);
        print('☁️ Found ${cloudEvents.length} events in cloud');
        
        final db = await DatabaseService().database;
        final eventStore = intMapStoreFactory.store('events');
        
        for (var cloudEvent in cloudEvents) {
          // Check if event already exists locally by matching title and date
          final existing = await eventStore.findFirst(
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
            await eventStore.add(db, cloudEvent.toMap());
            print('✅ Added event from cloud: ${cloudEvent.title}');
          } else {
            // Event exists, update if cloud has photos and local doesn't
            final localEvent = Event.fromMap(existing.value, existing.key);
            if (cloudEvent.photoPaths.isNotEmpty && localEvent.photoPaths.isEmpty) {
              await eventStore.update(
                db,
                cloudEvent.toMap(),
                finder: Finder(filter: Filter.byKey(existing.key)),
              );
              print('✅ Updated event with cloud photos: ${cloudEvent.title}');
            }
          }
        }
        
        await eventProvider.loadEvents();
        print('✅ Events synced successfully');
      }

      // Step 8: Download notifications
      if (notificationProvider != null) {
        print('🔔 Downloading notifications...');
        final cloudNotifications = await downloadNotificationsForCenter(centerName);
        print('☁️ Found ${cloudNotifications.length} notifications in cloud');
        
        final db = await DatabaseService().database;
        final notificationStore = intMapStoreFactory.store('notifications');
        
        for (var cloudNotification in cloudNotifications) {
          // Check if notification already exists locally by matching title and date
          final existing = await notificationStore.findFirst(
            db,
            finder: Finder(
              filter: Filter.and([
                Filter.equals('title', cloudNotification.title),
                Filter.equals('date', cloudNotification.date.toIso8601String()),
              ]),
            ),
          );
          
          if (existing == null) {
            // New notification from cloud, add locally
            await notificationStore.add(db, cloudNotification.toMap());
            print('✅ Added notification from cloud: ${cloudNotification.title}');
          }
        }
        
        await notificationProvider.loadNotifications();
        print('✅ Notifications synced successfully');
      }

      // Final verification: Check how many students are now in the local database
      await studentProvider.fetchStudents(); // Refresh the student list
      final finalLocalStudents = studentProvider.getStudentsByCenter(centerName);
      print('🎯 SYNC COMPLETE: Final local student count for center "$centerName": ${finalLocalStudents.length}');
      for (var student in finalLocalStudents) {
        print('   📋 Local student: ${student.name} (${student.rollNo}) - Center: "${student.centerName}"');
      }

      return true;
    } catch (e) {
      print('❌ Error during full sync: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // QUEUE MANAGEMENT

  Future<Map<String, int>> getSyncQueueStats() async {
    return await _syncQueue.getSyncStats();
  }

  Future<void> retryFailedItems() async {
    final retryableItems = await _syncQueue.getRetryableItems();
    for (var item in retryableItems) {
      await _syncQueue.updateItemStatus(
        itemId: item.id,
        status: SyncStatus.pending,
      );
    }
    await processSyncQueue();
  }

  Future<void> cleanupOldItems() async {
    await _syncQueue.clearOldCompletedItems(daysOld: 7);
  }

  /// Debug method to check all students in the database
  Future<void> debugAllStudents() async {
    try {
      print('🔍 DEBUG: Fetching ALL students from database...');
      
      final response = await _supabase
          .from('students')
          .select();

      print('📊 DEBUG: Total students in database: ${response.length}');
      
      for (var data in response) {
        print('👤 DEBUG Student: ${data['name']} | Roll: ${data['roll_no']} | Center: "${data['center_name']}" | Class: ${data['class_batch']}');
      }
      
      // Also check unique center names
      final centerNames = response.map((s) => s['center_name']).toSet().toList();
      print('🏢 DEBUG: Unique center names in database: $centerNames');
      
    } catch (e) {
      print('❌ DEBUG: Error fetching all students: $e');
    }
  }

  /// Debug method to check what center is selected
  Future<void> debugSelectedCenter() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        print('👤 DEBUG: Current user: ${user.email}');
        
        // Try to get teacher profile to see selected center
        try {
          final teacherProfile = await _supabase
              .from('teachers')
              .select()
              .eq('email', user.email!)
              .maybeSingle();
              
          if (teacherProfile != null) {
            print('⚙️ DEBUG: Teacher center: ${teacherProfile['center_name']}');
          } else {
            print('⚙️ DEBUG: No teacher profile found');
          }
        } catch (e) {
          print('⚠️ DEBUG: Could not fetch teacher profile: $e');
        }
      }
    } catch (e) {
      print('❌ DEBUG: Error in debugSelectedCenter: $e');
    }
  }
}
