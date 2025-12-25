import 'package:flutter/material.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:sembast/sembast.dart';

class Student {
  final int id;
  final String name;
  final String rollNo;
  final String classBatch;
  final String centerName; // NEW: Center where student belongs
  bool isPresent; // Added for attendance page
  List<String> lessonsLearned; // List of activities/lessons taught to this student
  Map<String, String> testResults; // Map of testTopic -> marks/grade
  List<List<double>>? embeddings; // Store multiple embeddings for better accuracy
  Map<String, BaselineAssessment> baselineAssessments; // Subject -> Assessment
  Map<String, TopicProgress> topicProgress; // "subject:topic" -> Progress
  Map<String, TopicEvaluation> topicEvaluations; // NEW: Topic evaluations


  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.classBatch,
    required this.centerName, // NEW: Required parameter
    this.isPresent = false,
    List<String>? lessonsLearned,
    Map<String, String>? testResults,
    this.embeddings,
    Map<String, BaselineAssessment>? baselineAssessments,
    Map<String, TopicProgress>? topicProgress,
    Map<String, TopicEvaluation>? topicEvaluations,
  })  : this.lessonsLearned = lessonsLearned ?? [],
        this.testResults = testResults ?? {},
        this.baselineAssessments = baselineAssessments ?? {},
        this.topicProgress = topicProgress ?? {},
        this.topicEvaluations = topicEvaluations ?? {};

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'classBatch': classBatch,
      'centerName': centerName, // NEW: Include center
      'lessonsLearned': lessonsLearned,
      'testResults': testResults,
      'embeddings': embeddings,
      'baselineAssessments': baselineAssessments.map((k, v) => MapEntry(k, v.toMap())),
      'topicProgress': topicProgress.map((k, v) => MapEntry(k, v.toMap())),
      'topicEvaluations': topicEvaluations.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  static Student fromMap(Map<String, dynamic> map, int id) {
    // Handle both single (old) and multiple (new) embedding formats for backward compatibility
    List<List<double>>? studentEmbeddings;
    if (map['embeddings'] != null) {
      // New format: List<List<double>>
      try {
        studentEmbeddings = (map['embeddings'] as List)
            .map((e) => (e as List).map((d) => (d as num).toDouble()).toList())
            .toList();
      } catch (e) {
        print('Error parsing embeddings: $e');
        studentEmbeddings = null;
      }
    } else if (map['embedding'] != null) {
      // Old format: List<double> - wrap it in a list
      try {
        studentEmbeddings = [(map['embedding'] as List).map((d) => (d as num).toDouble()).toList()];
      } catch (e) {
        print('Error parsing embedding: $e');
        studentEmbeddings = null;
      }
    }

    // Parse baseline assessments
    Map<String, BaselineAssessment> baselineAssessments = {};
    if (map['baselineAssessments'] != null) {
      try {
        final assessmentsMap = map['baselineAssessments'] as Map<String, dynamic>;
        baselineAssessments = assessmentsMap.map(
          (k, v) => MapEntry(k, BaselineAssessment.fromMap(v as Map<String, dynamic>)),
        );
      } catch (e) {
        print('Error parsing baseline assessments: $e');
      }
    }

    // Parse topic progress
    Map<String, TopicProgress> topicProgress = {};
    if (map['topicProgress'] != null) {
      try {
        final progressMap = map['topicProgress'] as Map<String, dynamic>;
        topicProgress = progressMap.map(
          (k, v) => MapEntry(k, TopicProgress.fromMap(v as Map<String, dynamic>)),
        );
      } catch (e) {
        print('Error parsing topic progress: $e');
      }
    }

    // Parse topic evaluations
    Map<String, TopicEvaluation> topicEvaluations = {};
    if (map['topicEvaluations'] != null) {
      try {
        final evaluationsMap = map['topicEvaluations'] as Map<String, dynamic>;
        topicEvaluations = evaluationsMap.map(
          (k, v) => MapEntry(k, TopicEvaluation.fromMap(v as Map<String, dynamic>)),
        );
      } catch (e) {
        print('Error parsing topic evaluations: $e');
      }
    }

    return Student(
      id: id,
      name: map['name'] ?? '',
      rollNo: map['roll_no'] ?? map['rollNo'] ?? '',
      classBatch: map['class_batch'] ?? map['classBatch'] ?? '',
      centerName: map['center_name'] ?? map['centerName'] ?? 'Unknown',
      lessonsLearned: map['lessons_learned'] != null 
          ? List<String>.from(map['lessons_learned']) 
          : (map['lessonsLearned'] != null ? List<String>.from(map['lessonsLearned']) : []),
      testResults: map['test_results'] != null 
          ? Map<String, String>.from(map['test_results']) 
          : (map['testResults'] != null ? Map<String, String>.from(map['testResults']) : {}),
      embeddings: studentEmbeddings,
      baselineAssessments: baselineAssessments,
      topicProgress: topicProgress,
      topicEvaluations: topicEvaluations,
    );
  }
}

class StudentProvider with ChangeNotifier {
  final _studentStore = intMapStoreFactory.store('students');
  final DatabaseService _dbService = DatabaseService();
  final _cloudSync = CloudSyncService();
  final _cloudSyncV2 = CloudSyncServiceV2();

  List<Student> _students = [];
  List<Student> get students => _students;

  Future<Student?> addStudent({
    required String name,
    required String rollNo,
    required String classBatch,
    required String centerName, // NEW: Center parameter
    List<List<double>>? embeddings,
    Map<String, BaselineAssessment>? baselineAssessments,
    bool syncToCloud = true,
  }) async {
    print('📝 Adding student: $name (Roll: $rollNo, Class: $classBatch, Center: "$centerName")');
    
    final db = await _dbService.database;

    // Check for existing student with same rollNo, classBatch, and centerName
    final finder = Finder(filter: Filter.and([
      Filter.equals('rollNo', rollNo),
      Filter.equals('classBatch', classBatch),
      Filter.equals('centerName', centerName), // NEW: Check center too
    ]));
    final existingStudent = await _studentStore.findFirst(db, finder: finder);

    if (existingStudent != null) {
      print('⚠️ Student already exists: $name (Roll: $rollNo, Class: $classBatch, Center: "$centerName")');
      return null; // Student with this roll number, class, and center already exists
    }

    final studentData = {
      'name': name,
      'rollNo': rollNo,
      'classBatch': classBatch,
      'centerName': centerName, // NEW: Include center
      'embeddings': embeddings,
      'baselineAssessments': baselineAssessments?.map((k, v) => MapEntry(k, v.toMap())) ?? {},
      'topicProgress': <String, Map<String, dynamic>>{},
    };
    
    try {
      final newId = await _studentStore.add(db, studentData);
      final newStudent = Student.fromMap(studentData, newId);
      await fetchStudents(); // Refetch to keep the list in sync
      
      print('✅ Student added successfully to local database: $name (ID: $newId)');
      print('📊 Total students in local database: ${_students.length}');
      
      // Handle cloud sync if requested
      if (syncToCloud) {
        print('☁️ Syncing student to cloud: $name');
        await _cloudSyncV2.saveStudentWithSync(newStudent);
      }
      
      return newStudent;
    } catch (e) {
      print('❌ Error adding student to local database: $e');
      return null;
    }
  }

  Future<void> updateStudent(Student student, {bool syncToCloud = true}) async {
    final db = await _dbService.database;
    await _studentStore.update(db, student.toMap(), finder: Finder(filter: Filter.byKey(student.id)));
    await fetchStudents();
    
    print('✏️ Student updated locally: ${student.name} (Roll: ${student.rollNo})');
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Check if online
        final isOnline = await _cloudSyncV2.isOnline();
        
        if (isOnline) {
          print('🌐 Online - attempting immediate sync of student update to cloud');
          
          // Try immediate upload
          await _cloudSyncV2.queueStudentUpdate(student);
          final syncResult = await _cloudSyncV2.processSyncQueue();
          
          if (syncResult['success'] == true) {
            print('✅ Student update immediately synced to cloud');
          } else {
            print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
          }
        } else {
          print('📱 Offline - student update saved locally, will sync when online');
          
          // Queue for later sync when online
          await _cloudSyncV2.queueStudentUpdate(student);
          print('📋 Student update queued for sync when online');
        }
      } catch (e) {
        print('⚠️ Failed to sync student update: $e');
        // Update is saved locally, will sync later
      }
    }
  }

  Future<void> deleteStudent(int id, {bool syncToCloud = true}) async {
    // Get student info before deleting (needed for cloud sync)
    final student = _students.firstWhere((s) => s.id == id);
    
    // Delete from local database
    final db = await _dbService.database;
    await _studentStore.delete(db, finder: Finder(filter: Filter.byKey(id)));
    await fetchStudents();
    
    print('🗑️ Student deleted locally: ${student.name} (Roll: ${student.rollNo})');
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Check if online
        final isOnline = await _cloudSyncV2.isOnline();
        
        if (isOnline) {
          print('🌐 Online - attempting immediate sync of student delete to cloud');
          
          // Try immediate delete
          await _cloudSyncV2.queueStudentDelete(
            student.rollNo,
            student.classBatch,
            student.centerName,
          );
          final syncResult = await _cloudSyncV2.processSyncQueue();
          
          if (syncResult['success'] == true) {
            print('✅ Student delete immediately synced to cloud');
          } else {
            print('⚠️ Immediate delete sync failed, will retry later: ${syncResult['message']}');
          }
        } else {
          print('📱 Offline - student delete saved locally, will sync when online');
          
          // Queue for later sync when online
          await _cloudSyncV2.queueStudentDelete(
            student.rollNo,
            student.classBatch,
            student.centerName,
          );
          print('📋 Student delete queued for sync when online');
        }
      } catch (e) {
        print('⚠️ Failed to sync student delete: $e');
        // Delete is saved locally, will sync later
      }
    }
  }

  Future<void> deleteMultipleStudents(List<int> ids, {bool syncToCloud = true}) async {
    // Get student info before deleting (needed for cloud sync)
    final studentsToDelete = _students.where((s) => ids.contains(s.id)).toList();
    
    // Delete from local database
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await _studentStore.delete(txn, finder: Finder(filter: Filter.inList(Field.key, ids)));
    });
    await fetchStudents();
    
    print('🗑️ ${ids.length} students deleted locally');
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Check if online
        final isOnline = await _cloudSyncV2.isOnline();
        
        if (isOnline) {
          print('🌐 Online - attempting immediate sync of student deletes to cloud');
          
          // Queue each delete operation
          for (var student in studentsToDelete) {
            await _cloudSyncV2.queueStudentDelete(
              student.rollNo,
              student.classBatch,
              student.centerName,
            );
          }
          
          // Try immediate processing
          final syncResult = await _cloudSyncV2.processSyncQueue();
          
          if (syncResult['success'] == true) {
            print('✅ Student deletes immediately synced to cloud');
          } else {
            print('⚠️ Immediate delete sync failed, will retry later: ${syncResult['message']}');
          }
        } else {
          print('📱 Offline - student deletes saved locally, will sync when online');
          
          // Queue for later sync when online
          for (var student in studentsToDelete) {
            await _cloudSyncV2.queueStudentDelete(
              student.rollNo,
              student.classBatch,
              student.centerName,
            );
          }
          print('📋 Student deletes queued for sync when online');
        }
      } catch (e) {
        print('⚠️ Failed to sync deletes to cloud: $e');
        // Deletes are queued, will sync later
      }
    }
  }

  Future<void> fetchStudents() async {
    print('📚 Fetching students from local database...');
    final db = await _dbService.database;
    final snapshots = await _studentStore.find(db);
    _students = snapshots.map((snapshot) {
      return Student.fromMap(snapshot.value, snapshot.key);
    }).toList();
    
    print('📊 Loaded ${_students.length} students from local database');
    
    // Debug: Show students by center
    final centerGroups = <String, int>{};
    for (var student in _students) {
      centerGroups[student.centerName] = (centerGroups[student.centerName] ?? 0) + 1;
    }
    
    print('📋 Students by center:');
    centerGroups.forEach((center, count) {
      print('   🏢 "$center": $count students');
    });
    
    notifyListeners();
  }

  // NEW: Get students filtered by center
  List<Student> getStudentsByCenter(String centerName) {
    return _students.where((student) => student.centerName == centerName).toList();
  }

  // NEW: Get all unique centers from students
  List<String> getAllCenters() {
    final centers = <String>{};
    for (var student in _students) {
      centers.add(student.centerName);
    }
    return centers.toList()..sort();
  }

  // NEW: Get students by center and class batch
  List<Student> getStudentsByCenterAndClass(String centerName, String classBatch) {
    return _students
        .where((student) => student.centerName == centerName && student.classBatch == classBatch)
        .toList();
  }

  // NEW: Get all class batches for a specific center
  List<String> getClassBatchesByCenter(String centerName) {
    final batches = <String>{};
    for (var student in _students) {
      if (student.centerName == centerName) {
        batches.add(student.classBatch);
      }
    }
    return batches.toList()..sort();
  }
}
