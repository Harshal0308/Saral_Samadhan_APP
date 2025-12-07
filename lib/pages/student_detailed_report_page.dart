import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:samadhan_app/widgets/attendance_graph.dart';


class StudentDetailedReportPage extends StatelessWidget {
  final Student student;

  const StudentDetailedReportPage({super.key, required this.student});

  Future<String?> _generatePDFReport(BuildContext context, {bool autoOpen = true}) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF Report...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdf = pw.Document();
      
      // Get attendance data
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
        student.centerName,
        startOfMonth,
        now,
      );
      
      // Calculate attendance stats
      int totalDays = 0;
      int presentDays = 0;
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      
      for (var record in attendanceRecords) {
        if (record.attendance.containsKey(compositeKey)) {
          totalDays++;
          if (record.attendance[compositeKey] == true) {
            presentDays++;
          }
        }
      }
      
      final attendancePercentage = totalDays > 0 ? (presentDays / totalDays * 100).toStringAsFixed(1) : '0.0';

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT PROGRESS REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'For Parent-Teacher Meeting',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Student Information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Name:', student.name),
                  _buildInfoRow('Roll Number:', student.rollNo),
                  _buildInfoRow('Class/Batch:', student.classBatch),
                  _buildInfoRow('Center:', student.centerName),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Attendance Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ATTENDANCE SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Total Classes:', '$totalDays'),
                  _buildInfoRow('Classes Attended:', '$presentDays'),
                  _buildInfoRow('Classes Missed:', '${totalDays - presentDays}'),
                  _buildInfoRow('Attendance Percentage:', '$attendancePercentage%'),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    height: 20,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          width: (double.parse(attendancePercentage) / 100) * 500,
                          decoration: pw.BoxDecoration(
                            color: double.parse(attendancePercentage) >= 75 
                                ? PdfColors.green 
                                : double.parse(attendancePercentage) >= 50 
                                    ? PdfColors.orange 
                                    : PdfColors.red,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Lessons Learned
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LESSONS LEARNED',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  if (student.lessonsLearned.isEmpty)
                    pw.Text('No lessons recorded yet.', style: const pw.TextStyle(color: PdfColors.grey600))
                  else
                    ...student.lessonsLearned.map((lesson) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            margin: const pw.EdgeInsets.only(top: 4, right: 8),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.green,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(child: pw.Text(lesson)),
                        ],
                      ),
                    )).toList(),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Test Results
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TEST RESULTS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  if (student.testResults.isEmpty)
                    pw.Text('No test results recorded yet.', style: const pw.TextStyle(color: PdfColors.grey600))
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Test Topic', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Marks/Grade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...student.testResults.entries.map((entry) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(entry.key),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(entry.value),
                            ),
                          ],
                        )).toList(),
                      ],
                    ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REMARKS & RECOMMENDATIONS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '(To be filled during parent-teacher meeting)',
                      style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('_____________________'),
                    pw.SizedBox(height: 4),
                    pw.Text('Teacher Signature', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('_____________________'),
                    pw.SizedBox(height: 4),
                    pw.Text('Parent Signature', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Student_Report_${student.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success and open PDF
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Report generated: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        
        // Auto-open PDF if requested
        if (autoOpen) {
          await OpenFile.open(file.path);
        }
      }
      
      return file.path;
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    try {
      // Generate PDF without auto-opening
      final filePath = await _generatePDFReport(context, autoOpen: false);
      
      if (filePath != null) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Student Progress Report - ${student.name}',
          text: 'Sharing progress report for ${student.name} (${student.classBatch})',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student.name}\'s Report'),
        backgroundColor: SaralColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Share Button
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: () => _shareReport(context),
          ),
          // PDF Generation Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: () => _generatePDFReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Generate PDF Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _generatePDFReport(context),
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text(
                  'Generate PDF Report for Parent Meeting',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // 1. Profile Section
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: SaralColors.accent,
                        child: Icon(Icons.person, size: 60, color: SaralColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Name: ${student.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Roll No: ${student.rollNo}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Class: ${student.classBatch}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Center: Center A - Mumbai', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                  ],
                ),
              ),
            ),

            // 2. Attendance Summary
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Summary', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),

                    FutureBuilder<List<AttendanceRecord>>(
                      future: Provider.of<AttendanceProvider>(context, listen: false)
                          .fetchAttendanceRecordsByCenterAndDateRange(
                        student.centerName,
                        DateTime(DateTime.now().year, DateTime.now().month, 1),
                        DateTime.now(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text('Error loading attendance data');
                        }

                        final records = snapshot.data ?? [];
                        final compositeKey = '${student.rollNo}_${student.classBatch}';

                        final List<DailyAttendanceStat> stats = [];
                        int totalSessions = 0;
                        int attendedSessions = 0;

                        for (final record in records) {
                          int attended = 0;
                          int total = 0;

                          // Prefer sessionMeta if available
                          if (record.sessionMeta.containsKey(compositeKey)) {
                            final meta = record.sessionMeta[compositeKey]!;
                            attended = meta['attended'] ?? 0;
                            total = meta['total'] ?? 0;
                          } else if (record.attendance.containsKey(compositeKey)) {
                            // Fallback: 1-of-1 style (old style)
                            final present = record.attendance[compositeKey] ?? false;
                            attended = present ? 1 : 0;
                            total = 1;
                          }

                          if (total > 0) {
                            stats.add(
                              DailyAttendanceStat(
                                date: record.date,
                                attended: attended,
                                total: total,
                              ),
                            );
                            totalSessions += total;
                            attendedSessions += attended;
                          }
                        }

                        if (stats.isEmpty) {
                          return const Text(
                            'No attendance data recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        final double overallPercentage =
                            totalSessions > 0 ? (attendedSessions * 100.0 / totalSessions) : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AttendanceGraph(data: stats),
                            const SizedBox(height: 10),
                            Text(
                              'Percentage: ${overallPercentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              'Total sessions attended: $attendedSessions / $totalSessions',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),


            // 3. Academic Progress
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Progress', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Lesson Learned', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    if (student.lessonsLearned.isEmpty)
                      const Text('No lessons recorded yet.')
                    else
                      ...student.lessonsLearned.map((lesson) => ListTile(
                        leading: const Icon(Icons.check, color: Colors.green),
                        title: Text(lesson),
                      )).toList(),
                  ],
                ),
              ),
            ),

            // 4. Test Results
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Results', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (student.testResults.isEmpty)
                      const Text('No test results recorded yet.')
                    else
                      ...student.testResults.entries.map((entry) => ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.blue),
                        title: Text(entry.key),
                        subtitle: Text('Marks/Grade: ${entry.value}'),
                      )).toList(),
                  ],
                ),
              ),
            ),

            // 5. Additional Metrics
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Additional Metrics', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Volunteer effectiveness score: 4.5/5', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
