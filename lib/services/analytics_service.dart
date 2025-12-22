import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'dart:math' as math;

/// Service for generating analytics and insights
class AnalyticsService {
  
  // ============================================================================
  // STUDENT-LEVEL ANALYSIS
  // ============================================================================
  
  /// Get student enrollment by center
  static Map<String, int> getStudentEnrollmentByCenter(List<Student> students) {
    final Map<String, int> enrollment = {};
    for (var student in students) {
      enrollment[student.centerName] = (enrollment[student.centerName] ?? 0) + 1;
    }
    return enrollment;
  }
  
  /// Get student enrollment by class/grade
  static Map<String, int> getStudentEnrollmentByClass(List<Student> students) {
    final Map<String, int> enrollment = {};
    for (var student in students) {
      enrollment[student.classBatch] = (enrollment[student.classBatch] ?? 0) + 1;
    }
    return enrollment;
  }
  
  /// Get student enrollment by center and class
  static Map<String, Map<String, int>> getStudentEnrollmentByCenterAndClass(List<Student> students) {
    final Map<String, Map<String, int>> enrollment = {};
    for (var student in students) {
      if (!enrollment.containsKey(student.centerName)) {
        enrollment[student.centerName] = {};
      }
      enrollment[student.centerName]![student.classBatch] = 
          (enrollment[student.centerName]![student.classBatch] ?? 0) + 1;
    }
    return enrollment;
  }
  
  /// Calculate overall attendance percentage for all students
  static double getOverallAttendancePercentage(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    if (students.isEmpty || records.isEmpty) return 0.0;
    
    int totalPresent = 0;
    int totalPossible = 0;
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      for (var record in records) {
        if (record.attendance.containsKey(compositeKey)) {
          totalPossible++;
          if (record.attendance[compositeKey] == true) {
            totalPresent++;
          }
        }
      }
    }
    
    return totalPossible > 0 ? (totalPresent / totalPossible) * 100 : 0.0;
  }
  
  /// Get month-wise attendance percentage
  static Map<String, double> getMonthWiseAttendance(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<String, Map<String, int>> monthlyData = {}; // month -> {present, total}
    
    for (var record in records) {
      final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'present': 0, 'total': 0};
      }
      
      for (var student in students) {
        final compositeKey = '${student.rollNo}_${student.classBatch}';
        if (record.attendance.containsKey(compositeKey)) {
          monthlyData[monthKey]!['total'] = monthlyData[monthKey]!['total']! + 1;
          if (record.attendance[compositeKey] == true) {
            monthlyData[monthKey]!['present'] = monthlyData[monthKey]!['present']! + 1;
          }
        }
      }
    }
    
    final Map<String, double> monthlyPercentages = {};
    monthlyData.forEach((month, data) {
      final total = data['total']!;
      final present = data['present']!;
      monthlyPercentages[month] = total > 0 ? (present / total) * 100 : 0.0;
    });
    
    return monthlyPercentages;
  }
  
  /// Get center-wise attendance percentage
  static Map<String, double> getCenterWiseAttendance(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<String, Map<String, int>> centerData = {}; // center -> {present, total}
    
    for (var record in records) {
      if (!centerData.containsKey(record.centerName)) {
        centerData[record.centerName] = {'present': 0, 'total': 0};
      }
      
      final centerStudents = students.where((s) => s.centerName == record.centerName);
      for (var student in centerStudents) {
        final compositeKey = '${student.rollNo}_${student.classBatch}';
        if (record.attendance.containsKey(compositeKey)) {
          centerData[record.centerName]!['total'] = centerData[record.centerName]!['total']! + 1;
          if (record.attendance[compositeKey] == true) {
            centerData[record.centerName]!['present'] = centerData[record.centerName]!['present']! + 1;
          }
        }
      }
    }
    
    final Map<String, double> centerPercentages = {};
    centerData.forEach((center, data) {
      final total = data['total']!;
      final present = data['present']!;
      centerPercentages[center] = total > 0 ? (present / total) * 100 : 0.0;
    });
    
    return centerPercentages;
  }
  
  /// Calculate learning coverage (% syllabus completed per student)
  static Map<Student, Map<String, double>> getLearningCoverage(
    List<Student> students,
    Map<String, List<String>> subjectsTopics, // From SubjectsTopics.subjectsWithTopics
  ) {
    final Map<Student, Map<String, double>> coverage = {};
    
    for (var student in students) {
      coverage[student] = {};
      
      // Group lessons learned by subject
      final Map<String, Set<String>> learnedBySubject = {};
      for (var lesson in student.lessonsLearned) {
        // Try to extract subject from lesson format
        String subject = 'General';
        if (lesson.contains(':')) {
          subject = lesson.split(':')[0].trim();
        } else if (lesson.contains('-')) {
          subject = lesson.split('-')[0].trim();
        }
        
        if (!learnedBySubject.containsKey(subject)) {
          learnedBySubject[subject] = {};
        }
        learnedBySubject[subject]!.add(lesson);
      }
      
      // Calculate coverage percentage for each subject
      subjectsTopics.forEach((subject, topics) {
        final learnedTopics = learnedBySubject[subject]?.length ?? 0;
        final totalTopics = topics.length;
        coverage[student]![subject] = totalTopics > 0 ? (learnedTopics / totalTopics) * 100 : 0.0;
      });
    }
    
    return coverage;
  }
  
  /// Get test performance - average marks per subject
  static Map<String, double> getAverageMarksBySubject(List<Student> students) {
    final Map<String, List<double>> subjectScores = {};
    
    for (var student in students) {
      student.testResults.forEach((testTopic, marks) {
        String subject = 'General';
        
        // Extract subject from test topic
        if (testTopic.contains(':')) {
          subject = testTopic.split(':')[0].trim();
        }
        
        // Parse marks to percentage
        double? score = _parseMarksToPercentage(marks);
        if (score != null) {
          if (!subjectScores.containsKey(subject)) {
            subjectScores[subject] = [];
          }
          subjectScores[subject]!.add(score);
        }
      });
    }
    
    final Map<String, double> averages = {};
    subjectScores.forEach((subject, scores) {
      if (scores.isNotEmpty) {
        averages[subject] = scores.reduce((a, b) => a + b) / scores.length;
      }
    });
    
    return averages;
  }
  
  /// Calculate pass/fail ratio
  static Map<String, Map<String, int>> getPassFailRatio(
    List<Student> students, 
    {double passingThreshold = 50.0}
  ) {
    final Map<String, Map<String, int>> ratios = {};
    
    for (var student in students) {
      student.testResults.forEach((testTopic, marks) {
        String subject = 'General';
        if (testTopic.contains(':')) {
          subject = testTopic.split(':')[0].trim();
        }
        
        double? score = _parseMarksToPercentage(marks);
        if (score != null) {
          if (!ratios.containsKey(subject)) {
            ratios[subject] = {'pass': 0, 'fail': 0};
          }
          
          if (score >= passingThreshold) {
            ratios[subject]!['pass'] = ratios[subject]!['pass']! + 1;
          } else {
            ratios[subject]!['fail'] = ratios[subject]!['fail']! + 1;
          }
        }
      });
    }
    
    return ratios;
  }
  
  /// Identify dropout signals - consecutive absences
  static List<Map<String, dynamic>> getDropoutSignals(
    List<Student> students,
    List<AttendanceRecord> records,
    {int consecutiveAbsenceThreshold = 5}
  ) {
    final List<Map<String, dynamic>> signals = [];
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      
      // Get attendance records for this student, sorted by date
      final studentRecords = records
          .where((r) => r.attendance.containsKey(compositeKey))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      
      if (studentRecords.isEmpty) continue;
      
      // Count consecutive absences
      int consecutiveAbsences = 0;
      int maxConsecutiveAbsences = 0;
      DateTime? lastAbsenceDate;
      
      for (var record in studentRecords) {
        final isPresent = record.attendance[compositeKey] == true;
        
        if (!isPresent) {
          consecutiveAbsences++;
          lastAbsenceDate = record.date;
          maxConsecutiveAbsences = math.max(maxConsecutiveAbsences, consecutiveAbsences);
        } else {
          consecutiveAbsences = 0;
        }
      }
      
      // Check for dropout signals
      if (maxConsecutiveAbsences >= consecutiveAbsenceThreshold) {
        signals.add({
          'student': student,
          'consecutiveAbsences': maxConsecutiveAbsences,
          'currentStreak': consecutiveAbsences,
          'lastAbsenceDate': lastAbsenceDate,
          'riskLevel': maxConsecutiveAbsences >= 10 ? 'High' : 
                     maxConsecutiveAbsences >= 7 ? 'Medium' : 'Low',
        });
      }
    }
    
    // Sort by risk level and consecutive absences
    signals.sort((a, b) {
      final aRisk = a['riskLevel'] as String;
      final bRisk = b['riskLevel'] as String;
      if (aRisk != bRisk) {
        const riskOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        return riskOrder[aRisk]!.compareTo(riskOrder[bRisk]!);
      }
      return (b['consecutiveAbsences'] as int).compareTo(a['consecutiveAbsences'] as int);
    });
    
    return signals;
  }
  
  /// Identify declining performance
  static List<Map<String, dynamic>> getDecliningPerformance(
    List<Student> students,
    List<VolunteerReport> reports,
    {int minimumTests = 3, double declineThreshold = 15.0}
  ) {
    final List<Map<String, dynamic>> declining = [];
    
    for (var student in students) {
      // Get test scores for this student from volunteer reports
      final List<Map<String, dynamic>> testScores = [];
      
      for (var report in reports) {
        if (report.testConducted && report.testMarks.containsKey(student.id)) {
          final marks = report.testMarks[student.id]!;
          final score = _parseMarksToPercentage(marks);
          if (score != null) {
            testScores.add({
              'score': score,
              'topic': report.testTopic ?? 'Unknown',
              'subject': report.activityTaught.split('-')[0].trim(),
              'date': DateTime.now(), // We don't have exact date from reports
            });
          }
        }
      }
      
      // Also check student's own test results
      student.testResults.forEach((testTopic, marks) {
        final score = _parseMarksToPercentage(marks);
        if (score != null) {
          testScores.add({
            'score': score,
            'topic': testTopic,
            'subject': testTopic.contains(':') ? testTopic.split(':')[0].trim() : 'General',
            'date': DateTime.now(),
          });
        }
      });
      
      if (testScores.length < minimumTests) continue;
      
      // Sort by date (most recent first)
      testScores.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      // Calculate trend (compare recent vs older scores)
      final recentScores = testScores.take(testScores.length ~/ 2).map((t) => t['score'] as double).toList();
      final olderScores = testScores.skip(testScores.length ~/ 2).map((t) => t['score'] as double).toList();
      
      if (recentScores.isNotEmpty && olderScores.isNotEmpty) {
        final recentAvg = recentScores.reduce((a, b) => a + b) / recentScores.length;
        final olderAvg = olderScores.reduce((a, b) => a + b) / olderScores.length;
        final decline = olderAvg - recentAvg;
        
        if (decline >= declineThreshold) {
          declining.add({
            'student': student,
            'decline': decline,
            'recentAverage': recentAvg,
            'previousAverage': olderAvg,
            'totalTests': testScores.length,
            'riskLevel': decline >= 30 ? 'High' : decline >= 20 ? 'Medium' : 'Low',
          });
        }
      }
    }
    
    // Sort by decline amount
    declining.sort((a, b) => (b['decline'] as double).compareTo(a['decline'] as double));
    
    return declining;
  }
  
  /// Generate comprehensive student analytics summary
  static Map<String, dynamic> generateStudentAnalyticsSummary(
    List<Student> students,
    List<AttendanceRecord> attendanceRecords,
    List<VolunteerReport> volunteerReports,
    Map<String, List<String>> subjectsTopics,
  ) {
    return {
      'enrollment': {
        'total': students.length,
        'byCenter': getStudentEnrollmentByCenter(students),
        'byClass': getStudentEnrollmentByClass(students),
        'byCenterAndClass': getStudentEnrollmentByCenterAndClass(students),
      },
      'attendance': {
        'overall': getOverallAttendancePercentage(students, attendanceRecords),
        'monthWise': getMonthWiseAttendance(students, attendanceRecords),
        'centerWise': getCenterWiseAttendance(students, attendanceRecords),
        'studentWise': getStudentAttendancePercentages(students, attendanceRecords),
      },
      'learning': {
        'coverage': getLearningCoverage(students, subjectsTopics),
        'averageMarksBySubject': getAverageMarksBySubject(students),
        'passFailRatio': getPassFailRatio(students),
      },
      'risks': {
        'atRiskStudents': getAtRiskStudents(students, attendanceRecords),
        'dropoutSignals': getDropoutSignals(students, attendanceRecords),
        'decliningPerformance': getDecliningPerformance(students, volunteerReports),
      },
      'insights': generateStudentInsights(students, attendanceRecords, volunteerReports),
    };
  }
  
  /// Generate student-specific insights
  static List<String> generateStudentInsights(
    List<Student> students,
    List<AttendanceRecord> attendanceRecords,
    List<VolunteerReport> volunteerReports,
  ) {
    final insights = <String>[];
    
    // Enrollment insights
    final centerEnrollment = getStudentEnrollmentByCenter(students);
    if (centerEnrollment.isNotEmpty) {
      final topCenter = centerEnrollment.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('${topCenter.key} has the highest enrollment (${topCenter.value} students)');
    }
    
    // Attendance insights
    final overallAttendance = getOverallAttendancePercentage(students, attendanceRecords);
    if (overallAttendance > 0) {
      insights.add('Overall attendance rate: ${overallAttendance.toStringAsFixed(1)}%');
    }
    
    // Risk insights
    final dropoutSignals = getDropoutSignals(students, attendanceRecords);
    if (dropoutSignals.isNotEmpty) {
      final highRisk = dropoutSignals.where((s) => s['riskLevel'] == 'High').length;
      if (highRisk > 0) {
        insights.add('$highRisk student${highRisk > 1 ? 's' : ''} at high dropout risk');
      }
    }
    
    // Performance insights
    final declining = getDecliningPerformance(students, volunteerReports);
    if (declining.isNotEmpty) {
      insights.add('${declining.length} student${declining.length > 1 ? 's' : ''} showing declining performance');
    }
    
    // Learning coverage insights
    final averageMarks = getAverageMarksBySubject(students);
    if (averageMarks.isNotEmpty) {
      final bestSubject = averageMarks.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Best performing subject: ${bestSubject.key} (${bestSubject.value.toStringAsFixed(1)}% avg)');
    }
    
    return insights;
  }
  
  // ============================================================================
  // CENTER-LEVEL ANALYSIS
  // ============================================================================
  
  /// Compare attendance across centers
  static Map<String, Map<String, dynamic>> getCenterAttendanceComparison(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<String, Map<String, dynamic>> centerComparison = {};
    
    // Group students by center
    final Map<String, List<Student>> studentsByCenter = {};
    for (var student in students) {
      if (!studentsByCenter.containsKey(student.centerName)) {
        studentsByCenter[student.centerName] = [];
      }
      studentsByCenter[student.centerName]!.add(student);
    }
    
    // Calculate metrics for each center
    studentsByCenter.forEach((centerName, centerStudents) {
      final centerRecords = records.where((r) => r.centerName == centerName).toList();
      
      int totalPresent = 0;
      int totalPossible = 0;
      
      for (var student in centerStudents) {
        final compositeKey = '${student.rollNo}_${student.classBatch}';
        for (var record in centerRecords) {
          if (record.attendance.containsKey(compositeKey)) {
            totalPossible++;
            if (record.attendance[compositeKey] == true) {
              totalPresent++;
            }
          }
        }
      }
      
      final attendanceRate = totalPossible > 0 ? (totalPresent / totalPossible) * 100 : 0.0;
      final sessionsHeld = centerRecords.length;
      
      centerComparison[centerName] = {
        'totalStudents': centerStudents.length,
        'attendanceRate': attendanceRate,
        'sessionsHeld': sessionsHeld,
        'totalPresent': totalPresent,
        'totalPossible': totalPossible,
        'averageStudentsPerSession': sessionsHeld > 0 ? totalPresent / sessionsHeld : 0.0,
      };
    });
    
    return centerComparison;
  }
  
  /// Compare student performance across centers
  static Map<String, Map<String, dynamic>> getCenterPerformanceComparison(
    List<Student> students,
    List<VolunteerReport> reports,
  ) {
    final Map<String, Map<String, dynamic>> centerPerformance = {};
    
    // Group students by center
    final Map<String, List<Student>> studentsByCenter = {};
    for (var student in students) {
      if (!studentsByCenter.containsKey(student.centerName)) {
        studentsByCenter[student.centerName] = [];
      }
      studentsByCenter[student.centerName]!.add(student);
    }
    
    studentsByCenter.forEach((centerName, centerStudents) {
      final centerReports = reports.where((r) => r.centerName == centerName).toList();
      
      // Calculate average test scores
      final List<double> allScores = [];
      int totalTests = 0;
      
      for (var student in centerStudents) {
        // From student test results
        student.testResults.forEach((topic, marks) {
          final score = _parseMarksToPercentage(marks);
          if (score != null) {
            allScores.add(score);
            totalTests++;
          }
        });
        
        // From volunteer reports
        for (var report in centerReports) {
          if (report.testConducted && report.testMarks.containsKey(student.id)) {
            final marks = report.testMarks[student.id]!;
            final score = _parseMarksToPercentage(marks);
            if (score != null) {
              allScores.add(score);
              totalTests++;
            }
          }
        }
      }
      
      final averageScore = allScores.isNotEmpty ? allScores.reduce((a, b) => a + b) / allScores.length : 0.0;
      final passCount = allScores.where((score) => score >= 50).length;
      final passRate = allScores.isNotEmpty ? (passCount / allScores.length) * 100 : 0.0;
      
      centerPerformance[centerName] = {
        'totalStudents': centerStudents.length,
        'averageScore': averageScore,
        'totalTests': totalTests,
        'passRate': passRate,
        'testsPerStudent': centerStudents.isNotEmpty ? totalTests / centerStudents.length : 0.0,
      };
    });
    
    return centerPerformance;
  }
  
  /// Analyze volunteer availability vs student strength per center
  static Map<String, Map<String, dynamic>> getCenterVolunteerAnalysis(
    List<Student> students,
    List<VolunteerReport> reports,
  ) {
    final Map<String, Map<String, dynamic>> centerAnalysis = {};
    
    // Group by center
    final Map<String, List<Student>> studentsByCenter = {};
    final Map<String, List<VolunteerReport>> reportsByCenter = {};
    
    for (var student in students) {
      if (!studentsByCenter.containsKey(student.centerName)) {
        studentsByCenter[student.centerName] = [];
      }
      studentsByCenter[student.centerName]!.add(student);
    }
    
    for (var report in reports) {
      if (!reportsByCenter.containsKey(report.centerName)) {
        reportsByCenter[report.centerName] = [];
      }
      reportsByCenter[report.centerName]!.add(report);
    }
    
    studentsByCenter.forEach((centerName, centerStudents) {
      final centerReports = reportsByCenter[centerName] ?? [];
      final uniqueVolunteers = centerReports.map((r) => r.volunteerName).toSet();
      final totalVolunteerHours = getTotalVolunteerHours(centerReports);
      
      centerAnalysis[centerName] = {
        'totalStudents': centerStudents.length,
        'uniqueVolunteers': uniqueVolunteers.length,
        'totalVolunteerHours': totalVolunteerHours,
        'studentToVolunteerRatio': uniqueVolunteers.isNotEmpty ? centerStudents.length / uniqueVolunteers.length : 0.0,
        'hoursPerStudent': centerStudents.isNotEmpty ? totalVolunteerHours / centerStudents.length : 0.0,
        'sessionsHeld': centerReports.length,
      };
    });
    
    return centerAnalysis;
  }
  
  /// Analyze class-wise performance per center
  static Map<String, Map<String, Map<String, dynamic>>> getCenterClassPerformance(
    List<Student> students,
    List<AttendanceRecord> records,
  ) {
    final Map<String, Map<String, Map<String, dynamic>>> centerClassPerformance = {};
    
    for (var student in students) {
      if (!centerClassPerformance.containsKey(student.centerName)) {
        centerClassPerformance[student.centerName] = {};
      }
      if (!centerClassPerformance[student.centerName]!.containsKey(student.classBatch)) {
        centerClassPerformance[student.centerName]![student.classBatch] = {
          'students': <Student>[],
          'totalPresent': 0,
          'totalPossible': 0,
        };
      }
      centerClassPerformance[student.centerName]![student.classBatch]!['students'].add(student);
    }
    
    // Calculate attendance for each center-class combination
    centerClassPerformance.forEach((centerName, classes) {
      final centerRecords = records.where((r) => r.centerName == centerName).toList();
      
      classes.forEach((className, classData) {
        final classStudents = classData['students'] as List<Student>;
        int totalPresent = 0;
        int totalPossible = 0;
        
        for (var student in classStudents) {
          final compositeKey = '${student.rollNo}_${student.classBatch}';
          for (var record in centerRecords) {
            if (record.attendance.containsKey(compositeKey)) {
              totalPossible++;
              if (record.attendance[compositeKey] == true) {
                totalPresent++;
              }
            }
          }
        }
        
        classData['totalPresent'] = totalPresent;
        classData['totalPossible'] = totalPossible;
        classData['attendanceRate'] = totalPossible > 0 ? (totalPresent / totalPossible) * 100 : 0.0;
        classData['studentCount'] = classStudents.length;
      });
    });
    
    return centerClassPerformance;
  }
  
  /// Calculate resource utilization (sessions conducted vs planned)
  static Map<String, Map<String, dynamic>> getCenterResourceUtilization(
    List<AttendanceRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    final Map<String, Map<String, dynamic>> utilization = {};
    
    // Calculate working days in the period (Monday to Friday)
    int workingDays = 0;
    DateTime current = startDate;
    while (current.isBefore(endDate.add(const Duration(days: 1)))) {
      if (current.weekday <= 5) { // Monday to Friday
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    // Group records by center
    final Map<String, List<AttendanceRecord>> recordsByCenter = {};
    for (var record in records) {
      if (!recordsByCenter.containsKey(record.centerName)) {
        recordsByCenter[record.centerName] = [];
      }
      recordsByCenter[record.centerName]!.add(record);
    }
    
    recordsByCenter.forEach((centerName, centerRecords) {
      final sessionsHeld = centerRecords.length;
      final utilizationRate = workingDays > 0 ? (sessionsHeld / workingDays) * 100 : 0.0;
      
      utilization[centerName] = {
        'plannedSessions': workingDays,
        'sessionsHeld': sessionsHeld,
        'utilizationRate': utilizationRate,
        'missedSessions': workingDays - sessionsHeld,
      };
    });
    
    return utilization;
  }
  
  /// Identify centers needing intervention
  static List<Map<String, dynamic>> getCentersNeedingIntervention(
    List<Student> students,
    List<AttendanceRecord> records,
    List<VolunteerReport> reports,
  ) {
    final interventions = <Map<String, dynamic>>[];
    
    final attendanceComparison = getCenterAttendanceComparison(students, records);
    final performanceComparison = getCenterPerformanceComparison(students, reports);
    final volunteerAnalysis = getCenterVolunteerAnalysis(students, reports);
    
    attendanceComparison.forEach((centerName, attendanceData) {
      final performanceData = performanceComparison[centerName] ?? {};
      final volunteerData = volunteerAnalysis[centerName] ?? {};
      
      final attendanceRate = attendanceData['attendanceRate'] as double? ?? 0.0;
      final averageScore = performanceData['averageScore'] as double? ?? 0.0;
      final studentToVolunteerRatio = volunteerData['studentToVolunteerRatio'] as double? ?? 0.0;
      
      final List<String> issues = [];
      String priority = 'Low';
      
      // Check for issues
      if (attendanceRate < 60) {
        issues.add('Critical attendance rate (${attendanceRate.toStringAsFixed(1)}%)');
        priority = 'High';
      } else if (attendanceRate < 75) {
        issues.add('Low attendance rate (${attendanceRate.toStringAsFixed(1)}%)');
        if (priority == 'Low') priority = 'Medium';
      }
      
      if (averageScore < 50) {
        issues.add('Poor academic performance (${averageScore.toStringAsFixed(1)}% avg)');
        priority = 'High';
      } else if (averageScore < 65) {
        issues.add('Below average performance (${averageScore.toStringAsFixed(1)}% avg)');
        if (priority == 'Low') priority = 'Medium';
      }
      
      if (studentToVolunteerRatio > 15) {
        issues.add('High student-to-volunteer ratio (${studentToVolunteerRatio.toStringAsFixed(1)}:1)');
        if (priority == 'Low') priority = 'Medium';
      }
      
      if (issues.isNotEmpty) {
        interventions.add({
          'centerName': centerName,
          'priority': priority,
          'issues': issues,
          'attendanceRate': attendanceRate,
          'averageScore': averageScore,
          'studentToVolunteerRatio': studentToVolunteerRatio,
          'totalStudents': attendanceData['totalStudents'],
        });
      }
    });
    
    // Sort by priority (High -> Medium -> Low) and then by severity
    interventions.sort((a, b) {
      const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final aPriority = priorityOrder[a['priority']]!;
      final bPriority = priorityOrder[b['priority']]!;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, sort by attendance rate (lower first)
      return (a['attendanceRate'] as double).compareTo(b['attendanceRate'] as double);
    });
    
    return interventions;
  }
  
  // ============================================================================
  // VOLUNTEER-LEVEL ANALYSIS
  // ============================================================================
  
  /// Analyze total hours contributed by each volunteer
  static Map<String, Map<String, dynamic>> getVolunteerContributionAnalysis(
    List<VolunteerReport> reports,
  ) {
    final Map<String, Map<String, dynamic>> volunteerAnalysis = {};
    
    for (var report in reports) {
      if (!volunteerAnalysis.containsKey(report.volunteerName)) {
        volunteerAnalysis[report.volunteerName] = {
          'totalHours': 0.0,
          'sessionsCount': 0,
          'centersWorked': <String>{},
          'subjectsTaught': <String>{},
          'studentsImpacted': <int>{},
          'testsGiven': 0,
        };
      }
      
      final data = volunteerAnalysis[report.volunteerName]!;
      
      // Calculate hours for this session
      try {
        final inTime = _parseTime(report.inTime);
        final outTime = _parseTime(report.outTime);
        
        if (inTime != null && outTime != null) {
          final duration = outTime.difference(inTime);
          data['totalHours'] = (data['totalHours'] as double) + (duration.inMinutes / 60.0);
        }
      } catch (e) {
        // Skip invalid time entries
      }
      
      data['sessionsCount'] = (data['sessionsCount'] as int) + 1;
      (data['centersWorked'] as Set<String>).add(report.centerName);
      
      // Extract subject from activity
      final subject = report.activityTaught.split('-').first.trim();
      (data['subjectsTaught'] as Set<String>).add(subject);
      
      // Add impacted students
      (data['studentsImpacted'] as Set<int>).addAll(report.selectedStudents);
      
      if (report.testConducted) {
        data['testsGiven'] = (data['testsGiven'] as int) + 1;
      }
    }
    
    // Convert sets to counts and calculate derived metrics
    volunteerAnalysis.forEach((volunteerName, data) {
      data['centersCount'] = (data['centersWorked'] as Set<String>).length;
      data['subjectsCount'] = (data['subjectsTaught'] as Set<String>).length;
      data['studentsImpactedCount'] = (data['studentsImpacted'] as Set<int>).length;
      data['averageHoursPerSession'] = (data['sessionsCount'] as int) > 0 
          ? (data['totalHours'] as double) / (data['sessionsCount'] as int) 
          : 0.0;
      data['testFrequency'] = (data['sessionsCount'] as int) > 0 
          ? ((data['testsGiven'] as int) / (data['sessionsCount'] as int)) * 100 
          : 0.0;
    });
    
    return volunteerAnalysis;
  }
  
  /// Analyze sessions conducted per volunteer
  static Map<String, List<Map<String, dynamic>>> getVolunteerSessionAnalysis(
    List<VolunteerReport> reports,
  ) {
    final Map<String, List<Map<String, dynamic>>> volunteerSessions = {};
    
    for (var report in reports) {
      if (!volunteerSessions.containsKey(report.volunteerName)) {
        volunteerSessions[report.volunteerName] = [];
      }
      
      volunteerSessions[report.volunteerName]!.add({
        'date': DateTime.fromMillisecondsSinceEpoch(report.id),
        'centerName': report.centerName,
        'classBatch': report.classBatch,
        'activityTaught': report.activityTaught,
        'studentsCount': report.selectedStudents.length,
        'testConducted': report.testConducted,
        'duration': _calculateSessionDuration(report.inTime, report.outTime),
      });
    }
    
    // Sort sessions by date for each volunteer
    volunteerSessions.forEach((volunteerName, sessions) {
      sessions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    });
    
    return volunteerSessions;
  }
  
  /// Analyze subjects taught distribution per volunteer
  static Map<String, Map<String, int>> getVolunteerSubjectDistribution(
    List<VolunteerReport> reports,
  ) {
    final Map<String, Map<String, int>> distribution = {};
    
    for (var report in reports) {
      if (!distribution.containsKey(report.volunteerName)) {
        distribution[report.volunteerName] = {};
      }
      
      final subject = report.activityTaught.split('-').first.trim();
      distribution[report.volunteerName]![subject] = 
          (distribution[report.volunteerName]![subject] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  /// Calculate average student improvement under each volunteer
  static Map<String, Map<String, dynamic>> getVolunteerImpactAnalysis(
    List<Student> students,
    List<VolunteerReport> reports,
  ) {
    final Map<String, Map<String, dynamic>> volunteerImpact = {};
    
    for (var report in reports) {
      if (!volunteerImpact.containsKey(report.volunteerName)) {
        volunteerImpact[report.volunteerName] = {
          'studentsImpacted': <int>{},
          'totalTestScores': <double>[],
          'testsGiven': 0,
          'averageScore': 0.0,
          'improvementRate': 0.0,
        };
      }
      
      final data = volunteerImpact[report.volunteerName]!;
      (data['studentsImpacted'] as Set<int>).addAll(report.selectedStudents);
      
      if (report.testConducted) {
        data['testsGiven'] = (data['testsGiven'] as int) + 1;
        
        // Collect test scores from this volunteer's tests
        report.testMarks.forEach((studentId, marks) {
          final score = _parseMarksToPercentage(marks);
          if (score != null) {
            (data['totalTestScores'] as List<double>).add(score);
          }
        });
      }
    }
    
    // Calculate derived metrics
    volunteerImpact.forEach((volunteerName, data) {
      final scores = data['totalTestScores'] as List<double>;
      data['studentsImpactedCount'] = (data['studentsImpacted'] as Set<int>).length;
      data['averageScore'] = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
      data['passRate'] = scores.isNotEmpty ? (scores.where((s) => s >= 50).length / scores.length) * 100 : 0.0;
    });
    
    return volunteerImpact;
  }
  
  /// Analyze volunteer consistency (dropout risk)
  static Map<String, Map<String, dynamic>> getVolunteerConsistencyAnalysis(
    List<VolunteerReport> reports,
    DateTime analysisStartDate,
  ) {
    final Map<String, Map<String, dynamic>> consistency = {};
    
    // Group reports by volunteer and sort by date
    final Map<String, List<VolunteerReport>> reportsByVolunteer = {};
    for (var report in reports) {
      if (!reportsByVolunteer.containsKey(report.volunteerName)) {
        reportsByVolunteer[report.volunteerName] = [];
      }
      reportsByVolunteer[report.volunteerName]!.add(report);
    }
    
    reportsByVolunteer.forEach((volunteerName, volunteerReports) {
      volunteerReports.sort((a, b) => a.id.compareTo(b.id)); // Sort by date
      
      // Calculate gaps between sessions
      final List<int> gapDays = [];
      for (int i = 1; i < volunteerReports.length; i++) {
        final prevDate = DateTime.fromMillisecondsSinceEpoch(volunteerReports[i - 1].id);
        final currentDate = DateTime.fromMillisecondsSinceEpoch(volunteerReports[i].id);
        final gap = currentDate.difference(prevDate).inDays;
        gapDays.add(gap);
      }
      
      // Calculate consistency metrics
      final averageGap = gapDays.isNotEmpty ? gapDays.reduce((a, b) => a + b) / gapDays.length : 0.0;
      final maxGap = gapDays.isNotEmpty ? gapDays.reduce(math.max) : 0;
      final lastSessionDate = volunteerReports.isNotEmpty 
          ? DateTime.fromMillisecondsSinceEpoch(volunteerReports.last.id)
          : analysisStartDate;
      final daysSinceLastSession = DateTime.now().difference(lastSessionDate).inDays;
      
      // Determine risk level
      String riskLevel = 'Low';
      if (daysSinceLastSession > 30 || maxGap > 21) {
        riskLevel = 'High';
      } else if (daysSinceLastSession > 14 || maxGap > 14) {
        riskLevel = 'Medium';
      }
      
      consistency[volunteerName] = {
        'totalSessions': volunteerReports.length,
        'averageGapDays': averageGap,
        'maxGapDays': maxGap,
        'daysSinceLastSession': daysSinceLastSession,
        'riskLevel': riskLevel,
        'isActive': daysSinceLastSession <= 7,
        'lastSessionDate': lastSessionDate,
      };
    });
    
    return consistency;
  }
  
  /// Identify volunteers creating the most impact
  static List<Map<String, dynamic>> getTopImpactVolunteers(
    List<Student> students,
    List<VolunteerReport> reports,
    {int limit = 10}
  ) {
    final contributionAnalysis = getVolunteerContributionAnalysis(reports);
    final impactAnalysis = getVolunteerImpactAnalysis(students, reports);
    
    final List<Map<String, dynamic>> topVolunteers = [];
    
    contributionAnalysis.forEach((volunteerName, contributionData) {
      final impactData = impactAnalysis[volunteerName] ?? {};
      
      // Calculate impact score (weighted combination of metrics)
      final totalHours = contributionData['totalHours'] as double;
      final studentsImpacted = contributionData['studentsImpactedCount'] as int;
      final averageScore = impactData['averageScore'] as double? ?? 0.0;
      final passRate = impactData['passRate'] as double? ?? 0.0;
      final testsGiven = contributionData['testsGiven'] as int;
      
      // Impact score calculation (0-100)
      final impactScore = (
        (totalHours * 0.2) + // Hours contribution (20%)
        (studentsImpacted * 2.0) + // Students impacted (40% - 2 points per student)
        (averageScore * 0.2) + // Academic results (20%)
        (passRate * 0.1) + // Pass rate (10%)
        (testsGiven * 1.0) // Assessment frequency (10% - 1 point per test)
      ).clamp(0.0, 100.0);
      
      topVolunteers.add({
        'volunteerName': volunteerName,
        'impactScore': impactScore,
        'totalHours': totalHours,
        'studentsImpacted': studentsImpacted,
        'averageScore': averageScore,
        'passRate': passRate,
        'testsGiven': testsGiven,
        'sessionsCount': contributionData['sessionsCount'],
        'centersCount': contributionData['centersCount'],
        'subjectsCount': contributionData['subjectsCount'],
      });
    });
    
    // Sort by impact score (highest first)
    topVolunteers.sort((a, b) => (b['impactScore'] as double).compareTo(a['impactScore'] as double));
    
    return topVolunteers.take(limit).toList();
  }
  
  // ============================================================================
  // DIAGNOSTIC ANALYTICS
  // ============================================================================
  
  /// Analyze attendance drop patterns
  static Map<String, dynamic> getAttendanceDropAnalysis(
    List<Student> students,
    List<AttendanceRecord> records,
    List<VolunteerReport> reports,
  ) {
    // Attendance vs Day of Week
    final Map<int, List<double>> dayWiseAttendance = {};
    final Map<int, int> dayWiseTotal = {};
    
    for (var record in records) {
      final dayOfWeek = record.date.weekday;
      final presentCount = record.attendance.values.where((v) => v == true).length;
      final totalCount = record.attendance.length;
      
      if (totalCount > 0) {
        final percentage = (presentCount / totalCount) * 100;
        
        if (!dayWiseAttendance.containsKey(dayOfWeek)) {
          dayWiseAttendance[dayOfWeek] = [];
          dayWiseTotal[dayOfWeek] = 0;
        }
        
        dayWiseAttendance[dayOfWeek]!.add(percentage);
        dayWiseTotal[dayOfWeek] = dayWiseTotal[dayOfWeek]! + 1;
      }
    }
    
    // Calculate averages
    final Map<String, double> dayWiseAverages = {};
    dayWiseAttendance.forEach((day, percentages) {
      final dayName = _getDayName(day);
      dayWiseAverages[dayName] = percentages.reduce((a, b) => a + b) / percentages.length;
    });
    
    // Attendance vs Volunteer Presence
    final Map<String, List<double>> volunteerPresenceImpact = {};
    
    for (var record in records) {
      // Check if any volunteer was present on this day
      final dayReports = reports.where((r) => 
        DateTime.fromMillisecondsSinceEpoch(r.id).day == record.date.day &&
        DateTime.fromMillisecondsSinceEpoch(r.id).month == record.date.month &&
        DateTime.fromMillisecondsSinceEpoch(r.id).year == record.date.year
      ).toList();
      
      final hasVolunteer = dayReports.isNotEmpty;
      final presentCount = record.attendance.values.where((v) => v == true).length;
      final totalCount = record.attendance.length;
      
      if (totalCount > 0) {
        final percentage = (presentCount / totalCount) * 100;
        final key = hasVolunteer ? 'With Volunteer' : 'Without Volunteer';
        
        if (!volunteerPresenceImpact.containsKey(key)) {
          volunteerPresenceImpact[key] = [];
        }
        volunteerPresenceImpact[key]!.add(percentage);
      }
    }
    
    // Calculate volunteer presence impact
    final Map<String, double> volunteerImpactAverages = {};
    volunteerPresenceImpact.forEach((key, percentages) {
      volunteerImpactAverages[key] = percentages.reduce((a, b) => a + b) / percentages.length;
    });
    
    // Identify high-absence students
    final List<Map<String, dynamic>> highAbsenceStudents = [];
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      int totalDays = 0;
      int presentDays = 0;
      
      for (var record in records) {
        if (record.attendance.containsKey(compositeKey)) {
          totalDays++;
          if (record.attendance[compositeKey] == true) {
            presentDays++;
          }
        }
      }
      
      if (totalDays > 0) {
        final attendanceRate = (presentDays / totalDays) * 100;
        if (attendanceRate < 60) { // High absence threshold
          highAbsenceStudents.add({
            'student': student,
            'attendanceRate': attendanceRate,
            'totalDays': totalDays,
            'presentDays': presentDays,
            'absentDays': totalDays - presentDays,
          });
        }
      }
    }
    
    // Sort by attendance rate (lowest first)
    highAbsenceStudents.sort((a, b) => 
        (a['attendanceRate'] as double).compareTo(b['attendanceRate'] as double));
    
    return {
      'dayWiseAttendance': dayWiseAverages,
      'volunteerPresenceImpact': volunteerImpactAverages,
      'highAbsenceStudents': highAbsenceStudents,
      'insights': _generateAttendanceDropInsights(dayWiseAverages, volunteerImpactAverages, highAbsenceStudents),
    };
  }
  
  /// Analyze learning outcome diagnosis
  static Map<String, dynamic> getLearningOutcomeDiagnosis(
    List<Student> students,
    List<AttendanceRecord> records,
    List<VolunteerReport> reports,
  ) {
    // Performance vs Attendance Correlation
    final List<Map<String, dynamic>> studentCorrelations = [];
    
    for (var student in students) {
      final compositeKey = '${student.rollNo}_${student.classBatch}';
      
      // Calculate attendance rate
      int totalDays = 0;
      int presentDays = 0;
      
      for (var record in records) {
        if (record.attendance.containsKey(compositeKey)) {
          totalDays++;
          if (record.attendance[compositeKey] == true) {
            presentDays++;
          }
        }
      }
      
      final attendanceRate = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
      
      // Calculate average test score
      final List<double> testScores = [];
      
      // From student test results
      student.testResults.forEach((topic, marks) {
        final score = _parseMarksToPercentage(marks);
        if (score != null) {
          testScores.add(score);
        }
      });
      
      // From volunteer reports
      for (var report in reports) {
        if (report.testConducted && report.testMarks.containsKey(student.id)) {
          final marks = report.testMarks[student.id]!;
          final score = _parseMarksToPercentage(marks);
          if (score != null) {
            testScores.add(score);
          }
        }
      }
      
      if (testScores.isNotEmpty && totalDays > 0) {
        final averageScore = testScores.reduce((a, b) => a + b) / testScores.length;
        
        studentCorrelations.add({
          'student': student,
          'attendanceRate': attendanceRate,
          'averageScore': averageScore,
          'testCount': testScores.length,
        });
      }
    }
    
    // Subject-wise difficulty analysis
    final Map<String, List<double>> subjectScores = {};
    
    for (var student in students) {
      student.testResults.forEach((testTopic, marks) {
        String subject = 'General';
        if (testTopic.contains(':')) {
          subject = testTopic.split(':')[0].trim();
        }
        
        final score = _parseMarksToPercentage(marks);
        if (score != null) {
          if (!subjectScores.containsKey(subject)) {
            subjectScores[subject] = [];
          }
          subjectScores[subject]!.add(score);
        }
      });
    }
    
    // Calculate subject difficulty (lower average = more difficult)
    final Map<String, Map<String, dynamic>> subjectDifficulty = {};
    subjectScores.forEach((subject, scores) {
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;
      final passRate = (scores.where((s) => s >= 50).length / scores.length) * 100;
      final failureRate = 100 - passRate;
      
      String difficultyLevel = 'Easy';
      if (averageScore < 50) {
        difficultyLevel = 'Very Hard';
      } else if (averageScore < 65) {
        difficultyLevel = 'Hard';
      } else if (averageScore < 75) {
        difficultyLevel = 'Medium';
      }
      
      subjectDifficulty[subject] = {
        'averageScore': averageScore,
        'passRate': passRate,
        'failureRate': failureRate,
        'difficultyLevel': difficultyLevel,
        'totalTests': scores.length,
      };
    });
    
    // Calculate correlation coefficient between attendance and performance
    double correlationCoefficient = 0.0;
    if (studentCorrelations.length > 1) {
      final attendanceRates = studentCorrelations.map((s) => s['attendanceRate'] as double).toList();
      final averageScores = studentCorrelations.map((s) => s['averageScore'] as double).toList();
      
      correlationCoefficient = _calculateCorrelation(attendanceRates, averageScores);
    }
    
    return {
      'performanceAttendanceCorrelation': correlationCoefficient,
      'studentCorrelations': studentCorrelations,
      'subjectDifficulty': subjectDifficulty,
      'insights': _generateLearningOutcomeInsights(correlationCoefficient, subjectDifficulty, studentCorrelations),
    };
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Helper method to parse marks to percentage
  static double? parseMarksToPercentage(String marks) {
    return _parseMarksToPercentage(marks);
  }

  /// Helper method to parse time string
  static DateTime? parseTime(String timeStr) {
    return _parseTime(timeStr);
  }

  /// Helper method to get day name
  static String getDayName(int weekday) {
    return _getDayName(weekday);
  }

  /// Helper method to parse marks to percentage
  static double? _parseMarksToPercentage(String marks) {
    if (marks.contains('/')) {
      // Format: "8/10" or "15/20"
      final parts = marks.split('/');
      if (parts.length == 2) {
        final obtained = double.tryParse(parts[0].trim());
        final total = double.tryParse(parts[1].trim());
        if (obtained != null && total != null && total > 0) {
          return (obtained / total) * 100;
        }
      }
    } else {
      // Try direct numeric parse (assume it's already a percentage)
      return double.tryParse(marks);
    }
    return null;
  }
  
  /// Calculate session duration in hours
  static double _calculateSessionDuration(String inTime, String outTime) {
    try {
      final inDateTime = _parseTime(inTime);
      final outDateTime = _parseTime(outTime);
      
      if (inDateTime != null && outDateTime != null) {
        final duration = outDateTime.difference(inDateTime);
        return duration.inMinutes / 60.0;
      }
    } catch (e) {
      // Invalid time format
    }
    return 0.0;
  }
  
  /// Generate attendance drop insights
  static List<String> _generateAttendanceDropInsights(
    Map<String, double> dayWiseAverages,
    Map<String, double> volunteerImpactAverages,
    List<Map<String, dynamic>> highAbsenceStudents,
  ) {
    final insights = <String>[];
    
    // Day-wise insights
    if (dayWiseAverages.isNotEmpty) {
      final sortedDays = dayWiseAverages.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final worstDay = sortedDays.first;
      final bestDay = sortedDays.last;
      
      insights.add('${worstDay.key} has the lowest attendance (${worstDay.value.toStringAsFixed(1)}%)');
      insights.add('${bestDay.key} has the highest attendance (${bestDay.value.toStringAsFixed(1)}%)');
    }
    
    // Volunteer presence impact
    if (volunteerImpactAverages.containsKey('With Volunteer') && 
        volunteerImpactAverages.containsKey('Without Volunteer')) {
      final withVolunteer = volunteerImpactAverages['With Volunteer']!;
      final withoutVolunteer = volunteerImpactAverages['Without Volunteer']!;
      final difference = withVolunteer - withoutVolunteer;
      
      if (difference > 5) {
        insights.add('Volunteer presence increases attendance by ${difference.toStringAsFixed(1)}%');
      }
    }
    
    // High absence students
    if (highAbsenceStudents.isNotEmpty) {
      insights.add('${highAbsenceStudents.length} students have critical attendance issues (<60%)');
    }
    
    return insights;
  }
  
  /// Generate learning outcome insights
  static List<String> _generateLearningOutcomeInsights(
    double correlationCoefficient,
    Map<String, Map<String, dynamic>> subjectDifficulty,
    List<Map<String, dynamic>> studentCorrelations,
  ) {
    final insights = <String>[];
    
    // Correlation insight
    if (correlationCoefficient > 0.5) {
      insights.add('Strong positive correlation between attendance and performance (${(correlationCoefficient * 100).toStringAsFixed(0)}%)');
    } else if (correlationCoefficient > 0.3) {
      insights.add('Moderate correlation between attendance and performance (${(correlationCoefficient * 100).toStringAsFixed(0)}%)');
    } else {
      insights.add('Weak correlation between attendance and performance - other factors may be more important');
    }
    
    // Subject difficulty insights
    if (subjectDifficulty.isNotEmpty) {
      final hardestSubject = subjectDifficulty.entries
          .reduce((a, b) => (a.value['averageScore'] as double) < (b.value['averageScore'] as double) ? a : b);
      
      final easiestSubject = subjectDifficulty.entries
          .reduce((a, b) => (a.value['averageScore'] as double) > (b.value['averageScore'] as double) ? a : b);
      
      insights.add('${hardestSubject.key} is the most challenging subject (${(hardestSubject.value['averageScore'] as double).toStringAsFixed(1)}% avg)');
      insights.add('${easiestSubject.key} shows best performance (${(easiestSubject.value['averageScore'] as double).toStringAsFixed(1)}% avg)');
    }
    
    // Low attendance impact
    final lowAttendanceStudents = studentCorrelations.where((s) => (s['attendanceRate'] as double) < 60).toList();
    final highAttendanceStudents = studentCorrelations.where((s) => (s['attendanceRate'] as double) >= 80).toList();
    
    if (lowAttendanceStudents.isNotEmpty && highAttendanceStudents.isNotEmpty) {
      final lowAttendanceAvgScore = lowAttendanceStudents
          .map((s) => s['averageScore'] as double)
          .reduce((a, b) => a + b) / lowAttendanceStudents.length;
      
      final highAttendanceAvgScore = highAttendanceStudents
          .map((s) => s['averageScore'] as double)
          .reduce((a, b) => a + b) / highAttendanceStudents.length;
      
      final scoreDifference = highAttendanceAvgScore - lowAttendanceAvgScore;
      
      if (scoreDifference > 10) {
        insights.add('Students with <60% attendance score ${scoreDifference.toStringAsFixed(1)}% lower than those with >80% attendance');
      }
    }
    
    return insights;
  }
  
  /// Calculate correlation coefficient between two lists
  static double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double sumXSquared = 0.0;
    double sumYSquared = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = x[i] - meanX;
      final yDiff = y[i] - meanY;
      
      numerator += xDiff * yDiff;
      sumXSquared += xDiff * xDiff;
      sumYSquared += yDiff * yDiff;
    }
    
    final denominator = math.sqrt(sumXSquared * sumYSquared);
    
    return denominator != 0 ? numerator / denominator : 0.0;
  }
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
