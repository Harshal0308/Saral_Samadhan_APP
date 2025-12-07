import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/data/subjects_topics.dart';

class VolunteerTestReportPage extends StatefulWidget {
  const VolunteerTestReportPage({super.key});

  @override
  State<VolunteerTestReportPage> createState() => _VolunteerTestReportPageState();
}

class _VolunteerTestReportPageState extends State<VolunteerTestReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _volunteerNameController = TextEditingController();
  final _topicSearchController = TextEditingController();
  final _maxMarksController = TextEditingController();
  
  String? _selectedSubject;
  String? _selectedTopic;
  String? _customTopic;
  List<String> _filteredTopics = [];
  
  List<int> _testStudents = [];
  Map<int, TextEditingController> _testMarksControllers = {};
  double? _maxMarks;
  
  @override
  void dispose() {
    _volunteerNameController.dispose();
    _topicSearchController.dispose();
    _maxMarksController.dispose();
    for (var controller in _testMarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _filterTopics(String query) {
    if (_selectedSubject == null) return;
    setState(() {
      _filteredTopics = SubjectsTopics.searchTopics(_selectedSubject!, query);
    });
  }

  Future<void> _submitTestReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_testStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Get selected center
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // Get class batch from first selected student
    final firstStudent = studentProvider.students.firstWhere((s) => s.id == _testStudents.first);
    final classBatch = firstStudent.classBatch;

    // Format test topic as "Subject: Topic"
    final testTopic = _selectedSubject != null && _selectedTopic != null
        ? '$_selectedSubject: $_selectedTopic'
        : _customTopic ?? 'Unknown Topic';

    // Collect test marks
    Map<int, String> testMarks = {};
    for (int studentId in _testStudents) {
      final controller = _testMarksControllers[studentId];
      if (controller != null && controller.text.isNotEmpty) {
        // Format as "obtained/max"
        testMarks[studentId] = '${controller.text}/${_maxMarks!.toInt()}';
      }
    }

    // Create volunteer report (test-only report)
    final report = VolunteerReport(
      id: DateTime.now().millisecondsSinceEpoch,
      volunteerName: _volunteerNameController.text,
      selectedStudents: _testStudents,
      classBatch: classBatch,
      centerName: selectedCenter,
      inTime: TimeOfDay.now().format(context),
      outTime: TimeOfDay.now().format(context),
      activityTaught: 'Test Conducted: $testTopic',
      testConducted: true,
      testTopic: testTopic,
      marksGrade: '${testMarks.length} students tested',
      testStudents: _testStudents,
      testMarks: testMarks,
    );

    await volunteerProvider.addReport(report);

    // Update student profiles with test results
    for (int studentId in _testStudents) {
      final studentIndex = studentProvider.students.indexWhere((s) => s.id == studentId);
      if (studentIndex != -1) {
        final student = studentProvider.students[studentIndex];
        student.testResults[testTopic] = testMarks[studentId] ?? '';
        await studentProvider.updateStudent(student);
      }
    }

    await notificationProvider.addNotification(
      title: 'Test Report Submitted',
      message: 'Test report for $testTopic submitted successfully',
      type: 'success',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);

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
          'Submit Test Report',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                    const Icon(Icons.assignment, color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record test results for students',
                        style: TextStyle(color: const Color(0xFF6B7280), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Volunteer Name
              _buildSectionCard(
                title: 'Volunteer Information',
                child: TextFormField(
                  controller: _volunteerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Volunteer Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter volunteer name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Subject Selection
              _buildSectionCard(
                title: 'Test Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Select subject',
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: SubjectsTopics.subjects.map((subject) {
                        return DropdownMenuItem(value: subject, child: Text(subject));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                          _selectedTopic = null;
                          _customTopic = null;
                          _topicSearchController.clear();
                          _filteredTopics = SubjectsTopics.getTopicsForSubject(value!);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Topic Selection with Search
                    if (_selectedSubject != null) ...[
                      TextField(
                        controller: _topicSearchController,
                        decoration: InputDecoration(
                          labelText: 'Search Topic',
                          hintText: 'Type to search or enter custom topic',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _topicSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _topicSearchController.clear();
                                    setState(() {
                                      _filteredTopics = SubjectsTopics.getTopicsForSubject(_selectedSubject!);
                                      _selectedTopic = null;
                                      _customTopic = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _filteredTopics = SubjectsTopics.getTopicsForSubject(_selectedSubject!);
                              _customTopic = null;
                              _selectedTopic = null;
                            });
                          } else {
                            _filterTopics(value);
                            setState(() {
                              _customTopic = value;
                              _selectedTopic = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Topic Suggestions
                      if (_filteredTopics.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredTopics.length,
                            itemBuilder: (context, index) {
                              final topic = _filteredTopics[index];
                              return ListTile(
                                title: Text(topic),
                                onTap: () {
                                  setState(() {
                                    _selectedTopic = topic;
                                    _customTopic = null;
                                    _topicSearchController.text = topic;
                                    _filteredTopics = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),

                    // Maximum Marks
                    TextFormField(
                      controller: _maxMarksController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Marks',
                        hintText: 'Enter maximum marks (e.g., 10, 20, 100)',
                        prefixIcon: Icon(Icons.grade),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter maximum marks';
                        }
                        final marks = double.tryParse(value);
                        if (marks == null || marks <= 0) {
                          return 'Please enter valid marks';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _maxMarks = double.tryParse(value);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Student Selection
              _buildSectionCard(
                title: 'Select Students',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showStudentSelectionSheet(context, centerStudents),
                      icon: const Icon(Icons.group_add),
                      label: Text('Select Students (${_testStudents.length} selected)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (_testStudents.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _testStudents.map((studentId) {
                          final student = centerStudents.firstWhere((s) => s.id == studentId);
                          return Chip(
                            label: Text(student.name),
                            onDeleted: () {
                              setState(() {
                                _testStudents.remove(studentId);
                                _testMarksControllers[studentId]?.dispose();
                                _testMarksControllers.remove(studentId);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Marks Entry
              if (_testStudents.isNotEmpty && _maxMarks != null) ...[
                _buildSectionCard(
                  title: 'Enter Marks',
                  child: Column(
                    children: _testStudents.map((studentId) {
                      final student = centerStudents.firstWhere((s) => s.id == studentId);
                      
                      // Create controller if not exists
                      if (!_testMarksControllers.containsKey(studentId)) {
                        _testMarksControllers[studentId] = TextEditingController();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _testMarksControllers[studentId],
                          decoration: InputDecoration(
                            labelText: student.name,
                            hintText: 'Enter marks (max: ${_maxMarks!.toInt()})',
                            prefixIcon: const Icon(Icons.edit),
                            suffixText: '/ ${_maxMarks!.toInt()}',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter marks for ${student.name}';
                            }
                            final marks = double.tryParse(value);
                            if (marks == null) {
                              return 'Please enter valid marks';
                            }
                            if (marks > _maxMarks!) {
                              return 'Marks cannot exceed ${_maxMarks!.toInt()}';
                            }
                            if (marks < 0) {
                              return 'Marks cannot be negative';
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitTestReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Test Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showStudentSelectionSheet(BuildContext context, List<Student> students) async {
    final List<int>? result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StudentSelectionSheet(
              scrollController: scrollController,
              allStudents: students,
              initiallySelectedStudents: _testStudents,
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _testStudents = result;
      });
    }
  }
}


// Student Selection Sheet with Class-wise Grouping
class StudentSelectionSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<Student> allStudents;
  final List<int> initiallySelectedStudents;

  const StudentSelectionSheet({
    super.key,
    required this.scrollController,
    required this.allStudents,
    required this.initiallySelectedStudents,
  });

  @override
  State<StudentSelectionSheet> createState() => StudentSelectionSheetState();
}

class StudentSelectionSheetState extends State<StudentSelectionSheet> {
  late final Map<String, List<Student>> _groupedStudents;
  late final Set<int> _selectedStudents;
  String? _expandedClass;

  @override
  void initState() {
    super.initState();
    _selectedStudents = Set<int>.from(widget.initiallySelectedStudents);
    _groupedStudents = {};
    for (var student in widget.allStudents) {
      (_groupedStudents[student.classBatch] ??= []).add(student);
    }
  }

  void _onSelectAll(String classBatch, bool? isSelected) {
    final studentsInClass = _groupedStudents[classBatch]!.map((s) => s.id).toList();
    setState(() {
      if (isSelected == true) {
        // Add all students from this class
        _selectedStudents.addAll(studentsInClass);
      } else {
        // Remove all students from this class
        _selectedStudents.removeAll(studentsInClass);
      }
    });
  }

  void _onStudentSelected(int studentId, bool? isSelected) {
    setState(() {
      // Add or remove the current student (allow multiple classes)
      if (isSelected == true) {
        _selectedStudents.add(studentId);
      } else {
        _selectedStudents.remove(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classBatches = _groupedStudents.keys.toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text(
                'Select Students',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, _selectedStudents.toList());
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        // Class-wise Student List
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            children: [
              ExpansionPanelList(
                expansionCallback: (int panelIndex, bool isExpanded) {
                  setState(() {
                    _expandedClass = isExpanded ? classBatches[panelIndex] : null;
                  });
                },
                children: classBatches.map<ExpansionPanel>((String classBatch) {
                  final studentsInClass = _groupedStudents[classBatch]!;
                  final areAllSelected = studentsInClass.every((s) => _selectedStudents.contains(s.id));

                  return ExpansionPanel(
                    isExpanded: _expandedClass == classBatch,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text('Class $classBatch'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Select All'),
                            Checkbox(
                              value: areAllSelected,
                              onChanged: (bool? value) {
                                _onSelectAll(classBatch, value);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    body: Column(
                      children: studentsInClass.map((Student student) {
                        return CheckboxListTile(
                          title: Text(student.name),
                          subtitle: Text('Roll No: ${student.rollNo}'),
                          value: _selectedStudents.contains(student.id),
                          onChanged: (bool? value) {
                            _onStudentSelected(student.id, value);
                          },
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
