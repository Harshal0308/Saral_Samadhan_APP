import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/export_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportedReportsPage extends StatefulWidget {
  const ExportedReportsPage({super.key});

  @override
  State<ExportedReportsPage> createState() => _ExportedReportsPageState();
}

class _ExportedReportsPageState extends State<ExportedReportsPage> {
  late Future<List<File>> _exportedFilesFuture;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    
    // Initialize with an empty future to prevent LateInitializationError
    final exportProvider = Provider.of<ExportProvider>(context, listen: false);
    _exportedFilesFuture = exportProvider.getExportedFiles();
    
    // Fetch volunteer and attendance reports first, then load exported files
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    Future.wait([
      volunteerProvider.fetchReports(),
      attendanceProvider.fetchAttendanceRecords(),
    ]).then((_) {
      _loadExportedFiles();
      // Auto-cleanup old exports on page load (keeps last 60 days)
      _autoCleanupOldExports();
    });
    
    // Default to last 30 days
    _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
    _selectedEndDate = DateTime.now();
  }

  /// Automatically clean up exports older than 60 days to prevent stack up
  Future<void> _autoCleanupOldExports() async {
    try {
      final exportProvider = Provider.of<ExportProvider>(context, listen: false);
      final deletedCount = await exportProvider.cleanupOldExports(retentionDays: 60);
      if (deletedCount > 0) {
        print('🧹 Auto-cleanup: Removed $deletedCount old export files');
      }
    } catch (e) {
      print('⚠️ Auto-cleanup failed: $e');
    }
  }

  void _loadExportedFiles() {
    final exportProvider = Provider.of<ExportProvider>(context, listen: false);
    setState(() {
      _exportedFilesFuture = exportProvider.getExportedFiles();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          if (_selectedEndDate != null && _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedEndDate = picked; // Adjust end date if it's before start date
          }
        } else {
          _selectedEndDate = picked;
          if (_selectedStartDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedStartDate = picked; // Adjust start date if it's after end date
          }
        }
      });
    }
  }

  Future<void> _generateAttendanceReport() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range for the attendance report.')),
      );
      return;
    }

    final exportProvider = Provider.of<ExportProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // ✅ FIX: Fetch attendance records for the selected center and date range
    final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
      selectedCenter,
      _selectedStartDate!,
      _selectedEndDate!,
    );

    if (attendanceRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records found for the selected date range.')),
      );
      notificationProvider.addNotification(
        title: 'Attendance Export Failed',
        message: 'No attendance records found for the selected date range (${_selectedStartDate!.toLocal().toString().split(' ')[0]} to ${_selectedEndDate!.toLocal().toString().split(' ')[0]}).',
        type: 'warning',
      );
      return;
    }

    try {
      // ✅ FIX: Pass centerName to filter students during export
      final path = await exportProvider.exportAttendanceToExcel(
        attendanceRecords,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        centerName: selectedCenter,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance report saved to $path')),
      );
      notificationProvider.addNotification(
        title: 'Attendance Report Exported',
        message: 'Attendance report for ${_selectedStartDate!.toLocal().toString().split(' ')[0]} to ${_selectedEndDate!.toLocal().toString().split(' ')[0]} saved successfully.',
        type: 'success',
      );
      _loadExportedFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate attendance report: $e')),
      );
      notificationProvider.addNotification(
        title: 'Attendance Export Failed',
        message: 'Failed to generate attendance report: $e',
        type: 'alert',
      );
    }
  }

  Future<void> _generateVolunteerReport(List<VolunteerReport> reports) async {
    final exportProvider = Provider.of<ExportProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    print('DEBUG: _generateVolunteerReport called with ${reports.length} reports');
    
    try {
      if (reports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No reports to export.')),
        );
        return;
      }
      
      final path = await exportProvider.exportVolunteerReportToPdf(
        reports,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
      print('DEBUG: PDF generated successfully at $path');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Volunteer report saved to $path')),
      );
      notificationProvider.addNotification(
        title: 'Volunteer Report Exported',
        message: 'Volunteer report for selected range exported successfully.',
        type: 'success',
      );
      _loadExportedFiles();
    } catch (e, stackTrace) {
      print('DEBUG: Error generating volunteer report: $e');
      print('DEBUG: Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate volunteer report: $e')),
      );
      notificationProvider.addNotification(
        title: 'Volunteer Report Export Failed',
        message: 'Failed to generate volunteer report: $e',
        type: 'alert',
      );
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
          'Exported Reports',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Date Range and Generate Buttons Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date Range Selectors
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _selectedStartDate == null
                              ? 'Start Date'
                              : _selectedStartDate!.toLocal().toString().split(' ')[0],
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _selectedEndDate == null
                              ? 'End Date'
                              : _selectedEndDate!.toLocal().toString().split(' ')[0],
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Generate Buttons
                ElevatedButton.icon(
                  onPressed: _generateAttendanceReport,
                  icon: const Icon(Icons.table_chart, size: 20),
                  label: const Text('Generate Attendance Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<VolunteerProvider>(
                  builder: (context, volunteerProvider, child) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedStartDate == null || _selectedEndDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a date range for the volunteer report.')),
                          );
                          return;
                        }
                        final reports = volunteerProvider.reports.where((report) {
                          final reportDate = DateTime.fromMillisecondsSinceEpoch(report.id);
                          final startDate = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
                          final endDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day + 1);
                          return !reportDate.isBefore(startDate) && reportDate.isBefore(endDate);
                        }).toList();

                        if (reports.isNotEmpty) {
                          _generateVolunteerReport(reports);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No volunteer reports available to export for the selected date range.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Generate Volunteer Report PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Exported Files List
          Expanded(
            child: FutureBuilder<List<File>>(
              future: _exportedFilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No exported reports found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final files = snapshot.data!;
                final attendanceFiles = files.where((f) => f.path.contains('Attendance')).toList();
                final volunteerFiles = files.where((f) => f.path.contains('VolunteerReport')).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (attendanceFiles.isNotEmpty)
                      _buildReportSection(context, 'Attendance Excel Files', attendanceFiles, Icons.table_chart, const Color(0xFF10B981)),
                    if (volunteerFiles.isNotEmpty)
                      _buildReportSection(context, 'Volunteer Daily Reports', volunteerFiles, Icons.description, const Color(0xFF8B5CF6)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Samadhan App Report',
        text: 'Sharing report: $fileName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReportSection(BuildContext context, String title, List<File> files, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 24),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Files List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final fileName = file.path.split(Platform.pathSeparator).last;
            final fileSize = _formatFileSize(file.lengthSync());
            final modifiedDate = file.lastModifiedSync();
            final formattedDate = '${modifiedDate.day} ${_getMonthName(modifiedDate.month)} ${modifiedDate.year}';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final result = await OpenFile.open(file.path);
                  if (result.type != ResultType.done) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not open file: ${result.message}'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // File Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      // File Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.insert_drive_file, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  fileSize,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.file_download, color: Color(0xFF6B7280)),
                            onPressed: () => _shareFile(file),
                            tooltip: 'Download',
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Color(0xFF6B7280)),
                            onPressed: () => _shareFile(file),
                            tooltip: 'Share',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}