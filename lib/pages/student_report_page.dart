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
      backgroundColor: const Color(0xFFF5F5F5),
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
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.studentReport,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search student name or roll no...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Class Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allClassBatches.map((classBatch) {
                  final isSelected = (_selectedFilterClassBatch ?? 'All') == classBatch;
                  final isAllClasses = classBatch == 'All';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAllClasses && isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.filter_list, size: 16, color: Colors.white),
                            ),
                          Text(
                            isAllClasses ? 'All Classes' : 'Class $classBatch',
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilterClassBatch = classBatch;
                        });
                      },
                      backgroundColor: const Color(0xFFF3F4F6),
                      selectedColor: const Color(0xFF8B5CF6),
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Student List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      l10n.noStudentsFound ?? 'No such student',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = _selectedStudentIds.contains(student.id);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? SaralColors.accent.withOpacity(0.6) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar or Selection Icon
                                _isSelectionMode
                                    ? Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isSelected ? SaralColors.primary : Colors.grey,
                                        size: 28,
                                      )
                                    : CircleAvatar(
                                        radius: 28,
                                        backgroundColor: const Color(0xFF8B5CF6),
                                        child: Text(
                                          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                const SizedBox(width: 16),
                                // Student Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Roll ${student.rollNo} • ${student.classBatch}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Action Buttons or Arrow
                                if (!_isSelectionMode)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
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
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                        onPressed: () => _showDeleteConfirmation(student.id),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                                    ],
                                  ),
                              ],
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
              backgroundColor: SaralColors.destructive,
              child: const Icon(Icons.delete),
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