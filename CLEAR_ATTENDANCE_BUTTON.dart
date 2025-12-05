// 🔧 TEMPORARY DEBUG BUTTON - Add this to your settings or debug page
// This will clear all attendance data so you can start fresh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:sembast/sembast.dart';

class ClearAttendanceButton extends StatelessWidget {
  const ClearAttendanceButton({super.key});

  Future<void> _clearAllAttendance(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Clear All Attendance?'),
          content: const Text(
            'This will delete ALL attendance records (local and cloud) for your center.\n\n'
            'This action cannot be undone!\n\n'
            'Use this to fix corrupted attendance data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clearing attendance...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get center name
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final centerName = userProvider.userSettings.selectedCenter ?? 'Unknown';

      // 1. Clear local attendance
      final db = await DatabaseService().database;
      final attendanceStore = intMapStoreFactory.store('attendance');
      
      // Delete all attendance records for this center
      final finder = Finder(
        filter: Filter.or([
          Filter.equals('centerName', centerName),
          Filter.equals('center_name', centerName),
        ]),
      );
      
      final deletedLocal = await attendanceStore.delete(db, finder: finder);
      print('✅ Cleared $deletedLocal local attendance records');

      // 2. Clear cloud attendance
      try {
        await Supabase.instance.client
            .from('attendance_records')
            .delete()
            .eq('center_name', centerName);
        print('✅ Cleared cloud attendance for $centerName');
      } catch (e) {
        print('⚠️ Error clearing cloud attendance: $e');
      }

      // Success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cleared all attendance for $centerName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error clearing attendance: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Debug Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Use this if attendance is showing wrong data due to corrupted records.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _clearAllAttendance(context),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// HOW TO USE:
// Add this to your settings page or create a debug page:
//
// import 'CLEAR_ATTENDANCE_BUTTON.dart';
//
// Then in your build method:
// ClearAttendanceButton(),
