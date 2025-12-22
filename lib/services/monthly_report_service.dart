import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/analytics_service.dart';
import 'package:samadhan_app/data/subjects_topics.dart';
import 'package:intl/intl.dart';

class MonthlyReportService {
  
  /// Generate comprehensive monthly report
  static Future<Map<String, dynamic>> generateMonthlyReport({
    required List<Student> students,
    required List<AttendanceRecord> attendanceRecords,
    required List<VolunteerReport> volunteerReports,
    required DateTime month,
    String? centerName,
  }) async {
    
    // Filter data for the specific month
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    
    final monthlyAttendance = attendanceRecords.where((record) =>
        record.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
        record.date.isBefore(monthEnd.add(const Duration(days: 1)))
    ).toList();
    
    final monthlyReports = volunteerReports.where((report) =>
        // We don't have exact dates in volunteer reports, so we'll use all reports
        true // TODO: Add date field to volunteer reports
    ).toList();
    
    // Filter by center if specified
    List<Student> filteredStudents = centerName != null
        ? students.where((s) => s.centerName == centerName).toList()
        : students;
    
    List<AttendanceRecord> filteredAttendance = centerName != null
        ? monthlyAttendance.where((r) => r.centerName == centerName).toList()
        : monthlyAttendance;
    
    List<VolunteerReport> filteredReports = centerName != null
        ? monthlyReports.where((r) => r.centerName == centerName).toList()
        : monthlyReports;
    
    // Generate analytics
    final analytics = AnalyticsService.generateStudentAnalyticsSummary(
      filteredStudents,
      filteredAttendance,
      filteredReports,
      SubjectsTopics.subjectsWithTopics,
    );
    
    // Calculate additional monthly metrics
    final monthlyMetrics = _calculateMonthlyMetrics(
      filteredStudents,
      filteredAttendance,
      filteredReports,
      monthStart,
      monthEnd,
    );
    
    return {
      'reportDate': DateTime.now(),
      'reportMonth': month,
      'centerName': centerName ?? 'All Centers',
      'summary': _generateExecutiveSummary(analytics, monthlyMetrics),
      'enrollment': analytics['enrollment'],
      'attendance': analytics['attendance'],
      'learning': analytics['learning'],
      'risks': analytics['risks'],
      'monthlyMetrics': monthlyMetrics,
      'insights': analytics['insights'],
      'recommendations': _generateRecommendations(analytics, monthlyMetrics),
    };
  }
  
  /// Calculate monthly-specific metrics
  static Map<String, dynamic> _calculateMonthlyMetrics(
    List<Student> students,
    List<AttendanceRecord> attendanceRecords,
    List<VolunteerReport> volunteerReports,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    // Calculate working days in month (excluding weekends)
    int workingDays = 0;
    DateTime current = monthStart;
    while (current.isBefore(monthEnd.add(const Duration(days: 1)))) {
      if (current.weekday <= 5) { // Monday to Friday
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    // Calculate actual teaching days
    final teachingDays = attendanceRecords.length;
    
    // Calculate new enrollments (students added this month)
    // Note: We don't have enrollment dates, so this would need to be added to Student model
    final newEnrollments = 0; // TODO: Implement when enrollment dates are available
    
    // Calculate dropouts (students who haven't attended in last 10 days of month)
    final dropouts = _calculateDropouts(students, attendanceRecords, monthEnd);
    
    // Calculate volunteer engagement
    final uniqueVolunteers = volunteerReports.map((r) => r.volunteerName).toSet().length;
    final totalVolunteerHours = AnalyticsService.getTotalVolunteerHours(volunteerReports);
    
    // Calculate test statistics
    final testStats = _calculateTestStatistics(students, volunteerReports);
    
    return {
      'workingDays': workingDays,
      'teachingDays': teachingDays,
      'attendanceRate': teachingDays > 0 ? (teachingDays / workingDays) * 100 : 0.0,
      'newEnrollments': newEnrollments,
      'dropouts': dropouts,
      'netEnrollmentChange': newEnrollments - dropouts.length,
      'uniqueVolunteers': uniqueVolunteers,
      'totalVolunteerHours': totalVolunteerHours,
      'averageHoursPerVolunteer': uniqueVolunteers > 0 ? totalVolunteerHours / uniqueVolunteers : 0.0,
      'testStatistics': testStats,
    };
  }
  
  /// Calculate students who might have dropped out
  static List<Student> _calculateDropouts(
    List<Student> students,
    List<AttendanceRecord> attendanceRecords,
    DateTime monthEnd,
  ) {
    final dropouts = <Student>[];
    final lastTenDays = monthEnd.subtract(const Duration(days: 10));
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      
      // Check if student attended in last 10 days of month
      final recentAttendance = attendanceRecords.where((record) =>
          record.date.isAfter(lastTenDays) &&
          record.attendance.containsKey(compositeKey) &&
          record.attendance[compositeKey] == true
      ).toList();
      
      if (recentAttendance.isEmpty && attendanceRecords.isNotEmpty) {
        dropouts.add(student);
      }
    }
    
    return dropouts;
  }
  
  /// Calculate test statistics for the month
  static Map<String, dynamic> _calculateTestStatistics(
    List<Student> students,
    List<VolunteerReport> volunteerReports,
  ) {
    int totalTests = 0;
    int studentsWhoTookTests = 0;
    final Set<int> testedStudentIds = {};
    
    for (var report in volunteerReports) {
      if (report.testConducted) {
        totalTests++;
        testedStudentIds.addAll(report.testStudents);
      }
    }
    
    // Also count tests from student records
    for (var student in students) {
      if (student.testResults.isNotEmpty) {
        testedStudentIds.add(student.id);
      }
    }
    
    studentsWhoTookTests = testedStudentIds.length;
    
    return {
      'totalTests': totalTests,
      'studentsWhoTookTests': studentsWhoTookTests,
      'testParticipationRate': students.isNotEmpty ? (studentsWhoTookTests / students.length) * 100 : 0.0,
      'averageTestsPerStudent': studentsWhoTookTests > 0 ? totalTests / studentsWhoTookTests : 0.0,
    };
  }
  
  /// Generate executive summary
  static Map<String, dynamic> _generateExecutiveSummary(
    Map<String, dynamic> analytics,
    Map<String, dynamic> monthlyMetrics,
  ) {
    final enrollment = analytics['enrollment'] as Map<String, dynamic>;
    final attendance = analytics['attendance'] as Map<String, dynamic>;
    final risks = analytics['risks'] as Map<String, dynamic>;
    
    final totalStudents = enrollment['total'] as int;
    final overallAttendance = attendance['overall'] as double;
    final atRiskCount = (risks['atRiskStudents'] as List).length;
    final dropoutSignals = (risks['dropoutSignals'] as List).length;
    
    final teachingDays = monthlyMetrics['teachingDays'] as int;
    final workingDays = monthlyMetrics['workingDays'] as int;
    final volunteerHours = monthlyMetrics['totalVolunteerHours'] as double;
    
    return {
      'totalStudents': totalStudents,
      'overallAttendance': overallAttendance,
      'teachingDays': teachingDays,
      'workingDays': workingDays,
      'volunteerHours': volunteerHours,
      'atRiskStudents': atRiskCount,
      'dropoutSignals': dropoutSignals,
      'healthScore': _calculateHealthScore(overallAttendance, atRiskCount, totalStudents),
    };
  }
  
  /// Calculate overall program health score (0-100)
  static double _calculateHealthScore(double attendance, int atRisk, int total) {
    if (total == 0) return 0.0;
    
    // Attendance contributes 60% to health score
    final attendanceScore = attendance * 0.6;
    
    // Risk factor contributes 40% (inverse - fewer at-risk students = better score)
    final riskScore = total > 0 ? ((total - atRisk) / total) * 40 : 0.0;
    
    return attendanceScore + riskScore;
  }
  
  /// Generate actionable recommendations
  static List<String> _generateRecommendations(
    Map<String, dynamic> analytics,
    Map<String, dynamic> monthlyMetrics,
  ) {
    final recommendations = <String>[];
    
    final attendance = analytics['attendance'] as Map<String, dynamic>;
    final risks = analytics['risks'] as Map<String, dynamic>;
    final learning = analytics['learning'] as Map<String, dynamic>;
    
    final overallAttendance = attendance['overall'] as double;
    final atRiskStudents = risks['atRiskStudents'] as List;
    final dropoutSignals = risks['dropoutSignals'] as List;
    final decliningPerformance = risks['decliningPerformance'] as List;
    
    // Attendance recommendations
    if (overallAttendance < 70) {
      recommendations.add('🚨 URGENT: Overall attendance is critically low (${overallAttendance.toStringAsFixed(1)}%). Implement immediate intervention strategies.');
    } else if (overallAttendance < 80) {
      recommendations.add('⚠️ Attendance needs improvement (${overallAttendance.toStringAsFixed(1)}%). Consider parent meetings and incentive programs.');
    }
    
    // At-risk student recommendations
    if (atRiskStudents.isNotEmpty) {
      recommendations.add('👥 ${atRiskStudents.length} students need immediate attention for low attendance. Schedule one-on-one meetings.');
    }
    
    // Dropout prevention recommendations
    if (dropoutSignals.isNotEmpty) {
      recommendations.add('🆘 ${dropoutSignals.length} students showing dropout signals. Implement retention strategies immediately.');
    }
    
    // Performance recommendations
    if (decliningPerformance.isNotEmpty) {
      recommendations.add('📉 ${decliningPerformance.length} students showing declining performance. Provide additional academic support.');
    }
    
    // Learning coverage recommendations
    final coverage = learning['coverage'] as Map<Student, Map<String, double>>? ?? {};
    if (coverage.isNotEmpty) {
      final averageCoverage = _calculateAverageCoverage(coverage);
      if (averageCoverage < 50) {
        recommendations.add('📚 Syllabus coverage is low (${averageCoverage.toStringAsFixed(1)}%). Focus on completing more topics per session.');
      }
    }
    
    // Volunteer recommendations
    final volunteerHours = monthlyMetrics['totalVolunteerHours'] as double;
    final uniqueVolunteers = monthlyMetrics['uniqueVolunteers'] as int;
    if (uniqueVolunteers < 5) {
      recommendations.add('🤝 Consider recruiting more volunteers. Currently only $uniqueVolunteers active volunteers.');
    }
    
    // Test recommendations
    final testStats = monthlyMetrics['testStatistics'] as Map<String, dynamic>;
    final testParticipation = testStats['testParticipationRate'] as double;
    if (testParticipation < 70) {
      recommendations.add('📝 Test participation is low (${testParticipation.toStringAsFixed(1)}%). Encourage more regular assessments.');
    }
    
    return recommendations;
  }
  
  /// Calculate average learning coverage across all students
  static double _calculateAverageCoverage(Map<Student, Map<String, double>> coverage) {
    if (coverage.isEmpty) return 0.0;
    
    double totalCoverage = 0.0;
    int totalSubjects = 0;
    
    coverage.forEach((student, subjects) {
      subjects.forEach((subject, percentage) {
        totalCoverage += percentage;
        totalSubjects++;
      });
    });
    
    return totalSubjects > 0 ? totalCoverage / totalSubjects : 0.0;
  }
  
  /// Generate formatted report text
  static String generateReportText(Map<String, dynamic> reportData) {
    final monthName = DateFormat('MMMM yyyy').format(reportData['reportMonth']);
    final centerName = reportData['centerName'] as String;
    final summary = reportData['summary'] as Map<String, dynamic>;
    final recommendations = reportData['recommendations'] as List<String>;
    final insights = reportData['insights'] as List<String>;
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('📊 MONTHLY STUDENT ANALYTICS REPORT');
    buffer.writeln('═' * 50);
    buffer.writeln('Month: $monthName');
    buffer.writeln('Center: $centerName');
    buffer.writeln('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(reportData['reportDate'])}');
    buffer.writeln();
    
    // Executive Summary
    buffer.writeln('📈 EXECUTIVE SUMMARY');
    buffer.writeln('─' * 30);
    buffer.writeln('Total Students: ${summary['totalStudents']}');
    buffer.writeln('Overall Attendance: ${(summary['overallAttendance'] as double).toStringAsFixed(1)}%');
    buffer.writeln('Teaching Days: ${summary['teachingDays']}/${summary['workingDays']} working days');
    buffer.writeln('Volunteer Hours: ${(summary['volunteerHours'] as double).toStringAsFixed(1)}h');
    buffer.writeln('At-Risk Students: ${summary['atRiskStudents']}');
    buffer.writeln('Health Score: ${(summary['healthScore'] as double).toStringAsFixed(1)}/100');
    buffer.writeln();
    
    // Key Insights
    if (insights.isNotEmpty) {
      buffer.writeln('💡 KEY INSIGHTS');
      buffer.writeln('─' * 30);
      for (var insight in insights) {
        buffer.writeln('• $insight');
      }
      buffer.writeln();
    }
    
    // Recommendations
    if (recommendations.isNotEmpty) {
      buffer.writeln('🎯 RECOMMENDATIONS');
      buffer.writeln('─' * 30);
      for (var recommendation in recommendations) {
        buffer.writeln('• $recommendation');
      }
      buffer.writeln();
    }
    
    // Detailed Metrics
    final enrollment = reportData['enrollment'] as Map<String, dynamic>;
    final attendance = reportData['attendance'] as Map<String, dynamic>;
    final learning = reportData['learning'] as Map<String, dynamic>;
    final risks = reportData['risks'] as Map<String, dynamic>;
    
    buffer.writeln('📊 DETAILED METRICS');
    buffer.writeln('─' * 30);
    
    // Enrollment breakdown
    final byCenter = enrollment['byCenter'] as Map<String, int>? ?? {};
    if (byCenter.isNotEmpty) {
      buffer.writeln('Enrollment by Center:');
      byCenter.forEach((center, count) {
        buffer.writeln('  • $center: $count students');
      });
      buffer.writeln();
    }
    
    // Attendance breakdown
    final centerWise = attendance['centerWise'] as Map<String, double>? ?? {};
    if (centerWise.isNotEmpty) {
      buffer.writeln('Attendance by Center:');
      centerWise.forEach((center, percentage) {
        buffer.writeln('  • $center: ${percentage.toStringAsFixed(1)}%');
      });
      buffer.writeln();
    }
    
    // Risk analysis
    final dropoutSignals = risks['dropoutSignals'] as List<Map<String, dynamic>>? ?? [];
    if (dropoutSignals.isNotEmpty) {
      buffer.writeln('Students with Dropout Signals:');
      for (var signal in dropoutSignals.take(5)) {
        final student = signal['student'] as Student;
        final absences = signal['consecutiveAbsences'] as int;
        final riskLevel = signal['riskLevel'] as String;
        buffer.writeln('  • ${student.name} (${student.rollNo}): $absences consecutive absences - $riskLevel risk');
      }
      if (dropoutSignals.length > 5) {
        buffer.writeln('  ... and ${dropoutSignals.length - 5} more');
      }
      buffer.writeln();
    }
    
    buffer.writeln('─' * 50);
    buffer.writeln('Report generated by Samadhan App Analytics');
    
    return buffer.toString();
  }
}