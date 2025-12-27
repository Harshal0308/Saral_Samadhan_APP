import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/student_details_provider.dart';
import 'package:samadhan_app/models/student_details.dart';
import 'package:samadhan_app/pages/student_enrollment_page.dart';
import 'package:samadhan_app/pages/student_profile_analytics_page.dart';
import 'package:samadhan_app/pages/student_details_view_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentProfileWithTabsPage extends StatefulWidget {
  final Student student;

  const StudentProfileWithTabsPage({super.key, required this.student});

  @override
  State<StudentProfileWithTabsPage> createState() => _StudentProfileWithTabsPageState();
}

class _StudentProfileWithTabsPageState extends State<StudentProfileWithTabsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StudentDetails? _enrollmentDetails;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrollmentDetails();
  }

  Future<void> _loadEnrollmentDetails() async {
    final provider = context.read<StudentDetailsProvider>();
    await provider.loadStudentDetails(widget.student.id);
    setState(() {
      _enrollmentDetails = provider.currentStudentDetails;
      _isLoadingDetails = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEnrollmentPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEnrollmentPage(
          studentId: widget.student.id,
          studentName: widget.student.name,
        ),
      ),
    );
    
    if (result == true) {
      _loadEnrollmentDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        backgroundColor: SaralColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Student Details', icon: Icon(Icons.person_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Progress Tab (existing analytics page)
          StudentProfileAnalyticsPage(student: widget.student),
          
          // Student Details Tab
          StudentDetailsViewPage(
            studentId: widget.student.id,
            studentName: widget.student.name,
          ),
        ],
      ),
    );
  }
}