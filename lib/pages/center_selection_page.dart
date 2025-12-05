import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/pages/main_dashboard_page.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';

class CenterSelectionPage extends StatelessWidget {
  const CenterSelectionPage({super.key});

  final List<Map<String, String>> centers = const [
    {'name': 'Mumbai Central', 'location': 'Dadar, Mumbai', 'students': '45 students'},
    {'name': 'Pune East Center', 'location': 'Kothrud, Pune', 'students': '32 students'},
    {'name': 'Nashik Hub', 'location': 'College Road, Nashik', 'students': '28 students'},
    {'name': 'Nagpur Center', 'location': 'Sitabuldi, Nagpur', 'students': '38 students'},
    {'name': 'Thane Branch', 'location': 'Ghodbunder, Thane', 'students': '41 students'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Curved top with gradient background
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B5FFF), Color(0xFF3B5FBF)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SARAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Your Center',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choose where you work',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Center list
                        ...List.generate(
                          centers.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCenterButton(context, centers[index]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context, Map<String, String> center) {
    return GestureDetector(
      onTap: () async {
        print('✅ Selected Center: ${center['name']}');
        
        // Get providers before showing dialog
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final offlineProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
        final studentProvider = Provider.of<StudentProvider>(context, listen: false);
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
        
        // Show loading dialog
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Syncing data...'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        
        try {
          // Save selected center
          await userProvider.updateSelectedCenter(center['name']);
          
          // Auto-sync data for the selected center
          if (offlineProvider.isOnline) {
            print('🔄 Auto-syncing data for ${center['name']}...');
            
            final cloudSyncService = CloudSyncService();
            
            // Sync data for the selected center
            await cloudSyncService.fullSyncForCenter(
              center['name']!,
              studentProvider,
              attendanceProvider,
              volunteerProvider,
            );
            
            // Refresh providers after sync
            await studentProvider.fetchStudents();
            await attendanceProvider.fetchAttendanceRecords();
            await volunteerProvider.fetchReports();
            
            print('✅ Auto-sync completed for ${center['name']}');
          } else {
            print('⚠️ Offline - sync will happen when online');
          }
        } catch (e) {
          print('❌ Error during auto-sync: $e');
          // Show error message
          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync error: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return; // Don't navigate if there was an error
        }
        
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        // Navigate to dashboard
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainDashboardPage()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5B5FFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF5B5FFF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
