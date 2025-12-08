// DIAGNOSTIC SCRIPT: Check Attendance Records in Database
// Run this to see what attendance records are actually saved

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';

/// Test page to check attendance records
class CheckAttendanceRecordsPage extends StatelessWidget {
  const CheckAttendanceRecordsPage({super.key});

  Future<void> _checkRecords(BuildContext context) async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    print('\n═══════════════════════════════════════════════════════');
    print('📊 ATTENDANCE RECORDS DIAGNOSTIC');
    print('═══════════════════════════════════════════════════════\n');
    
    // Check last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    print('🔍 Checking records for:');
    print('   Center: $selectedCenter');
    print('   Date Range: ${thirtyDaysAgo.toLocal().toString().split(' ')[0]} to ${now.toLocal().toString().split(' ')[0]}');
    print('');
    
    final records = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
      selectedCenter,
      thirtyDaysAgo,
      now,
    );
    
    print('📋 FOUND ${records.length} ATTENDANCE RECORDS:\n');
    
    if (records.isEmpty) {
      print('❌ NO RECORDS FOUND!');
      print('   This means:');
      print('   1. No attendance has been marked in the last 30 days, OR');
      print('   2. Records are not being saved properly, OR');
      print('   3. Records are saved with a different center name');
      print('');
    } else {
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        print('Record ${i + 1}:');
        print('   ID: ${record.id}');
        print('   Date: ${record.date.toLocal().toString().split(' ')[0]}');
        print('   Center: ${record.centerName}');
        print('   Students: ${record.attendance.length}');
        
        // Count present/absent
        final present = record.attendance.values.where((v) => v == true).length;
        final absent = record.attendance.values.where((v) => v == false).length;
        print('   Present: $present, Absent: $absent');
        
        // Show first 3 students as sample
        final sampleKeys = record.attendance.keys.take(3).toList();
        print('   Sample students:');
        for (var key in sampleKeys) {
          print('      $key: ${record.attendance[key] == true ? "Present" : "Absent"}');
        }
        print('');
      }
    }
    
    // Check ALL records (not just selected center)
    print('═══════════════════════════════════════════════════════');
    print('📊 CHECKING ALL CENTERS (for comparison)');
    print('═══════════════════════════════════════════════════════\n');
    
    await attendanceProvider.fetchAttendanceRecords();
    final allRecords = attendanceProvider.attendanceRecords;
    
    print('📋 TOTAL RECORDS IN DATABASE: ${allRecords.length}\n');
    
    if (allRecords.isNotEmpty) {
      // Group by center
      final Map<String, int> centerCounts = {};
      for (var record in allRecords) {
        centerCounts[record.centerName] = (centerCounts[record.centerName] ?? 0) + 1;
      }
      
      print('Records by center:');
      centerCounts.forEach((center, count) {
        print('   $center: $count records');
      });
      print('');
      
      // Show date range
      final dates = allRecords.map((r) => r.date).toList()..sort();
      if (dates.isNotEmpty) {
        print('Date range:');
        print('   Oldest: ${dates.first.toLocal().toString().split(' ')[0]}');
        print('   Newest: ${dates.last.toLocal().toString().split(' ')[0]}');
      }
    }
    
    print('\n═══════════════════════════════════════════════════════');
    print('✅ DIAGNOSTIC COMPLETE');
    print('═══════════════════════════════════════════════════════\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Attendance Records'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Attendance Records Diagnostic',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'This will check what attendance records are saved in the database.\n\nCheck the console logs for detailed output.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _checkRecords(context),
              icon: const Icon(Icons.search),
              label: const Text('Run Diagnostic'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to use:
/// 
/// 1. Add this page to your navigation:
///    Navigator.push(context, MaterialPageRoute(
///      builder: (_) => CheckAttendanceRecordsPage()
///    ));
/// 
/// 2. Tap "Run Diagnostic" button
/// 
/// 3. Check console logs for detailed output
/// 
/// 4. Look for:
///    - How many records are found
///    - What dates they cover
///    - Which centers they belong to
///    - Sample student data
