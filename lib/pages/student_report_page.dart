import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/pages/edit_student_page.dart';
import 'package:samadhan_app/pages/student_detailed_report_page.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentReportPage extends StatefulWidget {
  const StudentReportPage({super.key});

  @override
  State<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends State<StudentReportPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilterClassBatch;
  bool _isSelectionMode = false;
  List<int> _selectedStudentIds = [];

  List<Student> _getFilteredStudents(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // Get only students from selected center
    List<Student> students = studentProvider.getStudentsByCenter(selectedCenter);
    
    return students.where((student) {
      final matchesSearch = student.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilterClassBatch == null || _selectedFilterClassBatch == 'All' || student.classBatch == _selectedFilterClassBatch;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _toggleSelection(int studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
      if (_selectedStudentIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int studentId) {
    setState(() {
      _isSelectionMode = true;
      _selectedStudentIds.add(studentId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });
  }

  Future<void> _deleteSelectedStudents() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteStudent),
          content: Text('${l10n.areYouSureYouWantToDelete} ${_selectedStudentIds.length} student(s)?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      await studentProvider.deleteMultipleStudents(_selectedStudentIds);
      notificationProvider.addNotification(
        title: 'Students Deleted',
        message: '${_selectedStudentIds.length} student(s) have been successfully deleted.',
        type: 'info',
      );
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // Get class batches only from selected center
    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    final allClassBatches = ['All', ...centerStudents.map((s) => s.classBatch)].toSet().toList();
    final l10n = AppLocalizations.of(context)!;
    final _filteredStudents = _getFilteredStudents(context);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              backgroundColor: SaralColors.primary,
              title: Text('${_selectedStudentIds.length} selected', style: SaralTextStyles.title.copyWith(color: Colors.white)),
            )
          : AppBar(
              backgroundColor: SaralColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(l10n.studentReport, style: SaralTextStyles.title.copyWith(color: Colors.white)),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchStudents,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: SaralColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SaralRadius.radius),
                  borderSide: BorderSide(color: SaralColors.border),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n.filterByClassBatch,
                filled: true,
                fillColor: SaralColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SaralRadius.radius),
                  borderSide: BorderSide(color: SaralColors.border),
                ),
              ),
              value: _selectedFilterClassBatch ?? 'All',
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilterClassBatch = newValue;
                });
              },
              items: allClassBatches.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(child: Text(l10n.noStudentsFound ?? 'No such student'))
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = _selectedStudentIds.contains(student.id);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Material(
                          color: isSelected ? SaralColors.accent.withOpacity(0.6) : Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(student.id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailedReportPage(student: student),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _enterSelectionMode(student.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  _isSelectionMode
                                      ? Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? SaralColors.primary : Colors.grey)
                                      : CircleAvatar(
                                          radius: 22,
                                          backgroundColor: SaralColors.primary,
                                          child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(student.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Roll No: ${student.rollNo}, Class: ${student.classBatch}', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  if (!_isSelectionMode)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditStudentPage(student: student),
                                              ),
                                            ).then((_) => setState(() {}));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteConfirmation(student.id),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
              onPressed: _deleteSelectedStudents,
              child: const Icon(Icons.delete),
              backgroundColor: SaralColors.destructive,
            )
          : null,
    );
  }

  Future<void> _showDeleteConfirmation(int studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final student = studentProvider.students.firstWhere((s) => s.id == studentId);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteStudent),
          content: Text('${l10n.areYouSureYouWantToDelete} ${student.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await Provider.of<StudentProvider>(context, listen: false).deleteStudent(student.id);
      Provider.of<NotificationProvider>(context, listen: false).addNotification(
        title: 'Student Deleted',
        message: 'Student ${student.name} has been successfully deleted.',
        type: 'info',
      );
      if (mounted) {
        setState(() {});
      }
    }
  }
}