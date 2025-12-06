import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/pages/edit_volunteer_report_page.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';

class VolunteerReportsListPage extends StatefulWidget {
  const VolunteerReportsListPage({super.key});

  @override
  State<VolunteerReportsListPage> createState() => _VolunteerReportsListPageState();
}

class _VolunteerReportsListPageState extends State<VolunteerReportsListPage> {
  bool _isSelectionMode = false;
  List<int> _selectedReportIds = [];

  @override
  void initState() {
    super.initState();
    Provider.of<VolunteerProvider>(context, listen: false).fetchReports();
  }

  void _toggleSelection(int reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
      } else {
        _selectedReportIds.add(reportId);
      }
      if (_selectedReportIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int reportId) {
    setState(() {
      _isSelectionMode = true;
      _selectedReportIds.add(reportId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReportIds.clear();
    });
  }

  Future<void> _deleteSelectedReports() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteSelectedReports),
          content: Text(l10n.areYouSureYouWantToDeleteNReports(_selectedReportIds.length)),
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
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
      await volunteerProvider.deleteMultipleReports(_selectedReportIds);
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              backgroundColor: const Color(0xFF8B5CF6),
              title: Text('${_selectedReportIds.length} selected', style: const TextStyle(color: Colors.white)),
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.volunteerReports,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Consumer2<VolunteerProvider, UserProvider>(
        builder: (context, volunteerProvider, userProvider, child) {
          final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
          // Get only reports from selected center
          final centerReports = volunteerProvider.getReportsByCenter(selectedCenter);
          
          if (centerReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No volunteer reports found yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: centerReports.length,
            itemBuilder: (context, index) {
              final report = centerReports[index];
              final isSelected = _selectedReportIds.contains(report.id);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: const Color(0xFF8B5CF6), width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.all(16),
                    onExpansionChanged: (expanded) {
                      if (_isSelectionMode && expanded) {
                        _toggleSelection(report.id);
                      }
                    },
                    leading: _isSelectionMode
                        ? Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
                            size: 28,
                          )
                        : CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF8B5CF6),
                            child: Text(
                              report.volunteerName.isNotEmpty ? report.volunteerName[0].toUpperCase() : 'V',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    title: Text(
                      report.volunteerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Class ${report.classBatch}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${report.inTime} - ${report.outTime}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: _isSelectionMode
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditVolunteerReportPage(report: report),
                                    ),
                                  );
                                },
                                tooltip: 'Edit Report',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Report'),
                                        content: Text(
                                          'Are you sure you want to delete this report by ${report.volunteerName}?'
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          TextButton(
                                            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed == true) {
                                    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
                                    await volunteerProvider.deleteMultipleReports([report.id]);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Report deleted successfully'),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      );
                                    }
                                  }
                                },
                                tooltip: 'Delete Report',
                              ),
                            ],
                          ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              icon: Icons.school,
                              label: 'Activity Taught',
                              value: report.activityTaught,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.people,
                              label: 'Students',
                              value: '${report.selectedStudents.length} students attended',
                            ),
                            const SizedBox(height: 12),
                            if (report.testConducted) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Test Conducted',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Topic: ${report.testTopic ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF166534)),
                                    ),
                                    if (report.testStudents.isNotEmpty)
                                      Text(
                                        'Test Takers: ${report.testStudents.length} students',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF166534)),
                                      ),
                                  ],
                                ),
                              ),
                            ] else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'No test conducted',
                                      style: TextStyle(
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _deleteSelectedReports,
              icon: const Icon(Icons.delete),
              label: const Text('Delete Selected'),
              backgroundColor: const Color(0xFFEF4444),
            )
          : null,
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
