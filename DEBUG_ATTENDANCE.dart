// ============================================================================
// TEMPORARY DEBUG CODE - Add this to your app to see what's happening
// ============================================================================

// Add this button to your settings page or create a debug page:

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:sembast/sembast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugAttendancePage extends StatelessWidget {
  const DebugAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Button 1: Show Local Attendance
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseService().database;
              final store = intMapStoreFactory.store('attendance');
              final records = await store.find(db);
              
              print('═══════════════════════════════════════');
              print('📊 LOCAL ATTENDANCE RECORDS: ${records.length}');
              print('═══════════════════════════════════════');
              
              for (var record in records) {
                print('\n📝 Record ID: ${record.key}');
                print('   Date: ${record.value['date']}');
                print('   Center: ${record.value['centerName'] ?? record.value['center_name']}');
                print('   Attendance: ${record.value['attendance']}');
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Check console for ${records.length} local records')),
              );
            },
            child: const Text('1. Show Local Attendance'),
          ),
          
          const SizedBox(height: 16),
          
          // Button 2: Show Supabase Attendance
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final center = userProvider.userSettings.selectedCenter ?? 'Unknown';
              
              final response = await Supabase.instance.client
                  .from('attendance_records')
                  .select()
                  .eq('center_name', center)
                  .order('date', ascending: false);
              
              print('═══════════════════════════════════════');
              print('☁️ SUPABASE ATTENDANCE RECORDS: ${response.length}');
              print('   Center: $center');
              print('═══════════════════════════════════════');
              
              for (var record in response) {
                print('\n📝 Record ID: ${record['id']}');
                print('   Date: ${record['date']}');
                print('   Center: ${record['center_name']}');
                print('   Attendance: ${record['attendance']}');
                print('   Created: ${record['created_at']}');
                print('   Updated: ${record['updated_at']}');
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Check console for ${response.length} cloud records')),
              );
            },
            child: const Text('2. Show Supabase Attendance'),
          ),
          
          const SizedBox(height: 16),
          
          // Button 3: Check for Duplicates in Supabase
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final center = userProvider.userSettings.selectedCenter ?? 'Unknown';
              
              final response = await Supabase.instance.client
                  .from('attendance_records')
                  .select()
                  .eq('center_name', center);
              
              // Group by date
              Map<String, List<dynamic>> byDate = {};
              for (var record in response) {
                String date = record['date'].toString().split('T')[0];
                byDate[date] = byDate[date] ?? [];
                byDate[date]!.add(record);
              }
              
              print('═══════════════════════════════════════');
              print('🔍 CHECKING FOR DUPLICATES');
              print('   Center: $center');
              print('═══════════════════════════════════════');
              
              int duplicateCount = 0;
              for (var entry in byDate.entries) {
                if (entry.value.length > 1) {
                  duplicateCount++;
                  print('\n❌ DUPLICATE FOUND for ${entry.key}:');
                  print('   ${entry.value.length} records exist!');
                  for (var record in entry.value) {
                    print('   - ID: ${record['id']}, Attendance: ${record['attendance']}');
                  }
                }
              }
              
              if (duplicateCount == 0) {
                print('\n✅ No duplicates found!');
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(duplicateCount == 0 
                    ? '✅ No duplicates' 
                    : '❌ Found $duplicateCount duplicate dates'),
                  backgroundColor: duplicateCount == 0 ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('3. Check for Duplicates'),
          ),
          
          const SizedBox(height: 16),
          
          // Button 4: Clear Local Attendance
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Local Attendance?'),
                  content: const Text('This will delete all local attendance data. You can re-sync from cloud.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                final db = await DatabaseService().database;
                await intMapStoreFactory.store('attendance').delete(db);
                
                print('═══════════════════════════════════════');
                print('🗑️ LOCAL ATTENDANCE CLEARED');
                print('═══════════════════════════════════════');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Local attendance cleared. Tap Sync to download from cloud.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('4. Clear Local Attendance'),
          ),
          
          const SizedBox(height: 16),
          
          // Button 5: Test Save Attendance
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final center = userProvider.userSettings.selectedCenter ?? 'Test Center';
              
              // Test data: 3 students
              final testAttendance = {
                999: true,   // Student 999 present
                998: false,  // Student 998 absent
                997: true,   // Student 997 present
              };
              
              print('═══════════════════════════════════════');
              print('🧪 TEST SAVE ATTENDANCE');
              print('   Center: $center');
              print('   Date: ${DateTime.now()}');
              print('   Data: $testAttendance');
              print('═══════════════════════════════════════');
              
              await attendanceProvider.saveAttendance(testAttendance, center);
              
              print('✅ Test attendance saved');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Test attendance saved. Check console.')),
              );
            },
            child: const Text('5. Test Save Attendance'),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Instructions:\n'
            '1. Tap button 1 to see local data\n'
            '2. Tap button 2 to see Supabase data\n'
            '3. Tap button 3 to check for duplicates\n'
            '4. If duplicates found, run RUN_THIS_NOW.sql in Supabase\n'
            '5. Then tap button 4 to clear local data\n'
            '6. Then sync to download clean data',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOW TO USE:
// ============================================================================
// 1. Add this file to your project
// 2. Add a button in your settings to open this page:
//
//    ElevatedButton(
//      onPressed: () {
//        Navigator.push(
//          context,
//          MaterialPageRoute(builder: (context) => const DebugAttendancePage()),
//        );
//      },
//      child: const Text('Debug Attendance'),
//    ),
//
// 3. Use the buttons to diagnose the issue
// 4. Check the console output
// ============================================================================
