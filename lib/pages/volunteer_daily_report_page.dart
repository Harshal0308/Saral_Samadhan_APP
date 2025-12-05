import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/data/subjects_topics.dart'; // NEW: Subject → Topic data

class VolunteerDailyReportPage extends StatefulWidget {
  const VolunteerDailyReportPage({super.key});

  @override
  State<VolunteerDailyReportPage> createState() => _VolunteerDailyReportPageState();
}

class _VolunteerDailyReportPageState extends State<VolunteerDailyReportPage> {

  final _formKey = GlobalKey<FormState>();

  final _volunteerNameController = TextEditingController(); // Use a controller

  TimeOfDay? _inTime;

  TimeOfDay? _outTime;

  String? _selectedSubject; // NEW: Selected subject
  String? _selectedTopic; // NEW: Selected topic
  String? _customTopic; // NEW: Custom topic if not in list
  final _topicSearchController = TextEditingController(); // NEW: For topic search
  List<String> _filteredTopics = []; // NEW: Filtered topics based on search

  bool _testConducted = false;

  String? _testTopic;

  String? _marksGrade;

  List<int> _selectedStudents = []; // Changed to List<int>
  
  List<int> _testStudents = []; // Students who took the test
  
  Map<int, TextEditingController> _testMarksControllers = {}; // Controllers for each student's marks



  @override

  void initState() {

    super.initState();

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _volunteerNameController.text = userProvider.userSettings.name; // Set controller text

  }



  @override

  void dispose() {

    _volunteerNameController.dispose();
    _topicSearchController.dispose(); // NEW: Dispose topic search controller
    
    // Dispose all test marks controllers
    for (var controller in _testMarksControllers.values) {
      controller.dispose();
    }

    super.dispose();

  }
  
  // NEW: Filter topics based on search query
  void _filterTopics(String query) {
    if (_selectedSubject == null) return;
    
    setState(() {
      _filteredTopics = SubjectsTopics.searchTopics(_selectedSubject!, query);
    });
  }

  

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {

    final TimeOfDay? picked = await showTimePicker(

      context: context,

      initialTime: TimeOfDay.now(),

    );

    if (picked != null && picked != (isStartTime ? _inTime : _outTime)) {

      setState(() {

        if (isStartTime) {

          _inTime = picked;

        } else {

          _outTime = picked;

        }

      });

    }

  }



  void _showStudentSelectionSheet() async {

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';

    // Get only students from selected center
    final allStudents = studentProvider.getStudentsByCenter(selectedCenter);



    final List<int>? result = await showModalBottomSheet<List<int>>( // Changed to List<int>

      context: context,

      isScrollControlled: true,

      builder: (context) {

        return DraggableScrollableSheet(

          expand: false,

          initialChildSize: 0.8,

          maxChildSize: 0.9,

                    builder: (BuildContext context, ScrollController scrollController) {

                      return StudentSelectionSheet(

                        scrollController: scrollController,

                        allStudents: allStudents,

                        initiallySelectedStudents: _selectedStudents,

                      );

                    },

        );

      },

    );



    if (result != null) {

      setState(() {

        _selectedStudents = result;

      });

    }

  }

  void _showTestStudentSelectionSheet() async {

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    // Only show students from the same class as the selected students
    final testStudentCandidates = _selectedStudents.isNotEmpty
        ? studentProvider.students.where((s) => _selectedStudents.contains(s.id)).toList()
        : [];

    if (testStudentCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select students who attended first.')),
      );
      return;
    }

    final List<int>? result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return StudentSelectionSheet(
              scrollController: scrollController,
              allStudents: testStudentCandidates.cast<Student>(),
              initiallySelectedStudents: _testStudents,
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _testStudents = result;
        // Initialize controllers for selected test students
        _testMarksControllers.clear();
        for (int studentId in _testStudents) {
          _testMarksControllers[studentId] = TextEditingController();
        }
      });
    }
  }



  Future<void> _submitReport() async {

    if (_formKey.currentState!.validate()) {

      _formKey.currentState!.save();

      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      final studentProvider = Provider.of<StudentProvider>(context, listen: false);



      // Find the class batch of the first selected student

      String? classBatch;

      if (_selectedStudents.isNotEmpty) {

        final firstStudent = studentProvider.students.firstWhere((s) => s.id == _selectedStudents.first);

        classBatch = firstStudent.classBatch;

      }



      // Build testMarks Map from controllers
      final Map<int, String> testMarksMap = {};
      for (int studentId in _testStudents) {
        final controller = _testMarksControllers[studentId];
        if (controller != null) {
          testMarksMap[studentId] = controller.text;
        }
      }

      // Get selected center
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';

      final report = VolunteerReport(

        id: DateTime.now().millisecondsSinceEpoch,

        volunteerName: _volunteerNameController.text, // Use controller text

        selectedStudents: _selectedStudents,

        classBatch: classBatch ?? "Unknown", // Use the found class batch

        centerName: selectedCenter, // NEW: Include center

        inTime: _inTime!.format(context),

        outTime: _outTime!.format(context),

        activityTaught: '${_selectedSubject!}: ${_selectedTopic ?? _customTopic}', // NEW: Format as "Subject: Topic"

        testConducted: _testConducted,

        testTopic: _testTopic,

        marksGrade: _marksGrade,

        testStudents: _testStudents,

        testMarks: testMarksMap,

      );



      await volunteerProvider.addReport(report);

      // NEW: Save the subject and topic as a lesson learned to each selected student
      final lessonTaught = '${_selectedSubject!}: ${_selectedTopic ?? _customTopic}';
      
      print('📚 Updating student profiles with lesson: $lessonTaught');
      
      for (int studentId in _selectedStudents) {
        final studentIndex = studentProvider.students.indexWhere((s) => s.id == studentId);
        if (studentIndex != -1) {
          final student = studentProvider.students[studentIndex];
          // Add the lesson to the student's lessons learned if not already present
          if (!student.lessonsLearned.contains(lessonTaught)) {
            student.lessonsLearned.add(lessonTaught);
            await studentProvider.updateStudent(student);
            print('   ✅ Updated ${student.name} - Added: $lessonTaught');
          } else {
            print('   ⚠️ ${student.name} already has this lesson');
          }
        }
      }

      // Save test results to student profiles who took the test
      if (_testConducted && _testTopic != null) {
        for (int studentId in _testStudents) {
          final studentIndex = studentProvider.students.indexWhere((s) => s.id == studentId);
          if (studentIndex != -1) {
            final student = studentProvider.students[studentIndex];
            // Add test result to student's testResults map
            student.testResults[_testTopic!] = testMarksMap[studentId] ?? '';
            await studentProvider.updateStudent(student);
          }
        }
      }

      notificationProvider.addNotification(

        title: 'Volunteer Report Submitted',

        message: 'Daily report for ${_volunteerNameController.text} in ${classBatch ?? "Unknown"} submitted. Lesson: ${_selectedSubject!}: ${_selectedTopic ?? _customTopic}.',

        type: 'success',

      );

      // Sync to cloud if online
      final offlineProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
      if (offlineProvider.isOnline) {
        final cloudSync = CloudSyncService();
        await cloudSync.uploadVolunteerReport(report);
      }

      if(mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Volunteer report submitted successfully!')),

        );

        Navigator.pop(context);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Volunteer Daily Report'),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context); // Go back to Dashboard

          },

        ),

      ),

      body: Padding(

        padding: const EdgeInsets.all(16.0),

        child: Form(

          key: _formKey,

          child: ListView(

            children: [

              TextFormField(

                controller: _volunteerNameController, // Use controller

                decoration: InputDecoration(

                  labelText: 'Volunteer Name',

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                ),

                validator: (value) {

                  if (value == null || value.isEmpty) {

                    return 'Please enter a volunteer name';

                  }

                  return null;

                },

              ),

              const SizedBox(height: 16),

              ElevatedButton(

                onPressed: _showStudentSelectionSheet,

                child: Text('Select Students (${_selectedStudents.length})'),

              ),

              const SizedBox(height: 16),

              Row(

                children: [

                  Expanded(

                    child: GestureDetector(

                      onTap: () => _selectTime(context, true),

                      child: AbsorbPointer(

                        child: TextFormField(

                          controller: TextEditingController(text: _inTime?.format(context) ?? ''),

                          decoration: InputDecoration(

                            labelText: 'In Time',

                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                          ),

                          validator: (value) {

                            if (value == null || value.isEmpty) {

                              return 'Please select in time';

                            }

                            return null;

                          },

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: GestureDetector(

                      onTap: () => _selectTime(context, false),

                      child: AbsorbPointer(

                        child: TextFormField(

                          controller: TextEditingController(text: _outTime?.format(context) ?? ''),

                          decoration: InputDecoration(

                            labelText: 'Out Time',

                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                          ),

                          validator: (value) {

                            if (value == null || value.isEmpty) {

                              return 'Please select out time';

                            }

                            return null;

                          },

                        ),

                      ),

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 16),

              // NEW: Subject Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.book),
                ),
                value: _selectedSubject,
                items: SubjectsTopics.subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                    _selectedTopic = null; // Reset topic when subject changes
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

              // NEW: Topic Searchable Dropdown
              if (_selectedSubject != null) ...[
                TextFormField(
                  controller: _topicSearchController,
                  decoration: InputDecoration(
                    labelText: 'Search Topic',
                    hintText: 'Type to search topics...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _topicSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _topicSearchController.clear();
                              _filterTopics('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterTopics,
                ),
                const SizedBox(height: 8),
                
                // Topic selection chips
                if (_filteredTopics.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _filteredTopics.length,
                      itemBuilder: (context, index) {
                        final topic = _filteredTopics[index];
                        final isSelected = _selectedTopic == topic;
                        return ListTile(
                          title: Text(topic),
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          leading: Radio<String>(
                            value: topic,
                            groupValue: _selectedTopic,
                            onChanged: (value) {
                              setState(() {
                                _selectedTopic = value;
                                _customTopic = null; // Clear custom topic if selecting from list
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTopic = topic;
                              _customTopic = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Custom topic option
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Or Add Custom Topic',
                          hintText: 'e.g., Profit and Loss - Introduction',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customTopic = value;
                            if (value.isNotEmpty) {
                              _selectedTopic = null; // Clear selected topic if typing custom
                            }
                          });
                        },
                        validator: (value) {
                          if (_selectedTopic == null && (value == null || value.isEmpty)) {
                            return 'Please select a topic or add a custom one';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              SwitchListTile(

                title: const Text('Test Conducted'),

                value: _testConducted,

                onChanged: (bool value) {

                  setState(() {

                    _testConducted = value;

                  });

                },

              ),

              if (_testConducted) ...[

                const SizedBox(height: 16),

                TextFormField(

                  decoration: InputDecoration(

                    labelText: 'Test Topic',

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                  ),

                  onSaved: (value) => _testTopic = value,

                  validator: (value) {

                    if (_testConducted && (value == null || value.isEmpty)) {

                      return 'Please enter test topic';

                    }

                    return null;

                  },

                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(

                  onPressed: _showTestStudentSelectionSheet,

                  icon: const Icon(Icons.people),

                  label: Text('Select Students Who Took Test (${_testStudents.length})'),

                  style: ElevatedButton.styleFrom(

                    minimumSize: const Size(double.infinity, 50),

                  ),

                ),

                if (_testStudents.isNotEmpty) ...[

                  const SizedBox(height: 16),

                  const Text('Enter Marks/Grade for Each Student:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 10),

                  ..._testStudents.map((studentId) {

                    final student = Provider.of<StudentProvider>(context, listen: false).students.firstWhere((s) => s.id == studentId);

                    return Padding(

                      padding: const EdgeInsets.only(bottom: 12),

                      child: Row(

                        children: [

                          Expanded(

                            flex: 2,

                            child: Text(student.name, style: const TextStyle(fontSize: 14)),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            flex: 1,

                            child: TextField(

                              controller: _testMarksControllers[studentId],

                              decoration: InputDecoration(

                                labelText: 'Marks',

                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

                              ),

                            ),

                          ),

                        ],

                      ),

                    );

                  }).toList(),

                ],

              ],

              const SizedBox(height: 24),

              ElevatedButton(

                onPressed: _submitReport,

                style: ElevatedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(vertical: 16),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(12),

                  ),

                ),

                child: const Text('Submit', style: TextStyle(fontSize: 18)),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class StudentSelectionSheet extends StatefulWidget {



  final ScrollController scrollController;



  final List<Student> allStudents;



  final List<int> initiallySelectedStudents;







  const StudentSelectionSheet({



    required this.scrollController,



    required this.allStudents,



    required this.initiallySelectedStudents,



  });







  @override



  State<StudentSelectionSheet> createState() => StudentSelectionSheetState();



}







class StudentSelectionSheetState extends State<StudentSelectionSheet> {

  late final Map<String, List<Student>> _groupedStudents;

  late final Set<int> _selectedStudents; // Changed to Set<int>

  String? _expandedClass;



  @override

  void initState() {

    super.initState();

    _selectedStudents = Set<int>.from(widget.initiallySelectedStudents); // Changed to Set<int>

    _groupedStudents = {};

    for (var student in widget.allStudents) {

      (_groupedStudents[student.classBatch] ??= []).add(student);

    }

  }



  void _onSelectAll(String classBatch, bool? isSelected) {

    final studentsInClass = _groupedStudents[classBatch]!.map((s) => s.id).toList();

    setState(() {

      _selectedStudents.clear();

      if (isSelected == true) {

        _selectedStudents.addAll(studentsInClass);

      }

    });

  }



  void _onStudentSelected(int studentId, bool? isSelected) { // Changed to studentId

    // Find the class of the student being selected.

    final studentClass = _groupedStudents.entries

        .firstWhere((entry) => entry.value.any((s) => s.id == studentId))

        .key;

        

    setState(() {

      // Check if there are existing selections from a different class.

      if (_selectedStudents.isNotEmpty) {

        final firstSelectedStudentId = _selectedStudents.first;

        final firstSelectedStudentClass = _groupedStudents.entries

            .firstWhere((entry) => entry.value.any((s) => s.id == firstSelectedStudentId))

            .key;

        

        if (studentClass != firstSelectedStudentClass) {

          // If the class is different, clear the old selections.

          _selectedStudents.clear();

        }

      }



      // Add or remove the current student.

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

        Padding(

          padding: const EdgeInsets.all(16.0),

          child: Text('Select Students', style: Theme.of(context).textTheme.titleLarge),

        ),

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

        Padding(

          padding: const EdgeInsets.all(16.0),

          child: ElevatedButton(

            onPressed: () {

              Navigator.of(context).pop(_selectedStudents.toList());

            },

            child: const Text('Done'),

          ),

        ),

      ],

    );

  }

}
