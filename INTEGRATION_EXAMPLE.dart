// ============================================================================
// INTEGRATION EXAMPLE: How to Use the New Sync Queue System
// ============================================================================

// This file shows how to integrate the sync queue into your existing code.
// Copy these patterns into your actual files.

// ============================================================================
// 1. UPDATE ATTENDANCE PROVIDER
// ============================================================================

// In lib/providers/attendance_provider.dart
// Add this import at the top:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

// Add this property to the class:
final _cloudSyncV2 = CloudSyncServiceV2();

// Update the saveAttendance method:
Future<void> saveAttendance(Map<int, bool> attendance, String centerName) async {
  final db = await _dbService.database;
  final record = AttendanceRecord(
    id: DateTime.now().millisecondsSinceEpoch, // Use timestamp as ID
    date: DateTime.now(),
    centerName: centerName,
    attendance: attendance,
  );
  
  // Save locally
  await _attendanceStore.add(db, record.toMap());
  
  // Add to sync queue (NEW!)
  await _cloudSyncV2.queueAttendanceUpload(record);
  
  await fetchAttendanceRecords();
}

// ============================================================================
// 2. UPDATE STUDENT PROVIDER
// ============================================================================

// In lib/providers/student_provider.dart
// Add this import at the top:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

// Add this property to the class:
final _cloudSyncV2 = CloudSyncServiceV2();

// Update the addStudent method:
Future<Student?> addStudent({
  required String name,
  required String rollNo,
  required String classBatch,
  required String centerName,
  List<List<double>>? embeddings,
}) async {
  final db = await _dbService.database;

  // Check for existing student
  final finder = Finder(filter: Filter.and([
    Filter.equals('rollNo', rollNo),
    Filter.equals('classBatch', classBatch),
    Filter.equals('centerName', centerName),
  ]));
  final existingStudent = await _studentStore.findFirst(db, finder: finder);

  if (existingStudent != null) {
    return null;
  }

  final studentData = {
    'name': name,
    'rollNo': rollNo,
    'classBatch': classBatch,
    'centerName': centerName,
    'embeddings': embeddings
  };
  
  // Save locally
  final newId = await _studentStore.add(db, studentData);
  final newStudent = Student.fromMap(studentData, newId);
  
  // Add to sync queue (NEW!)
  await _cloudSyncV2.queueStudentUpload(newStudent);
  
  await fetchStudents();
  return newStudent;
}

// ============================================================================
// 3. UPDATE VOLUNTEER PROVIDER
// ============================================================================

// In lib/providers/volunteer_provider.dart
// Add this import at the top:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

// Add this property to the class:
final _cloudSyncV2 = CloudSyncServiceV2();

// Update the addReport method:
Future<void> addReport(VolunteerReport report) async {
  final db = await _dbService.database;
  
  // Save locally
  await _reportStore.record(report.id).put(db, report.toMap());
  
  // Add to sync queue (NEW!)
  await _cloudSyncV2.queueVolunteerReportUpload(report);
  
  await fetchReports();
}

// ============================================================================
// 4. UPDATE MAIN DASHBOARD PAGE
// ============================================================================

// In lib/pages/main_dashboard_page.dart
// Replace the import:
// OLD: import 'package:samadhan_app/services/cloud_sync_service.dart';
// NEW:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

// Update the property:
// OLD: final _cloudSyncService = CloudSyncService();
// NEW:
final _cloudSyncService = CloudSyncServiceV2();

// The _syncDataWithCloud method stays mostly the same!
// It will automatically process the queue before downloading

// ============================================================================
// 5. ADD DEBUG PAGE TO DRAWER
// ============================================================================

// In lib/pages/main_dashboard_page.dart
// Add this import at the top:
import 'package:samadhan_app/pages/sync_queue_debug_page.dart';

// Add this to the drawer (after Offline Sync):
ListTile(
  leading: const Icon(Icons.bug_report),
  title: const Text('Sync Queue Debug'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SyncQueueDebugPage()),
    );
  },
),

// ============================================================================
// 6. AUTO-SYNC WHEN COMING ONLINE
// ============================================================================

// In lib/providers/offline_sync_provider.dart
// Add this import at the top:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';

// Update the _updateConnectionStatus method:
void _updateConnectionStatus(List<ConnectivityResult> results) {
  final wasOnline = _isOnline;
  _isOnline = results.contains(ConnectivityResult.mobile) || 
              results.contains(ConnectivityResult.wifi);
  
  if (_isOnline) {
    _syncStatusMessage = "Connected. Ready to sync.";
    
    // Auto-sync when coming online (NEW!)
    if (!wasOnline) {
      _autoSyncWhenOnline();
    }
  } else {
    _syncStatusMessage = "Offline. Changes will be synced when online.";
  }
  notifyListeners();
}

// Add this new method:
Future<void> _autoSyncWhenOnline() async {
  try {
    final cloudSync = CloudSyncServiceV2();
    
    // Check if there are pending items
    final stats = await cloudSync.getSyncQueueStats();
    final pendingCount = stats['pending'] ?? 0;
    
    if (pendingCount > 0) {
      print('🔄 Auto-syncing $pendingCount pending items...');
      _syncStatusMessage = "Auto-syncing $pendingCount items...";
      notifyListeners();
      
      // Process the queue
      final result = await cloudSync.processSyncQueue();
      
      if (result['success']) {
        _syncStatusMessage = "Sync complete. ${result['successCount']} items uploaded.";
      } else {
        _syncStatusMessage = "Sync completed with ${result['failureCount']} errors.";
      }
      notifyListeners();
    }
  } catch (e) {
    print('❌ Auto-sync error: $e');
    _syncStatusMessage = "Auto-sync failed. Tap sync button to retry.";
    notifyListeners();
  }
}

// ============================================================================
// 7. SHOW SYNC QUEUE STATUS IN OFFLINE SYNC PAGE
// ============================================================================

// In lib/pages/offline_mode_sync_page.dart
// Add this import:
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/pages/sync_queue_debug_page.dart';

// Add this property to the state class:
final _cloudSyncV2 = CloudSyncServiceV2();
Map<String, int> _queueStats = {};

// Add this method to load queue stats:
Future<void> _loadQueueStats() async {
  final stats = await _cloudSyncV2.getSyncQueueStats();
  setState(() {
    _queueStats = stats;
  });
}

// Call it in initState:
@override
void initState() {
  super.initState();
  _loadQueueStats();
}

// Add this card after the Auto-Sync Status card:
Card(
  elevation: 2,
  margin: const EdgeInsets.only(bottom: 16),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sync Queue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SyncQueueDebugPage(),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQueueStat('Pending', _queueStats['pending'] ?? 0, Colors.orange),
            _buildQueueStat('Failed', _queueStats['failed'] ?? 0, Colors.red),
            _buildQueueStat('Total', _queueStats['total'] ?? 0, Colors.blue),
          ],
        ),
      ],
    ),
  ),
),

// Add this helper method:
Widget _buildQueueStat(String label, int count, Color color) {
  return Column(
    children: [
      Text(
        count.toString(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

// ============================================================================
// 8. PERIODIC BACKGROUND SYNC (OPTIONAL)
// ============================================================================

// In lib/main.dart or your main app widget
// Add this to set up periodic sync:

import 'dart:async';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';

class _MyAppState extends State<MyApp> {
  Timer? _syncTimer;
  final _cloudSync = CloudSyncServiceV2();

  @override
  void initState() {
    super.initState();
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    // Sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final stats = await _cloudSync.getSyncQueueStats();
        final pending = stats['pending'] ?? 0;
        
        if (pending > 0) {
          print('🔄 Periodic sync: Processing $pending pending items...');
          await _cloudSync.processSyncQueue();
        }
      } catch (e) {
        print('❌ Periodic sync error: $e');
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

// ============================================================================
// TESTING CHECKLIST
// ============================================================================

/*
✅ Test Offline Scenario:
1. Turn off internet
2. Take attendance
3. Open Sync Queue Debug page
4. Verify 1 pending item appears
5. Turn on internet
6. Tap "Process Queue"
7. Verify item is removed and data is in Supabase

✅ Test Failure Scenario:
1. Simulate network error (disconnect during sync)
2. Item should be marked as failed
3. Check error message in debug page
4. Tap "Retry Failed"
5. Verify success

✅ Test Auto-Sync:
1. Go offline
2. Add student, take attendance, submit report
3. Check queue (should have 3 items)
4. Go online
5. Wait for auto-sync
6. Verify all items synced

✅ Test App Restart:
1. Add items to queue
2. Close app completely
3. Reopen app
4. Check queue (items should still be there)
5. Process queue
6. Verify success
*/

// ============================================================================
// DONE! Your app now has a robust sync queue system.
// ============================================================================
