import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/widgets/topic_progress_widget.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class TopicTrackingPage extends StatefulWidget {
  const TopicTrackingPage({super.key});

  @override
  State<TopicTrackingPage> createState() => _TopicTrackingPageState();
}

class _TopicTrackingPageState extends State<TopicTrackingPage> {
  String? _selectedCenter;
  String? _selectedClass;
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    _selectedCenter = userProvider.userSettings.selectedCenter;
    if (_selectedCenter != null) {
      _filterStudents();
    }
  }

  void _filterStudents() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    setState(() {
      _filteredStudents = studentProvider.students.where((student) {
        bool matchesCenter = _selectedCenter == null || student.centerName == _selectedCenter;
        bool matchesClass = _selectedClass == null || student.classBatch == _selectedClass;
        return matchesCenter && matchesClass;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentProvider, UserProvider>(
      builder: (context, studentProvider, userProvider, child) {
        final centers = studentProvider.getAllCenters();
        final classes = _selectedCenter != null 
            ? studentProvider.getClassBatchesByCenter(_selectedCenter!)
            : <String>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Topic Progress Tracking'),
            backgroundColor: SaralColors.primary,
          ),
          body: Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Center',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _selectedCenter,
                            items: centers.map((center) {
                              return DropdownMenuItem(
                                value: center,
                                child: Text(
                                  center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCenter = value;
                                _selectedClass = null; // Reset class when center changes
                              });
                              _filterStudents();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Class (Optional)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _selectedClass,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Classes'),
                              ),
                              ...classes.map((classBatch) {
                                return DropdownMenuItem(
                                  value: classBatch,
                                  child: Text(
                                    'Class $classBatch',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedClass = value;
                              });
                              _filterStudents();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Found ${_filteredStudents.length} students. Track: ❌ Not Started, ⚠️ Needs Revision, ✔️ Understood',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _filteredStudents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select a center to view students',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: TopicProgressWidget(
                          students: _filteredStudents,
                          volunteerName: userProvider.userSettings.name.isNotEmpty ? userProvider.userSettings.name : 'Unknown',
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}