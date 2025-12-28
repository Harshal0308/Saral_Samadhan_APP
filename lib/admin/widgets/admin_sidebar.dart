import 'package:flutter/material.dart';
import 'package:samadhan_app/admin/pages/admin_dashboard_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class AdminSidebar extends StatelessWidget {
  final AdminSection currentSection;
  final Function(AdminSection) onSectionChanged;
  final bool isExpanded;

  const AdminSidebar({
    super.key,
    required this.currentSection,
    required this.onSectionChanged,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 250 : 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B5FFF), Color(0xFF3B5FBF)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: SaralColors.primary,
                    size: 24,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SARAL Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  section: AdminSection.dashboard,
                ),
                _buildNavItem(
                  icon: Icons.school,
                  label: 'Students',
                  section: AdminSection.students,
                ),
                _buildNavItem(
                  icon: Icons.person,
                  label: 'Teachers',
                  section: AdminSection.teachers,
                ),
                _buildNavItem(
                  icon: Icons.fact_check,
                  label: 'Attendance',
                  section: AdminSection.attendance,
                ),
                _buildNavItem(
                  icon: Icons.volunteer_activism,
                  label: 'Volunteers',
                  section: AdminSection.volunteers,
                ),
                _buildNavItem(
                  icon: Icons.assignment,
                  label: 'Volunteer Reports',
                  section: AdminSection.volunteerReports,
                ),
                _buildNavItem(
                  icon: Icons.event,
                  label: 'Events',
                  section: AdminSection.events,
                ),
                _buildNavItem(
                  icon: Icons.schedule,
                  label: 'Schedules',
                  section: AdminSection.schedules,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required AdminSection section,
  }) {
    final isSelected = currentSection == section;
    
    return Tooltip(
      message: isExpanded ? '' : label,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? SaralColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? SaralColors.primary : Colors.grey[600],
            size: 22,
          ),
          title: isExpanded
              ? Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? SaralColors.primary : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                )
              : null,
          dense: true,
          onTap: () => onSectionChanged(section),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
