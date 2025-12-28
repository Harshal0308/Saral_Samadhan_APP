import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/admin/providers/admin_auth_provider.dart';
import 'package:samadhan_app/admin/providers/admin_data_provider.dart';
import 'package:samadhan_app/admin/widgets/admin_sidebar.dart';
import 'package:samadhan_app/admin/widgets/data_table_view.dart';
import 'package:samadhan_app/admin/widgets/dashboard_stats.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

enum AdminSection { dashboard, students, teachers, attendance, volunteers, volunteerReports, events, schedules }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminSection _currentSection = AdminSection.dashboard;
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDataProvider>(context, listen: false).loadAllData();
    });
  }

  String _getSectionTitle() {
    switch (_currentSection) {
      case AdminSection.dashboard: return 'Dashboard';
      case AdminSection.students: return 'Students';
      case AdminSection.teachers: return 'Teachers';
      case AdminSection.attendance: return 'Attendance';
      case AdminSection.volunteers: return 'Volunteers';
      case AdminSection.volunteerReports: return 'Volunteer Reports';
      case AdminSection.events: return 'Events';
      case AdminSection.schedules: return 'Schedules';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final auth = Provider.of<AdminAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: isWide ? null : IconButton(
          icon: const Icon(Icons.menu, color: SaralColors.foreground),
          onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
        ),
        title: Text(
          _getSectionTitle(),
          style: const TextStyle(
            color: SaralColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: SaralColors.primary),
            tooltip: 'Refresh Data',
            onPressed: () {
              Provider.of<AdminDataProvider>(context, listen: false).loadAllData();
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SaralColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 18, color: SaralColors.primary),
                const SizedBox(width: 8),
                Text(
                  auth.currentTeacher?.name ?? 'Admin',
                  style: const TextStyle(
                    color: SaralColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (isWide || _sidebarExpanded)
            AdminSidebar(
              currentSection: _currentSection,
              onSectionChanged: (section) {
                setState(() {
                  _currentSection = section;
                  if (!isWide) _sidebarExpanded = false;
                });
              },
              isExpanded: isWide || _sidebarExpanded,
            ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<AdminDataProvider>(
      builder: (context, dataProvider, _) {
        if (dataProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: SaralColors.primary),
                SizedBox(height: 16),
                Text('Loading data from Supabase...'),
              ],
            ),
          );
        }

        switch (_currentSection) {
          case AdminSection.dashboard:
            return DashboardStats(stats: dataProvider.stats);
          case AdminSection.students:
            return DataTableView(
              title: 'Students',
              tableName: 'students',
              data: dataProvider.students,
              columns: const ['id', 'name', 'roll_no', 'class_batch', 'center_name', 'created_at'],
              columnLabels: const {
                'id': 'ID',
                'name': 'Name',
                'roll_no': 'Roll No',
                'class_batch': 'Class',
                'center_name': 'Center',
                'created_at': 'Created',
              },
            );
          case AdminSection.teachers:
            return DataTableView(
              title: 'Teachers',
              tableName: 'teachers',
              data: dataProvider.teachers,
              columns: const ['id', 'name', 'email', 'phone_number', 'center_name', 'role', 'is_active'],
              columnLabels: const {
                'id': 'ID',
                'name': 'Name',
                'email': 'Email',
                'phone_number': 'Phone',
                'center_name': 'Center',
                'role': 'Role',
                'is_active': 'Active',
              },
            );
          case AdminSection.attendance:
            return DataTableView(
              title: 'Attendance',
              tableName: 'attendance',
              data: dataProvider.attendance,
              columns: const ['id', 'date', 'center_name', 'attendance'],
              columnLabels: const {
                'id': 'ID',
                'date': 'Date',
                'center_name': 'Center',
                'attendance': 'Records',
              },
            );
          case AdminSection.volunteers:
            return DataTableView(
              title: 'Volunteers',
              tableName: 'volunteers',
              data: dataProvider.volunteers,
              columns: const ['id', 'name', 'center_name', 'attendance_count', 'first_report_date', 'last_report_date'],
              columnLabels: const {
                'id': 'ID',
                'name': 'Name',
                'center_name': 'Center',
                'attendance_count': 'Sessions',
                'first_report_date': 'First Report',
                'last_report_date': 'Last Report',
              },
            );
          case AdminSection.volunteerReports:
            return DataTableView(
              title: 'Volunteer Reports',
              tableName: 'volunteer_reports',
              data: dataProvider.volunteerReports,
              columns: const ['id', 'volunteer_name', 'class_batch', 'center_name', 'activity_taught', 'in_time', 'out_time'],
              columnLabels: const {
                'id': 'ID',
                'volunteer_name': 'Volunteer',
                'class_batch': 'Class',
                'center_name': 'Center',
                'activity_taught': 'Activity',
                'in_time': 'In',
                'out_time': 'Out',
              },
            );
          case AdminSection.events:
            return DataTableView(
              title: 'Events',
              tableName: 'events',
              data: dataProvider.events,
              columns: const ['id', 'title', 'date', 'class_batch', 'center_name', 'attendance_summary'],
              columnLabels: const {
                'id': 'ID',
                'title': 'Title',
                'date': 'Date',
                'class_batch': 'Class',
                'center_name': 'Center',
                'attendance_summary': 'Attendance',
              },
            );
          case AdminSection.schedules:
            return DataTableView(
              title: 'Schedules',
              tableName: 'schedules',
              data: dataProvider.schedules,
              columns: const ['id', 'class_batch', 'date', 'time', 'topic', 'center_name'],
              columnLabels: const {
                'id': 'ID',
                'class_batch': 'Class',
                'date': 'Date',
                'time': 'Time',
                'topic': 'Topic',
                'center_name': 'Center',
              },
            );
        }
      },
    );
  }
}
