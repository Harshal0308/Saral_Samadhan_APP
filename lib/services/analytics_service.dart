import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';

/// Service for generating analytics and insights
class AnalyticsService {
  /// Calculate attendance percentage for a date range
  static double calculateAttendancePercentage(
    List<AttendanceRecord> records,
    int totalStudents,
  ) {
    if (records.isEmpty || totalStudents == 0) return 0.0;
    
    int totalPresent = 0;
    int totalPossible = records.length * totalStudents;
    
    for (var record in records) {
      totalPresent += record.attendance.values.where((v) => v == true).length;
    }
    
    return totalPossible > 0 ? (totalPresent / totalPossible) * 100 : 0.0;
  }

  /// Get attendance trend data for charts (date -> percentage)
  static Map<DateTime, double> getAttendanceTrend(
    List<AttendanceRecord> records,
    int totalStudents,
  ) {
    final Map<DateTime, double> trend = {};
    
    for (var record in records) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      final presentCount = record.attendance.values.where((v) => v == true).length;
      final percentage = totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;
      trend[date] = percentage;
    }
    
    return trend;
  }

  /// Get student-wise attendance percentage
  static Map<Student, double> getStudentAttendancePercentages(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<Student, double> percentages = {};
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      int presentCount = 0;
      int totalDays = records.length;
      
      for (var record in records) {
        if (record.attendance[compositeKey] == true) {
          presentCount++;
        }
      }
      
      percentages[student] = totalDays > 0 ? (presentCount / totalDays) * 100 : 0.0;
    }
    
    return percentages;
  }

  /// Identify at-risk students (low attendance)
  static List<Student> getAtRiskStudents(
    List<Student> students,
    List<AttendanceRecord> records,
    {double threshold = 50.0}
  ) {
    final percentages = getStudentAttendancePercentages(students, records);
    return percentages.entries
        .where((entry) => entry.value < threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get class-wise attendance comparison
  static Map<String, double> getClassWiseAttendance(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<String, int> classPresentCount = {};
    final Map<String, int> classTotalCount = {};
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      classTotalCount[student.classBatch] = (classTotalCount[student.classBatch] ?? 0) + records.length;
      
      for (var record in records) {
        if (record.attendance[compositeKey] == true) {
          classPresentCount[student.classBatch] = (classPresentCount[student.classBatch] ?? 0) + 1;
        }
      }
    }
    
    final Map<String, double> classPercentages = {};
    for (var className in classTotalCount.keys) {
      final present = classPresentCount[className] ?? 0;
      final total = classTotalCount[className] ?? 0;
      classPercentages[className] = total > 0 ? (present / total) * 100 : 0.0;
    }
    
    return classPercentages;
  }

  /// Calculate total volunteer hours from reports
  static double getTotalVolunteerHours(List<VolunteerReport> reports) {
    double totalHours = 0.0;
    
    for (var report in reports) {
      try {
        final inTime = _parseTime(report.inTime);
        final outTime = _parseTime(report.outTime);
        
        if (inTime != null && outTime != null) {
          final duration = outTime.difference(inTime);
          totalHours += duration.inMinutes / 60.0;
        }
      } catch (e) {
        // Skip invalid time entries
      }
    }
    
    return totalHours;
  }

  /// Get volunteer-wise hours
  static Map<String, double> getVolunteerHours(List<VolunteerReport> reports) {
    final Map<String, double> hours = {};
    
    for (var report in reports) {
      try {
        final inTime = _parseTime(report.inTime);
        final outTime = _parseTime(report.outTime);
        
        if (inTime != null && outTime != null) {
          final duration = outTime.difference(inTime);
          final volunteerHours = duration.inMinutes / 60.0;
          hours[report.volunteerName] = (hours[report.volunteerName] ?? 0.0) + volunteerHours;
        }
      } catch (e) {
        // Skip invalid time entries
      }
    }
    
    return hours;
  }

  /// Get most taught subjects from volunteer reports
  static Map<String, int> getSubjectDistribution(List<VolunteerReport> reports) {
    final Map<String, int> distribution = {};
    
    for (var report in reports) {
      final subject = report.activityTaught.split('-').first.trim();
      distribution[subject] = (distribution[subject] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Generate key insights
  static List<String> generateInsights(
    List<Student> students,
    List<AttendanceRecord> attendanceRecords,
    List<VolunteerReport> volunteerReports,
  ) {
    final insights = <String>[];
    
    // At-risk students
    final atRiskStudents = getAtRiskStudents(students, attendanceRecords);
    if (atRiskStudents.isNotEmpty) {
      insights.add('${atRiskStudents.length} student${atRiskStudents.length > 1 ? 's' : ''} need attention (low attendance)');
    }
    
    // Attendance trend
    if (attendanceRecords.length >= 2) {
      final recent = attendanceRecords.take(7).toList();
      final older = attendanceRecords.skip(7).take(7).toList();
      
      if (older.isNotEmpty) {
        final recentAvg = calculateAttendancePercentage(recent, students.length);
        final olderAvg = calculateAttendancePercentage(older, students.length);
        final change = recentAvg - olderAvg;
        
        if (change.abs() > 5) {
          insights.add('Attendance ${change > 0 ? 'improved' : 'decreased'} by ${change.abs().toStringAsFixed(1)}% this week');
        }
      }
    }
    
    // Volunteer hours
    final totalHours = getTotalVolunteerHours(volunteerReports);
    if (totalHours > 0) {
      insights.add('${totalHours.toStringAsFixed(1)} volunteer hours contributed');
    }
    
    // Most active volunteer
    final volunteerHours = getVolunteerHours(volunteerReports);
    if (volunteerHours.isNotEmpty) {
      final topVolunteer = volunteerHours.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Most active: ${topVolunteer.key} (${topVolunteer.value.toStringAsFixed(1)}h)');
    }
    
    return insights;
  }

  /// Parse time string (HH:MM format) to DateTime
  static DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }

  /// Get day-wise attendance pattern (Monday = 1, Sunday = 7)
  static Map<int, double> getDayWiseAttendancePattern(
    List<AttendanceRecord> records,
    int totalStudents,
  ) {
    final Map<int, List<double>> dayAttendance = {};
    
    for (var record in records) {
      final dayOfWeek = record.date.weekday;
      final presentCount = record.attendance.values.where((v) => v == true).length;
      final percentage = totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;
      
      if (!dayAttendance.containsKey(dayOfWeek)) {
        dayAttendance[dayOfWeek] = [];
      }
      dayAttendance[dayOfWeek]!.add(percentage);
    }
    
    // Calculate average for each day
    final Map<int, double> averages = {};
    for (var entry in dayAttendance.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }
    
    return averages;
  }

  /// Get best and worst attendance days
  static Map<String, dynamic> getBestWorstDays(
    List<AttendanceRecord> records,
    int totalStudents,
  ) {
    final dayPattern = getDayWiseAttendancePattern(records, totalStudents);
    
    if (dayPattern.isEmpty) {
      return {'best': null, 'worst': null};
    }
    
    final best = dayPattern.entries.reduce((a, b) => a.value > b.value ? a : b);
    final worst = dayPattern.entries.reduce((a, b) => a.value < b.value ? a : b);
    
    return {
      'best': {'day': _getDayName(best.key), 'percentage': best.value},
      'worst': {'day': _getDayName(worst.key), 'percentage': worst.value},
    };
  }

  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
