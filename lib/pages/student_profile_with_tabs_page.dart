import 'package:flutter/material.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/models/student_details.dart';
import 'package:samadhan_app/services/student_details_service.dart';
import 'package:samadhan_app/pages/student_enrollment_page_complete.dart';
import 'package:samadhan_app/pages/student_profile_analytics_page.dart';
import 'package:samadhan_app/pages/student_details_view_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentProfileWithTabsPage extends StatefulWidget {
  final Student student;

  const StudentProfileWithTabsPage({super.key, required this.student});

  @override
  State<StudentProfileWithTabsPage> createState() => _StudentProfileWithTabsPageState();
}

class _StudentProfileWithTabsPageState extends State<StudentProfileWithTabsPage> {
  int _currentIndex = 0; // Default to Progress tab (index 0)
  final StudentDetailsService _service = StudentDetailsService();
  StudentDetails? _enrollmentDetails;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollmentDetails();
  }

  Future<void> _loadEnrollmentDetails() async {
    try {
      _enrollmentDetails = await _service.getStudentDetails(widget.student.id);
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _navigateToEnrollmentPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEnrollmentPageComplete(
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
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Progress Tab (default view)
          StudentProfileAnalyticsPage(student: widget.student),
          
          // Student Details Tab
          StudentDetailsViewPage(
            studentId: widget.student.id,
            studentName: widget.student.name,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: SaralColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Details',
          ),
        ],
      ),
    );
  }
}