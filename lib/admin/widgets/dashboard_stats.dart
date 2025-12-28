import 'package:flutter/material.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class DashboardStats extends StatelessWidget {
  final Map<String, int> stats;

  const DashboardStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Database Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SaralColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time data from Supabase',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                     constraints.maxWidth > 800 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Students',
                    stats['students'] ?? 0,
                    Icons.school,
                    SaralColors.studentsColor,
                    SaralColors.studentsBg,
                  ),
                  _buildStatCard(
                    'Teachers',
                    stats['teachers'] ?? 0,
                    Icons.person,
                    SaralColors.primary,
                    SaralColors.muted,
                  ),
                  _buildStatCard(
                    'Attendance Records',
                    stats['attendance'] ?? 0,
                    Icons.fact_check,
                    SaralColors.attendanceColor,
                    SaralColors.attendanceBg,
                  ),
                  _buildStatCard(
                    'Volunteers',
                    stats['volunteers'] ?? 0,
                    Icons.volunteer_activism,
                    SaralColors.volunteersColor,
                    SaralColors.volunteersBg,
                  ),
                  _buildStatCard(
                    'Volunteer Reports',
                    stats['volunteerReports'] ?? 0,
                    Icons.assignment,
                    SaralColors.analyticsColor,
                    SaralColors.analyticsBg,
                  ),
                  _buildStatCard(
                    'Events',
                    stats['events'] ?? 0,
                    Icons.event,
                    SaralColors.eventsColor,
                    SaralColors.eventsBg,
                  ),
                  _buildStatCard(
                    'Schedules',
                    stats['schedules'] ?? 0,
                    Icons.schedule,
                    SaralColors.scheduleColor,
                    SaralColors.scheduleBg,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: SaralColors.primary),
                    const SizedBox(width: 12),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildActionChip(
                      'Export Students CSV',
                      Icons.download,
                      () {},
                    ),
                    _buildActionChip(
                      'View All Centers',
                      Icons.location_city,
                      () {},
                    ),
                    _buildActionChip(
                      'Generate Report',
                      Icons.analytics,
                      () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: SaralColors.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: SaralColors.muted,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
