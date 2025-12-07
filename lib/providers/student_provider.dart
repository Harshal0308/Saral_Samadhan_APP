import 'package:flutter/material.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
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
  })  : this.lessonsLearned = lessonsLearned ?? [],
        this.testResults = testResults ?? {};

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'classBatch': classBatch,
      'centerName': centerName, // NEW: Include center
      'lessonsLearned': lessonsLearned,
      'testResults': testResults,
      'embeddings': embeddings,
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
  }) async {
    final db = await _dbService.database;

    // Check for existing student with same rollNo, classBatch, and centerName
    final finder = Finder(filter: Filter.and([
      Filter.equals('rollNo', rollNo),
      Filter.equals('classBatch', classBatch),
      Filter.equals('centerName', centerName), // NEW: Check center too
    ]));
    final existingStudent = await _studentStore.findFirst(db, finder: finder);

    if (existingStudent != null) {
      return null; // Student with this roll number, class, and center already exists
    }

    final studentData = {
      'name': name,
      'rollNo': rollNo,
      'classBatch': classBatch,
      'centerName': centerName, // NEW: Include center
      'embeddings': embeddings
    };
    final newId = await _studentStore.add(db, studentData);
    final newStudent = Student.fromMap(studentData, newId);
    await fetchStudents(); // Refetch to keep the list in sync
    return newStudent;
  }

  Future<void> updateStudent(Student student, {bool syncToCloud = true}) async {
    final db = await _dbService.database;
    await _studentStore.update(db, student.toMap(), finder: Finder(filter: Filter.byKey(student.id)));
    await fetchStudents();
    
    print('✏️ Student updated locally: ${student.name} (Roll: ${student.rollNo})');
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Queue the update operation
        await _cloudSyncV2.queueStudentUpdate(student);
        print('📝 Update operation queued for cloud sync');
        
        // Try to process immediately if online
        final result = await _cloudSyncV2.processSyncQueue();
        if (result['success'] == true) {
          print('✅ Student updated in cloud immediately');
        } else {
          print('⏳ Update queued - will sync when online: ${result['message']}');
        }
      } catch (e) {
        print('⚠️ Failed to sync update to cloud: $e');
        print('   Update is queued and will sync later');
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
        // Queue the delete operation
        await _cloudSyncV2.queueStudentDelete(
          student.rollNo,
          student.classBatch,
          student.centerName,
        );
        print('📝 Delete operation queued for cloud sync');
        
        // Try to process immediately if online
        final result = await _cloudSyncV2.processSyncQueue();
        if (result['success'] == true) {
          print('✅ Student deleted from cloud immediately');
        } else {
          print('⏳ Delete queued - will sync when online: ${result['message']}');
        }
      } catch (e) {
        print('⚠️ Failed to sync delete to cloud: $e');
        print('   Delete is queued and will sync later');
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
    
    // Sync to cloud if requested
    if (syncToCloud) {
      try {
        // Queue each delete operation
        for (var student in studentsToDelete) {
          await _cloudSyncV2.queueStudentDelete(
            student.rollNo,
            student.classBatch,
            student.centerName,
          );
        }
        
        // Try to process immediately if online
        await _cloudSyncV2.processSyncQueue();
      } catch (e) {
        print('⚠️ Failed to sync deletes to cloud: $e');
        // Deletes are queued, will sync later
      }
    }
  }

  Future<void> fetchStudents() async {
    final db = await _dbService.database;
    final snapshots = await _studentStore.find(db);
    _students = snapshots.map((snapshot) {
      return Student.fromMap(snapshot.value, snapshot.key);
    }).toList();
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
