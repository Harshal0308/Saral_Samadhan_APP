import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/widgets/attendance_graph.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/models/ptm_report.dart';
import 'package:samadhan_app/services/ptm_report_service.dart';
import 'package:samadhan_app/pages/student_details_view_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';


class StudentDetailedReportPage extends StatefulWidget {
  final Student student;

  const StudentDetailedReportPage({super.key, required this.student});

  @override
  State<StudentDetailedReportPage> createState() => _StudentDetailedReportPageState();
}

class _StudentDetailedReportPageState extends State<StudentDetailedReportPage> {
  // Touch tracking removed to prevent lag

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
        widget.student.centerName,
        startOfMonth,
        now,
      );
      
      // Calculate attendance stats
      int totalDays = 0;
      int presentDays = 0;
      final compositeKey = '${widget.student.rollNo}_${widget.student.classBatch}';
      
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
                  _buildInfoRow('Name:', widget.student.name),
                  _buildInfoRow('Roll Number:', widget.student.rollNo),
                  _buildInfoRow('Class/Batch:', widget.student.classBatch),
                  _buildInfoRow('Center:', widget.student.centerName),
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
                  if (widget.student.lessonsLearned.isEmpty)
                    pw.Text('No lessons recorded yet.', style: const pw.TextStyle(color: PdfColors.grey600))
                  else
                    ...widget.student.lessonsLearned.map((lesson) => pw.Padding(
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
            
            // Subject Performance Score (SPS) - PTM Report
            ..._buildPTMSubjectPerformancePDF(widget.student),
            
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
      final fileName = 'Student_Report_${widget.student.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
          subject: 'Student Progress Report - ${widget.student.name}',
          text: 'Sharing progress report for ${widget.student.name} (${widget.student.classBatch})',
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

  /// Build PTM Subject Performance Score section for PDF
  List<pw.Widget> _buildPTMSubjectPerformancePDF(Student student) {
    final performances = PTMReportService.generateReport(student);
    final summary = PTMReportService.getOverallSummary(performances);

    if (performances.isEmpty) {
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SUBJECT PERFORMANCE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Text('No performance data available yet.',
                  style: const pw.TextStyle(color: PdfColors.grey600)),
            ],
          ),
        ),
      ];
    }

    final widgets = <pw.Widget>[];

    // Overall Summary
    widgets.add(pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getPdfGradeBgColor(summary.overallGrade),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _getPdfGradeColor(summary.overallGrade)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('OVERALL PERFORMANCE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _getPdfGradeColor(summary.overallGrade),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text('Grade ${summary.overallGrade.letter}',
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Score: ${summary.overallScore.toStringAsFixed(1)}% | ${summary.overallGrade.displayName}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (summary.strongSubjects.isNotEmpty)
            pw.Text('Strong: ${summary.strongSubjects.join(", ")}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.green700)),
          if (summary.needsImprovementSubjects.isNotEmpty)
            pw.Text('Needs focus: ${summary.needsImprovementSubjects.join(", ")}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.orange700)),
        ],
      ),
    ));

    widgets.add(pw.SizedBox(height: 20));

    // Subject Cards
    for (final perf in performances) {
      widgets.add(_buildPdfSubjectCard(perf));
      widgets.add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  pw.Widget _buildPdfSubjectCard(SubjectPerformance perf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _getPdfGradeColor(perf.grade), width: 2),
        borderRadius: pw.BorderRadius.circular(8),
        color: _getPdfGradeBgColor(perf.grade),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(perf.subject,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _getPdfGradeColor(perf.grade),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('${perf.grade.letter} (${perf.sps.toStringAsFixed(0)}%)',
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Progress bar
          pw.Container(
            height: 12,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Stack(
              children: [
                pw.Container(
                  width: (perf.sps / 100) * 450,
                  decoration: pw.BoxDecoration(
                    color: _getPdfGradeColor(perf.grade),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Understanding: ', style: const pw.TextStyle(fontSize: 10)),
              ...List.generate(5, (i) => pw.Text(
                i < perf.understandingStars ? '★' : '☆',
                style: pw.TextStyle(fontSize: 10, color: i < perf.understandingStars ? PdfColors.amber : PdfColors.grey400),
              )),
              pw.SizedBox(width: 10),
              pw.Text('(${perf.topicsEvaluated} topics, ${perf.testsTaken} tests)',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(perf.remark, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(perf.dataSourceNote, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  PdfColor _getPdfGradeColor(PTMGrade grade) {
    switch (grade) {
      case PTMGrade.A: return PdfColors.green;
      case PTMGrade.B: return PdfColors.lightGreen700;
      case PTMGrade.C: return PdfColors.orange;
      case PTMGrade.D: return PdfColors.red;
    }
  }

  PdfColor _getPdfGradeBgColor(PTMGrade grade) {
    switch (grade) {
      case PTMGrade.A: return PdfColors.green50;
      case PTMGrade.B: return PdfColors.lightGreen50;
      case PTMGrade.C: return PdfColors.orange50;
      case PTMGrade.D: return PdfColors.red50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1), // Purple background
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Report',
            onPressed: () => _shareReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Generate PDF Report',
            onPressed: () => _generatePDFReport(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Info Card at top with purple background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
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
                          widget.student.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Roll ${widget.student.rollNo} • Class ${widget.student.classBatch}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.centerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Attendance Summary Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Attendance Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    FutureBuilder<List<AttendanceRecord>>(
                      future: Provider.of<AttendanceProvider>(context, listen: false)
                          .fetchAttendanceRecordsByCenterAndDateRange(
                        widget.student.centerName,
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
                        final compositeKey = '${widget.student.rollNo}_${widget.student.classBatch}';

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
                        final int absentSessions = totalSessions - attendedSessions;

                        // Calculate monthly attendance
                        final now = DateTime.now();
                        final monthlyStats = <String, Map<String, double>>{};
                        
                        for (int i = 3; i >= 0; i--) {
                          final month = DateTime(now.year, now.month - i, 1);
                          final monthKey = _getMonthName(month.month);
                          monthlyStats[monthKey] = {'attended': 0.0, 'total': 0.0};
                        }
                        
                        for (final stat in stats) {
                          final monthKey = _getMonthName(stat.date.month);
                          if (monthlyStats.containsKey(monthKey)) {
                            monthlyStats[monthKey]!['attended'] = 
                                (monthlyStats[monthKey]!['attended'] ?? 0.0) + stat.attended.toDouble();
                            monthlyStats[monthKey]!['total'] = 
                                (monthlyStats[monthKey]!['total'] ?? 0.0) + stat.total.toDouble();
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Interactive Attendance Bar Chart
                            Container(
                              height: 220,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF6366F1).withOpacity(0.05),
                                    const Color(0xFF8B5CF6).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: _buildAttendanceBarChart(monthlyStats),
                            ),
                            const SizedBox(height: 24),
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  '${overallPercentage.toStringAsFixed(0)}%',
                                  'Overall',
                                  const Color(0xFF10B981),
                                ),
                                _buildStatCard(
                                  '$attendedSessions',
                                  'Present',
                                  const Color(0xFF6B7280),
                                ),
                                _buildStatCard(
                                  '$absentSessions',
                                  'Absent',
                                  const Color(0xFFEF4444),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 3. Learning Progress Card - Grouped by Subject with Color-Coded Topics
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.book,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Learning Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Legend for color codes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(Colors.green, 'Good'),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.orange, 'Average'),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.red, 'Poor'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.student.lessonsLearned.isEmpty)
                      Text(
                        'No lessons recorded yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      _buildSubjectTopicsSection(),
                    if (widget.student.lessonsLearned.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.menu_book, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Text(
                            'Topics completed: ${widget.student.lessonsLearned.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 4. Test Results Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.student.testResults.isEmpty)
                      Text(
                        'No test results recorded yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else ...[
                      // Interactive Test Results Line Chart
                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFEF3C7).withOpacity(0.3),
                              const Color(0xFFFED7AA).withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: _buildTestResultsLineChart(),
                      ),
                      const SizedBox(height: 16),
                      // Test Results List
                      for (final mapEntry in widget.student.testResults.entries.toList().asMap().entries)
                        Builder(
                          builder: (context) {
                            final index = mapEntry.key;
                            final entry = mapEntry.value;
                            
                            // Parse marks if it's a number
                            final marksStr = entry.value;
                            final isNumeric = double.tryParse(marksStr) != null;
                            final percentage = isNumeric ? double.parse(marksStr) : 85.0;
                            
                            // Generate a date (most recent first)
                            final now = DateTime.now();
                            final testDate = DateTime(now.year, now.month, now.day - (index * 5));
                            final dateStr = '${testDate.day} ${_getMonthName(testDate.month)}';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _getScoreBgColor(percentage),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _getScoreTextColor(percentage),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),

                    // Generate PDF Button
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
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Helper method to build legend item for color codes
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Build subject-wise topics section with expandable dropdowns
  Widget _buildSubjectTopicsSection() {
    // Group lessons by subject
    final Map<String, List<String>> subjectTopics = {};
    
    for (final lesson in widget.student.lessonsLearned) {
      final parts = lesson.split(':');
      if (parts.length >= 2) {
        final subject = parts[0].trim();
        final topic = parts.sublist(1).join(':').trim();
        subjectTopics.putIfAbsent(subject, () => []);
        if (!subjectTopics[subject]!.contains(topic)) {
          subjectTopics[subject]!.add(topic);
        }
      }
    }

    if (subjectTopics.isEmpty) {
      return Text(
        'No lessons recorded yet.',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      children: subjectTopics.entries.map((entry) {
        final subject = entry.key;
        final topics = entry.value;
        
        // Count evaluations for this subject
        int goodCount = 0;
        int avgCount = 0;
        int poorCount = 0;
        
        for (final topic in topics) {
          final evaluationKey = '${subject}_${topic}_${widget.student.id}';
          final evaluation = widget.student.topicEvaluations[evaluationKey];
          if (evaluation != null) {
            switch (evaluation.evaluation) {
              case EvaluationLevel.good:
                goodCount++;
                break;
              case EvaluationLevel.average:
                avgCount++;
                break;
              case EvaluationLevel.poor:
                poorCount++;
                break;
            }
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSubjectIcon(subject),
                  color: _getSubjectColor(subject),
                  size: 20,
                ),
              ),
              title: Text(
                subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    '${topics.length} topics',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (goodCount > 0 || avgCount > 0 || poorCount > 0) ...[
                    const SizedBox(width: 8),
                    if (goodCount > 0) _buildMiniCount(Colors.green, goodCount),
                    if (avgCount > 0) _buildMiniCount(Colors.orange, avgCount),
                    if (poorCount > 0) _buildMiniCount(Colors.red, poorCount),
                  ],
                ],
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.map((topic) {
                    // Get evaluation for this topic
                    final evaluationKey = '${subject}_${topic}_${widget.student.id}';
                    final evaluation = widget.student.topicEvaluations[evaluationKey];
                    
                    // Determine color based on evaluation
                    Color bgColor;
                    Color textColor;
                    Color borderColor;
                    
                    if (evaluation != null) {
                      switch (evaluation.evaluation) {
                        case EvaluationLevel.good:
                          bgColor = Colors.green.shade50;
                          textColor = Colors.green.shade700;
                          borderColor = Colors.green.shade300;
                          break;
                        case EvaluationLevel.average:
                          bgColor = Colors.orange.shade50;
                          textColor = Colors.orange.shade700;
                          borderColor = Colors.orange.shade300;
                          break;
                        case EvaluationLevel.poor:
                          bgColor = Colors.red.shade50;
                          textColor = Colors.red.shade700;
                          borderColor = Colors.red.shade300;
                          break;
                      }
                    } else {
                      // No evaluation yet - use grey
                      bgColor = Colors.grey.shade100;
                      textColor = Colors.grey.shade600;
                      borderColor = Colors.grey.shade300;
                    }
                    
                    return Tooltip(
                      message: evaluation != null 
                        ? '${evaluation.evaluation.displayName} - Evaluated by ${evaluation.evaluatedBy}'
                        : 'Not evaluated yet',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Text(
                          topic,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Mini count badge for subject summary
  Widget _buildMiniCount(Color color, int count) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Get subject-specific color
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return const Color(0xFF3B82F6); // Blue
      case 'science':
        return const Color(0xFF10B981); // Green
      case 'english':
        return const Color(0xFF8B5CF6); // Purple
      case 'social science':
        return const Color(0xFFF59E0B); // Amber
      case 'computer':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  // Get subject-specific icon
  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.language;
      case 'social science':
        return Icons.public;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.book;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _getScoreBgColor(double score) {
    if (score >= 85) return const Color(0xFFD1FAE5); // Light green
    if (score >= 70) return const Color(0xFFFEF3C7); // Light yellow
    if (score >= 50) return const Color(0xFFFFEDD5); // Light orange
    return const Color(0xFFFEE2E2); // Light red
  }

  Color _getScoreTextColor(double score) {
    if (score >= 85) return const Color(0xFF059669); // Dark green
    if (score >= 70) return const Color(0xFFD97706); // Dark yellow
    if (score >= 50) return const Color(0xFFEA580C); // Dark orange
    return const Color(0xFFDC2626); // Dark red
  }

  Widget _buildAttendanceBarChart(Map<String, Map<String, double>> monthlyStats) {
    final entries = monthlyStats.entries.toList();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: false, // Disabled to prevent lag
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[value.toInt()].key,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = data.value['total']! > 0
              ? (data.value['attended']! * 100.0 / data.value['total']!)
              : 0.0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: percentage,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 24,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestResultsLineChart() {
    final testEntries = widget.student.testResults.entries.toList();
    if (testEntries.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    for (int i = 0; i < testEntries.length; i++) {
      final marksStr = testEntries[i].value;
      final isNumeric = double.tryParse(marksStr) != null;
      final percentage = isNumeric ? double.parse(marksStr) : 85.0;
      spots.add(FlSpot(i.toDouble(), percentage));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          enabled: false, // Disabled to prevent lag
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < testEntries.length) {
                  final testName = testEntries[value.toInt()].key;
                  final shortName = testName.length > 8 
                      ? '${testName.substring(0, 8)}...' 
                      : testName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortName,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFFF59E0B),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.3),
                  const Color(0xFFF59E0B).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
