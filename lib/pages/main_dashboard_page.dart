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
import 'package:samadhan_app/l10n/app_localizations.dart';

class MainDashboardPage extends StatelessWidget {
  const MainDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context).userSettings.name;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saralDashboard),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
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
                          color: Theme.of(context).colorScheme.secondary,
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
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
              );
            },
          ),
        ],
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
                  color: Colors.red,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    'You are offline. Some features may be unavailable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.welcome}, $userName!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      _buildDashboardTile(context, l10n.attendance, Icons.how_to_reg, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AttendanceOptionsPage()),
                        );
                      }),
                      _buildDashboardTile(context, l10n.students, Icons.people, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentReportPage()),
                        );
                      }),
                      _buildDashboardTile(context, l10n.volunteers, Icons.handshake, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VolunteerOptionsPage()),
                        );
                      }),
                      _buildDashboardTile(context, l10n.scheduler, Icons.calendar_today, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ClassSchedulerPage()),
                        );
                      }),
                       _buildDashboardTile(context, l10n.events, Icons.event, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EventsActivitiesPage()),
                        );
                      }),
                      _buildDashboardTile(context, l10n.exports, Icons.article, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExportedReportsPage()),
                        );
                      }),
                    ],
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
}
