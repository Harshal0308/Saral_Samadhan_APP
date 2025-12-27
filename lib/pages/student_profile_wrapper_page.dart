import 'package:flutter/material.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/pages/student_detailed_report_page.dart';
import 'package:samadhan_app/pages/student_details_view_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentProfileWrapperPage extends StatefulWidget {
  final Student student;

  const StudentProfileWrapperPage({super.key, required this.student});

  @override
  State<StudentProfileWrapperPage> createState() => _StudentProfileWrapperPageState();
}

class _StudentProfileWrapperPageState extends State<StudentProfileWrapperPage> {
  int _currentIndex = 0; // Default to Progress tab (index 0)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Progress Tab (existing detailed report page)
          StudentDetailedReportPage(student: widget.student),
          
          // Student Details Tab (enrollment information)
          Scaffold(
            appBar: AppBar(
              title: Text('${widget.student.name} - Details'),
              backgroundColor: SaralColors.primary,
            ),
            body: StudentDetailsViewPage(
              studentId: widget.student.id,
              studentName: widget.student.name,
            ),
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