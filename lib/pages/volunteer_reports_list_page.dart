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
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedReportIds.length} selected'),
            )
          : AppBar(
              title: Text(l10n.volunteerReports),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Go back to Volunteer Options Page
                },
              ),
            ),
      body: Consumer2<VolunteerProvider, UserProvider>(
        builder: (context, volunteerProvider, userProvider, child) {
          final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
          // Get only reports from selected center
          final centerReports = volunteerProvider.getReportsByCenter(selectedCenter);
          
          if (centerReports.isEmpty) {
            return const Center(
              child: Text('No volunteer reports found yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: centerReports.length,
            itemBuilder: (context, index) {
              final report = centerReports[index];
              final isSelected = _selectedReportIds.contains(report.id);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: isSelected ? Colors.blue.shade100 : null,
                child: InkWell(
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _enterSelectionMode(report.id);
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(report.id);
                    }
                  },
                  child: ExpansionTile(
                    title: Text('${l10n.reportBy} ${report.volunteerName}'),
                    subtitle: Text('Class: ${report.classBatch} - ${report.inTime} to ${report.outTime}'),
                    trailing: _isSelectionMode
                        ? Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: Colors.blue,
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditVolunteerReportPage(report: report),
                                ),
                              );
                            },
                          ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activity Taught: ${report.activityTaught}'),
                            const SizedBox(height: 8),
                            Text('Students: ${report.selectedStudents.join(', ')}'),
                            const SizedBox(height: 8),
                            if (report.testConducted)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Test Conducted: Yes'),
                                  Text('Test Topic: ${report.testTopic ?? 'N/A'}'),
                                  Text('Marks/Grade: ${report.marksGrade ?? 'N/A'}'),
                                ],
                              )
                            else
                              const Text('Test Conducted: No'),
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
          ? FloatingActionButton(
              onPressed: _deleteSelectedReports,
              child: const Icon(Icons.delete),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }
}
