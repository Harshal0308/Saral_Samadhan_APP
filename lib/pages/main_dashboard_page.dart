import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/pages/attendance_options_page.dart';
import 'package:samadhan_app/pages/student_report_page.dart';
import 'package:samadhan_app/pages/volunteer_options_page.dart';
import 'package:samadhan_app/pages/exported_reports_page.dart';
import 'package:samadhan_app/pages/account_details_page.dart';
import 'package:samadhan_app/pages/notification_center_page.dart';
import 'package:samadhan_app/pages/offline_mode_sync_page.dart';
import 'package:samadhan_app/pages/photo_gallery_page.dart';
import 'package:samadhan_app/pages/events_activities_page.dart';
import 'package:samadhan_app/pages/class_scheduler_page.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final _cloudSyncService = CloudSyncService();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Sync data when dashboard loads
    _syncDataWithCloud();
  }

  Future<void> _syncDataWithCloud() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    final offlineProvider = Provider.of<OfflineSyncProvider>(context, listen: false);

    final centerName = userProvider.userSettings.selectedCenter;

    if (centerName == null || centerName.isEmpty) return;

    // Only sync if online
    if (!offlineProvider.isOnline) {
      print('⚠️ Offline - skipping cloud sync');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await _cloudSyncService.fullSyncForCenter(
        centerName,
        studentProvider,
        attendanceProvider,
        volunteerProvider,
      );
      
      // Refresh providers after sync
      await studentProvider.fetchStudents();
      await attendanceProvider.fetchAttendanceRecords();
      await volunteerProvider.fetchReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data synced with other teachers'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Sync failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context).userSettings.name;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SaralColors.primary,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'SARAL Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: Text(l10n.exports),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportedReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.scheduler),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClassSchedulerPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.events),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsActivitiesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Media Gallery'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhotoGalleryPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Offline Sync'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfflineModeSyncPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer<OfflineSyncProvider>(
            builder: (context, syncProvider, child) {
              if (!syncProvider.isOnline) {
                return Container(
                  width: double.infinity,
                  color: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'You are offline',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Attendance & Volunteer reports available offline',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header area (matches Saral UI) with rounded bottom
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: SaralColors.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Make left side flexible so icons on right never cause overflow
                            Expanded(
                              child: Row(
                                children: [
                                  // Logo with text
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Image.asset(
                                            'assets/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('SARAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.welcome + ',', style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Sync button
                                IconButton(
                                  icon: _isSyncing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.cloud_sync, color: Colors.white),
                                  onPressed: _isSyncing ? null : _syncDataWithCloud,
                                  tooltip: 'Sync with other teachers',
                                ),
                                Consumer<NotificationProvider>(
                                  builder: (context, notificationProvider, child) {
                                    final unreadCount = notificationProvider.unreadCount;
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.notifications, color: Colors.white),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const NotificationCenterPage()),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: SaralColors.accent.withOpacity(0.95),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                      ],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.account_circle, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  // Main Tiles (big full-width buttons)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildLargeTile(
                          context,
                          l10n.attendance,
                          'Take attendance using photos or mark manually',
                          Icons.how_to_reg,
                          SaralColors.muted,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AttendanceOptionsPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLargeTile(
                          context,
                          l10n.students,
                          'View student details, performance & reports',
                          Icons.people,
                          Color(0xFFE6F0FF),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StudentReportPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLargeTile(
                          context,
                          l10n.volunteers,
                          'Submit & manage volunteer daily reports',
                          Icons.person_search,
                          Color(0xFFF8E9FF),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const VolunteerOptionsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Actions (grid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Consumer<OfflineSyncProvider>(
                      builder: (context, syncProvider, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.quickActions, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                            const SizedBox(height: 8),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children: [
                                // Scheduler - disabled offline
                                _buildQuickAction(
                                  context,
                                  Icons.calendar_today,
                                  'Schedule',
                                  syncProvider.isOnline
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const ClassSchedulerPage()),
                                          );
                                        }
                                      : null,
                                  enabled: syncProvider.isOnline,
                                ),
                                // Events - disabled offline
                                _buildQuickAction(
                                  context,
                                  Icons.emoji_events,
                                  'Events',
                                  syncProvider.isOnline
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const EventsActivitiesPage()),
                                          );
                                        }
                                      : null,
                                  enabled: syncProvider.isOnline,
                                ),
                                // Media Gallery - disabled offline
                                _buildQuickAction(
                                  context,
                                  Icons.photo_library,
                                  'Gallery',
                                  syncProvider.isOnline
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const PhotoGalleryPage()),
                                          );
                                        }
                                      : null,
                                  enabled: syncProvider.isOnline,
                                ),
                                // Exports - always enabled
                                _buildQuickAction(
                                  context,
                                  Icons.download,
                                  'Export',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ExportedReportsPage()),
                                    );
                                  },
                                  enabled: true,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeTile(BuildContext context, String title, String subtitle, IconData icon, Color iconBg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
          border: Border.all(color: SaralColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback? onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: ColorFiltered(
          colorFilter: enabled
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : ColorFilter.mode(Colors.grey[400]!, BlendMode.saturation),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SaralRadius.radius),
              border: Border.all(color: SaralColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
