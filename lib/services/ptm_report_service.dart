// PTM Report Service - Calculates Subject Performance Score (SPS)
// Formula: SPS = (0.6 × UnderstandingScore) + (0.4 × TestScore)

import 'package:samadhan_app/models/ptm_report.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/data/subjects_topics.dart';

class PTMReportService {
  // Weights for SPS calculation
  static const double understandingWeight = 0.6; // 60%
  static const double testWeight = 0.4; // 40%

  // Evaluation level to numeric value mapping
  static const Map<EvaluationLevel, double> evaluationValues = {
    EvaluationLevel.good: 1.0,
    EvaluationLevel.average: 0.6,
    EvaluationLevel.poor: 0.2, // Not 0 - even poor means some exposure
  };

  /// Generate PTM report for a student
  static List<SubjectPerformance> generateReport(Student student) {
    final performances = <SubjectPerformance>[];

    for (final subject in SubjectsTopics.subjects) {
      final performance = _calculateSubjectPerformance(student, subject);
      if (performance != null) {
        performances.add(performance);
      }
    }

    // Sort by SPS descending (best subjects first)
    performances.sort((a, b) => b.sps.compareTo(a.sps));

    return performances;
  }

  /// Calculate performance for a single subject
  static SubjectPerformance? _calculateSubjectPerformance(
    Student student,
    String subject,
  ) {
    // Get understanding data from TopicEvaluations
    final understandingData = _calculateUnderstandingScore(student, subject);
    
    // Get test data from testResults
    final testData = _calculateTestScore(student, subject);

    // Skip if no data at all
    if (!understandingData.hasData && !testData.hasData) {
      return null;
    }

    // Calculate SPS based on available data
    double sps;
    if (understandingData.hasData && testData.hasData) {
      // Both available - use weighted formula
      sps = (understandingWeight * understandingData.score) +
          (testWeight * testData.score);
    } else if (understandingData.hasData) {
      // Only understanding - use 100% weight
      sps = understandingData.score;
    } else {
      // Only tests - use 100% weight
      sps = testData.score;
    }

    final grade = PTMGradeExtension.fromScore(sps);
    final remark = _generateRemark(subject, grade, understandingData, testData);

    return SubjectPerformance(
      subject: subject,
      understandingScore: understandingData.score,
      testScore: testData.score,
      sps: sps,
      grade: grade,
      topicsEvaluated: understandingData.count,
      testsTaken: testData.count,
      hasUnderstandingData: understandingData.hasData,
      hasTestData: testData.hasData,
      remark: remark,
    );
  }


  /// Calculate understanding score from TopicEvaluations
  static _ScoreData _calculateUnderstandingScore(Student student, String subject) {
    final evaluations = student.topicEvaluations.values
        .where((e) => e.subject == subject)
        .toList();

    if (evaluations.isEmpty) {
      return _ScoreData(score: 0, count: 0, hasData: false);
    }

    double totalValue = 0;
    for (final eval in evaluations) {
      totalValue += evaluationValues[eval.evaluation] ?? 0.6;
    }

    final score = (totalValue / evaluations.length) * 100;
    return _ScoreData(score: score, count: evaluations.length, hasData: true);
  }

  /// Calculate test score from testResults
  /// Format: "Subject: Topic" -> "marks/maxMarks"
  static _ScoreData _calculateTestScore(Student student, String subject) {
    final testEntries = <double>[];

    student.testResults.forEach((testTopic, marks) {
      // Parse subject from test topic (format: "Subject: Topic")
      String testSubject = 'General';
      if (testTopic.contains(':')) {
        testSubject = testTopic.split(':')[0].trim();
      }

      if (testSubject == subject) {
        final percentage = _parseMarksToPercentage(marks);
        if (percentage != null) {
          testEntries.add(percentage);
        }
      }
    });

    if (testEntries.isEmpty) {
      return _ScoreData(score: 0, count: 0, hasData: false);
    }

    final avgScore = testEntries.reduce((a, b) => a + b) / testEntries.length;
    return _ScoreData(score: avgScore, count: testEntries.length, hasData: true);
  }

  /// Parse marks string to percentage
  /// Supports formats: "8/10", "15/20", "85%", "85"
  static double? _parseMarksToPercentage(String marks) {
    if (marks.contains('/')) {
      final parts = marks.split('/');
      if (parts.length == 2) {
        final obtained = double.tryParse(parts[0].trim());
        final max = double.tryParse(parts[1].trim());
        if (obtained != null && max != null && max > 0) {
          return (obtained / max) * 100;
        }
      }
    } else if (marks.contains('%')) {
      return double.tryParse(marks.replaceAll('%', '').trim());
    } else {
      // Assume it's a percentage if just a number
      return double.tryParse(marks.trim());
    }
    return null;
  }

  /// Generate teacher remark based on performance
  static String _generateRemark(
    String subject,
    PTMGrade grade,
    _ScoreData understanding,
    _ScoreData test,
  ) {
    switch (grade) {
      case PTMGrade.A:
        return 'Excellent understanding and performance in $subject. Keep up the great work!';
      case PTMGrade.B:
        if (understanding.hasData && test.hasData) {
          if (understanding.score > test.score) {
            return 'Good understanding of concepts. More practice in tests will help.';
          } else {
            return 'Good test performance. Continue building conceptual clarity.';
          }
        }
        return 'Good progress in $subject. Consistent effort will lead to excellence.';
      case PTMGrade.C:
        if (understanding.hasData && understanding.score < 60) {
          return 'Needs more focus on understanding basic concepts in $subject.';
        }
        return 'Needs improvement in $subject. Regular practice recommended.';
      case PTMGrade.D:
        return 'Requires additional support in $subject. Please discuss with teacher.';
    }
  }

  /// Get overall performance summary
  static PTMSummary getOverallSummary(List<SubjectPerformance> performances) {
    if (performances.isEmpty) {
      return PTMSummary(
        overallScore: 0,
        overallGrade: PTMGrade.D,
        strongSubjects: [],
        needsImprovementSubjects: [],
        totalSubjects: 0,
      );
    }

    final totalSPS = performances.map((p) => p.sps).reduce((a, b) => a + b);
    final overallScore = totalSPS / performances.length;
    final overallGrade = PTMGradeExtension.fromScore(overallScore);

    final strongSubjects = performances
        .where((p) => p.grade == PTMGrade.A || p.grade == PTMGrade.B)
        .map((p) => p.subject)
        .toList();

    final needsImprovementSubjects = performances
        .where((p) => p.grade == PTMGrade.C || p.grade == PTMGrade.D)
        .map((p) => p.subject)
        .toList();

    return PTMSummary(
      overallScore: overallScore,
      overallGrade: overallGrade,
      strongSubjects: strongSubjects,
      needsImprovementSubjects: needsImprovementSubjects,
      totalSubjects: performances.length,
    );
  }
}

/// Helper class for score calculation
class _ScoreData {
  final double score;
  final int count;
  final bool hasData;

  _ScoreData({
    required this.score,
    required this.count,
    required this.hasData,
  });
}

/// Overall PTM summary
class PTMSummary {
  final double overallScore;
  final PTMGrade overallGrade;
  final List<String> strongSubjects;
  final List<String> needsImprovementSubjects;
  final int totalSubjects;

  PTMSummary({
    required this.overallScore,
    required this.overallGrade,
    required this.strongSubjects,
    required this.needsImprovementSubjects,
    required this.totalSubjects,
  });
}
