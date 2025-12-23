import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart'; // Import AttendanceProvider
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportProvider {
  final StudentProvider _studentProvider;

  ExportProvider(this._studentProvider);

  // Helper to get application documents directory
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> exportAttendanceToExcel(List<AttendanceRecord> attendanceRecords, {DateTime? startDate, DateTime? endDate, String? centerName}) async {
    print('📊 EXPORTING ATTENDANCE TO EXCEL');
    print('   Total attendance records: ${attendanceRecords.length}');
    print('   Center filter: ${centerName ?? "ALL"}');
    
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // ✅ FIX: Filter students by center if provided
    final List<Student> studentsToExport = centerName != null
        ? _studentProvider.getStudentsByCenter(centerName)
        : _studentProvider.students;
    
    print('   Total students to export: ${studentsToExport.length}');

    // Determine all unique dates for columns
    final List<DateTime> uniqueDates = attendanceRecords
        .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
        .toSet()
        .toList();
    uniqueDates.sort((a, b) => a.compareTo(b));
    print('   Unique dates: ${uniqueDates.map((d) => "${d.day}/${d.month}/${d.year}").join(", ")}');

    // Create header row: Student Info + Dates
    List<CellValue> header = [
      TextCellValue('Roll No'),
      TextCellValue('Student Name'),
      TextCellValue('Class'),
    ];
    for (var date in uniqueDates) {
      header.add(TextCellValue('${date.day}/${date.month}/${date.year}'));
    }
    sheet.insertRowIterables(header, 0);

    // ✅ FIX: Create data rows for filtered students only
    int rowIndex = 1;
    for (var student in studentsToExport) {
      List<CellValue> row = [
        TextCellValue(student.rollNo),
        TextCellValue(student.name),
        TextCellValue(student.classBatch),
      ];

      for (var date in uniqueDates) {
        bool presentForDate = false;
        // ✅ FIX: Use composite key consistently
        final compositeKey = '${student.rollNo}_${student.classBatch}';
        
        for (var record in attendanceRecords) {
          if (record.date.year == date.year &&
              record.date.month == date.month &&
              record.date.day == date.day) {
            
            // Check if student was present using composite key
            if (record.attendance.containsKey(compositeKey) && 
                record.attendance[compositeKey] == true) {
              presentForDate = true;
              break;
            }
          }
        }
        row.add(TextCellValue(presentForDate ? 'P' : 'A'));
      }
      sheet.insertRowIterables(row, rowIndex++);
    }

    // Generate filename based on date range
    String filename = 'Attendance';
    if (startDate != null && endDate != null) {
      final monthStart = _getMonthName(startDate.month);
      final dayStart = startDate.day;
      final yearStart = startDate.year;
      final monthEnd = _getMonthName(endDate.month);
      final dayEnd = endDate.day;
      final yearEnd = endDate.year;
      
      if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
        // Same day
        filename = 'Attendance_${dayStart}_${monthStart}_$yearStart';
      } else {
        // Date range
        filename = 'Attendance_${dayStart}_${monthStart}_${yearStart}_to_${dayEnd}_${monthEnd}_${yearEnd}';
      }
    } else {
      // Fallback if dates not provided
      final now = DateTime.now();
      filename = 'Attendance_${now.day}_${_getMonthName(now.month)}_${now.year}';
    }

    final path = '${await _getLocalPath()}/${filename}.xlsx';
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      return path;
    }
    throw Exception('Failed to save Excel file.');
  }

  Future<String> exportVolunteerReportToPdf(List<VolunteerReport> reports, {DateTime? startDate, DateTime? endDate}) async {
    final pdf = pw.Document();
    final Map<int, Student> studentsMap = {for (var s in _studentProvider.students) s.id: s};

    for (var report in reports) {
      final reportDate = DateTime.fromMillisecondsSinceEpoch(report.id);
      final formattedDate = '${reportDate.day}/${reportDate.month}/${reportDate.year}';
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VOLUNTEER DAILY REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Teaching Session Summary',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.purple700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Report Date: $formattedDate',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Volunteer Information
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
                    'VOLUNTEER INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  _buildPdfInfoRow('Volunteer Name:', report.volunteerName),
                  _buildPdfInfoRow('Center:', report.centerName),
                  _buildPdfInfoRow('Class/Batch:', report.classBatch),
                  _buildPdfInfoRow('In Time:', report.inTime),
                  _buildPdfInfoRow('Out Time:', report.outTime),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Session Summary
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
                    'SESSION SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  _buildPdfInfoRow('Total Students:', '${report.selectedStudents.length}'),
                  _buildPdfInfoRow('Activity Taught:', report.activityTaught),
                  _buildPdfInfoRow('Test Conducted:', report.testConducted ? 'Yes' : 'No'),
                  if (report.testConducted && report.testTopic != null)
                    _buildPdfInfoRow('Test Topic:', report.testTopic!),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Students Taught
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
                    'STUDENTS TAUGHT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  if (report.selectedStudents.isEmpty)
                    pw.Text('No students recorded.', style: const pw.TextStyle(color: PdfColors.grey600))
                  else
                    ...report.selectedStudents.map((studentId) {
                      final student = studentsMap[studentId];
                      final studentName = student?.name ?? 'Unknown Student ($studentId)';
                      final rollNo = student?.rollNo ?? '';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              margin: const pw.EdgeInsets.only(top: 4, right: 8),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.purple,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                rollNo.isNotEmpty ? '$studentName (Roll: $rollNo)' : studentName,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Test Results (if test was conducted)
            if (report.testConducted) ...[
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
                        color: PdfColors.purple900,
                      ),
                    ),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 10),
                    if (report.testStudents.isEmpty)
                      pw.Text('No test results recorded.', style: const pw.TextStyle(color: PdfColors.grey600))
                    else
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Student Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Roll No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Marks/Grade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...report.testStudents.map((studentId) {
                            final student = studentsMap[studentId];
                            final studentName = student?.name ?? 'Unknown';
                            final rollNo = student?.rollNo ?? 'N/A';
                            final marks = report.testMarks[studentId] ?? 'N/A';
                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(studentName),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(rollNo),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(marks),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Remarks Section
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
                    'REMARKS & OBSERVATIONS',
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
                      '(Additional notes or observations)',
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
                    pw.Text('Volunteer Signature', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('_____________________'),
                    pw.SizedBox(height: 4),
                    pw.Text('Coordinator Signature', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Generate filename based on date range
    String filename = 'VolunteerReport';
    if (startDate != null && endDate != null) {
      final monthStart = _getMonthName(startDate.month);
      final dayStart = startDate.day;
      final yearStart = startDate.year;
      final monthEnd = _getMonthName(endDate.month);
      final dayEnd = endDate.day;
      final yearEnd = endDate.year;
      
      if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
        // Same day
        filename = 'VolunteerReport_${dayStart}_${monthStart}_$yearStart';
      } else {
        // Date range
        filename = 'VolunteerReport_${dayStart}_${monthStart}_${yearStart}_to_${dayEnd}_${monthEnd}_${yearEnd}';
      }
    } else {
      // Fallback if dates not provided
      final now = DateTime.now();
      filename = 'VolunteerReport_${now.day}_${_getMonthName(now.month)}_${now.year}';
    }

    final path = '${await _getLocalPath()}/${filename}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
  
  // Helper method for PDF info rows
  pw.Widget _buildPdfInfoRow(String label, String value) {
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
  
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<List<File>> getExportedFiles() async {
    final directory = Directory(await _getLocalPath());
    if (!await directory.exists()) {
      return [];
    }
    final files = directory.listSync().whereType<File>().where((file) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return fileName.startsWith('Attendance') || fileName.startsWith('VolunteerReport');
    }).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Clean up old exported files (older than specified days)
  /// Keeps files within the retention period to prevent stack up
  Future<int> cleanupOldExports({int retentionDays = 30}) async {
    try {
      final directory = Directory(await _getLocalPath());
      if (!await directory.exists()) {
        return 0;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: retentionDays));
      int deletedCount = 0;

      final files = directory.listSync().whereType<File>().where((file) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        return fileName.startsWith('Attendance') || fileName.startsWith('VolunteerReport');
      }).toList();

      for (var file in files) {
        final lastModified = file.lastModifiedSync();
        if (lastModified.isBefore(cutoffDate)) {
          try {
            await file.delete();
            deletedCount++;
            print('🗑️ Deleted old export: ${file.path.split(Platform.pathSeparator).last}');
          } catch (e) {
            print('❌ Failed to delete ${file.path}: $e');
          }
        }
      }

      print('✅ Cleanup complete: Deleted $deletedCount old export files');
      return deletedCount;
    } catch (e) {
      print('❌ Error during cleanup: $e');
      return 0;
    }
  }

  /// Delete all exported files (for reset functionality)
  Future<int> deleteAllExports() async {
    try {
      final directory = Directory(await _getLocalPath());
      if (!await directory.exists()) {
        return 0;
      }

      int deletedCount = 0;
      final files = directory.listSync().whereType<File>().where((file) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        return fileName.startsWith('Attendance') || fileName.startsWith('VolunteerReport');
      }).toList();

      for (var file in files) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          print('❌ Failed to delete ${file.path}: $e');
        }
      }

      print('✅ Deleted all $deletedCount export files');
      return deletedCount;
    } catch (e) {
      print('❌ Error deleting exports: $e');
      return 0;
    }
  }

  /// Share a file (Excel or PDF) via WhatsApp, Email, etc.
  Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileName = filePath.split(Platform.pathSeparator).last;
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Samadhan App Report',
        text: text ?? 'Sharing report: $fileName',
      );
      
      print('✅ File shared: $fileName');
    } catch (e) {
      print('❌ Error sharing file: $e');
      rethrow;
    }
  }
}
