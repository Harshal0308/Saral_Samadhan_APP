import 'package:flutter/material.dart';
import 'package:samadhan_app/pages/volunteer_daily_report_page.dart';
import 'package:samadhan_app/pages/volunteer_reports_list_page.dart';
import 'package:samadhan_app/pages/volunteer_test_report_page.dart';

class VolunteerOptionsPage extends StatelessWidget {
  const VolunteerOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Volunteer Reports',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF8B5CF6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Submit daily reports and track your volunteer activities',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Daily Report Card
            _buildOptionCard(
              context: context,
              icon: Icons.edit_document,
              iconColor: Colors.white,
              iconBackgroundColor: const Color(0xFF10B981),
              title: 'Submit Daily Report',
              subtitle: 'Record your daily volunteer activities',
              cardColor: const Color(0xFF10B981),
              isHighlighted: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VolunteerDailyReportPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Submit Test Report Card
            _buildOptionCard(
              context: context,
              icon: Icons.assignment,
              iconColor: const Color(0xFF3B82F6),
              iconBackgroundColor: const Color(0xFFDBEAFE),
              title: 'Submit Test Report',
              subtitle: 'Record test results for students',
              cardColor: Colors.white,
              isHighlighted: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VolunteerTestReportPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // View Past Reports Card
            _buildOptionCard(
              context: context,
              icon: Icons.history,
              iconColor: const Color(0xFF8B5CF6),
              iconBackgroundColor: const Color(0xFFEDE9FE),
              title: 'View Past Reports',
              subtitle: 'See your submitted reports',
              cardColor: Colors.white,
              isHighlighted: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VolunteerReportsListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required Color cardColor,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isHighlighted ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isHighlighted 
                              ? Colors.white.withOpacity(0.9) 
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: isHighlighted 
                      ? Colors.white.withOpacity(0.8) 
                      : const Color(0xFF9CA3AF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
