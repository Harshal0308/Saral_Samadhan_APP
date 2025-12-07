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

  List<int> _selectedStudents = []; // Changed to List<int>



  @override

  void initState() {

    super.initState();

    // Leave volunteer name empty for manual entry

  }



  @override

  void dispose() {

    _volunteerNameController.dispose();
    _topicSearchController.dispose(); // NEW: Dispose topic search controller

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



      // Get selected center
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';

      final report = VolunteerReport(

        id: DateTime.now().millisecondsSinceEpoch,

        volunteerName: _volunteerNameController.text, // Use controller text

        selectedStudents: _selectedStudents,

        classBatch: classBatch ?? "Unknown", // Use the found class batch

        centerName: selectedCenter, // NEW: Include center

        inTime: _inTime?.format(context) ?? 'Not set',

        outTime: _outTime?.format(context) ?? 'Not set',

        activityTaught: _selectedSubject != null 
          ? '${_selectedSubject!}: ${_selectedTopic ?? _customTopic ?? _topicSearchController.text}' 
          : 'No subject selected', // NEW: Format as "Subject: Topic"

        testConducted: false,

        testTopic: null,

        marksGrade: null,

        testStudents: [],

        testMarks: {},

      );



      await volunteerProvider.addReport(report);

      // NEW: Save the subject and topic as a lesson learned to each selected student
      final lessonTaught = '${_selectedSubject ?? "Unknown"}: ${_selectedTopic ?? _customTopic ?? _topicSearchController.text}';
      
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



      notificationProvider.addNotification(

        title: 'Volunteer Report Submitted',

        message: 'Daily report for ${_volunteerNameController.text} in ${classBatch ?? "Unknown"} submitted. Lesson: ${_selectedSubject ?? "Unknown"}: ${_selectedTopic ?? _customTopic ?? _topicSearchController.text}.',

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

      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),

          onPressed: () => Navigator.pop(context),

        ),

        title: const Text(

          'Volunteer Daily Report',

          style: TextStyle(

            color: Color(0xFF2C3E50),

            fontSize: 20,

            fontWeight: FontWeight.w600,

          ),

        ),

      ),

      body: Form(

        key: _formKey,

        child: ListView(

          padding: const EdgeInsets.all(20),

          children: [

            // Volunteer Name Section
            _buildSectionLabel('Volunteer Name *'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volunteerNameController,
              decoration: InputDecoration(
                hintText: 'Enter volunteer name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF6B7280)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter volunteer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Students Selection Section

            _buildSectionLabel('Choose Students *'),

            const SizedBox(height: 12),

            Wrap(

              spacing: 8,

              runSpacing: 8,

              children: _selectedStudents.map((studentId) {

                final student = Provider.of<StudentProvider>(context, listen: false).students.firstWhere((s) => s.id == studentId);

                return Chip(

                  label: Text(student.name),

                  backgroundColor: const Color(0xFFEDE9FE),

                  labelStyle: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w500),

                  deleteIcon: const Icon(Icons.close, size: 18, color: Color(0xFF8B5CF6)),

                  onDeleted: () {

                    setState(() {

                      _selectedStudents.remove(studentId);

                    });

                  },

                );

              }).toList(),

            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(

              onPressed: _showStudentSelectionSheet,

              icon: const Icon(Icons.add, size: 20),

              label: Text(_selectedStudents.isEmpty ? 'Select Students' : 'Add More Students'),

              style: OutlinedButton.styleFrom(

                foregroundColor: const Color(0xFF8B5CF6),

                side: const BorderSide(color: Color(0xFFDDD6FE)),

                padding: const EdgeInsets.symmetric(vertical: 14),

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),

            ),

            const SizedBox(height: 24),

            // Time Selection

            Row(

              children: [

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _buildSectionLabel('In Time *'),

                      const SizedBox(height: 8),

                      GestureDetector(

                        onTap: () => _selectTime(context, true),

                        child: Container(

                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                          decoration: BoxDecoration(

                            color: Colors.white,

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: const Color(0xFFE5E7EB)),

                          ),

                          child: Row(

                            children: [

                              Text(

                                _inTime?.format(context) ?? '10:00 AM',

                                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),

                              ),

                              const Spacer(),

                              const Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 20),

                            ],

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

                const SizedBox(width: 16),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _buildSectionLabel('Out Time *'),

                      const SizedBox(height: 8),

                      GestureDetector(

                        onTap: () => _selectTime(context, false),

                        child: Container(

                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                          decoration: BoxDecoration(

                            color: Colors.white,

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: const Color(0xFFE5E7EB)),

                          ),

                          child: Row(

                            children: [

                              Text(

                                _outTime?.format(context) ?? '12:30 PM',

                                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),

                              ),

                              const Spacer(),

                              const Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 20),

                            ],

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            const SizedBox(height: 24),

            // Activity Taught Section

            _buildSectionLabel('Activity Taught *'),

            const SizedBox(height: 12),

            // Subject Dropdown

            DropdownButtonFormField<String>(

              decoration: InputDecoration(

                hintText: 'Select Subject',

                filled: true,

                fillColor: Colors.white,

                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(12),

                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),

                ),

                enabledBorder: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(12),

                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),

                ),

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

                  _selectedTopic = null;

                  _customTopic = null;

                  _topicSearchController.clear();

                  // Load all topics for the selected subject initially

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

            if (_selectedSubject != null) ...[

              const SizedBox(height: 12),

              // Topic Search

              TextFormField(

                controller: _topicSearchController,

                decoration: InputDecoration(

                  hintText: 'Search or type topic...',

                  helperText: 'Start typing to search, or select from suggestions below',

                  helperStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),

                  filled: true,

                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),

                  ),

                  enabledBorder: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),

                  ),

                  focusedBorder: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),

                  ),

                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),

                  suffixIcon: _topicSearchController.text.isNotEmpty

                    ? IconButton(

                        icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),

                        onPressed: () {

                          setState(() {

                            _topicSearchController.clear();

                            _customTopic = null;

                            _selectedTopic = null;

                            _filteredTopics = SubjectsTopics.getTopicsForSubject(_selectedSubject!);

                          });

                        },

                      )

                    : null,

                ),

                onChanged: (value) {

                  _filterTopics(value);

                  setState(() {

                    _customTopic = value;

                    if (value.isNotEmpty) {

                      _selectedTopic = null;

                    }

                  });

                },

                validator: (value) {

                  if (_selectedTopic == null && (value == null || value.isEmpty)) {

                    return 'Please enter or select a topic';

                  }

                  return null;

                },

              ),

              // Show suggestions when there are filtered topics

              if (_filteredTopics.isNotEmpty) ...[

                const SizedBox(height: 8),

                Container(

                  constraints: const BoxConstraints(maxHeight: 200),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFFE5E7EB)),

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

                      Padding(

                        padding: const EdgeInsets.all(12),

                        child: Text(

                          _topicSearchController.text.isEmpty 

                            ? 'All Topics (${_filteredTopics.length})' 

                            : 'Matching Topics (${_filteredTopics.length})',

                          style: const TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w600,

                            color: Color(0xFF6B7280),

                          ),

                        ),

                      ),

                      const Divider(height: 1),

                      Expanded(

                        child: ListView.builder(

                          shrinkWrap: true,

                          itemCount: _filteredTopics.length,

                          itemBuilder: (context, index) {

                            final topic = _filteredTopics[index];

                            final isSelected = _selectedTopic == topic;

                            return ListTile(

                              dense: true,

                              title: Text(

                                topic,

                                style: TextStyle(

                                  fontSize: 14,

                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,

                                  color: isSelected ? const Color(0xFF3B82F6) : Colors.black87,

                                ),

                              ),

                              trailing: isSelected 

                                ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 20)

                                : null,

                              tileColor: isSelected ? const Color(0xFFEFF6FF) : null,

                              onTap: () {

                                setState(() {

                                  _selectedTopic = topic;

                                  _topicSearchController.text = topic;

                                  _customTopic = null;

                                  _filteredTopics = []; // Hide suggestions after selection

                                });

                              },

                            );

                          },

                        ),

                      ),

                    ],

                  ),

                ),

              ],

              

              // Show "No matches" message and custom topic option

              // Only show this when user is typing AND no topic is selected AND no matches found

              if (_topicSearchController.text.isNotEmpty && 

                  _selectedTopic == null && 

                  _filteredTopics.isEmpty) ...[

                const SizedBox(height: 8),

                Container(

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    color: const Color(0xFFFEF3C7),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFFFBBF24)),

                  ),

                  child: Row(

                    children: [

                      const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            const Text(

                              'No matching topics found',

                              style: TextStyle(

                                fontWeight: FontWeight.w600,

                                color: Color(0xFF92400E),

                              ),

                            ),

                            const SizedBox(height: 4),

                            Text(

                              'Your custom topic "${_topicSearchController.text}" will be used',

                              style: const TextStyle(

                                fontSize: 13,

                                color: Color(0xFF92400E),

                              ),

                            ),

                          ],

                        ),

                      ),

                    ],

                  ),

                ),

              ],

              

              // Show selected topic confirmation

              if (_selectedTopic != null) ...[

                const SizedBox(height: 8),

                Container(

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color: const Color(0xFFEFF6FF),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFF3B82F6)),

                  ),

                  child: Row(

                    children: [

                      const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 20),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Text(

                          'Selected: $_selectedTopic',

                          style: const TextStyle(

                            fontWeight: FontWeight.w600,

                            color: Color(0xFF1E40AF),

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ],

            const SizedBox(height: 32),

            // Submit Button

            ElevatedButton(

              onPressed: _submitReport,

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFF8B5CF6),

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(vertical: 16),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                ),

                elevation: 0,

              ),

              child: const Text('Submit Daily Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),

            ),

            const SizedBox(height: 20),

          ],

        ),

      ),

    );

  }



  Widget _buildSectionLabel(String label) {

    return Text(

      label,

      style: const TextStyle(

        fontSize: 14,

        fontWeight: FontWeight.w600,

        color: Color(0xFF6B7280),

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
