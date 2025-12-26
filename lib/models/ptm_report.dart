// PTM (Parent-Teacher Meeting) Report Models
// Based on Subject Performance Score (SPS) calculation

import 'package:flutter/material.dart';

/// Grade based on SPS score
enum PTMGrade {
  A, // 85-100: Excellent
  B, // 70-84: Good
  C, // 50-69: Needs Improvement
  D, // <50: Needs Support
}

extension PTMGradeExtension on PTMGrade {
  String get displayName {
    switch (this) {
      case PTMGrade.A:
        return 'Excellent';
      case PTMGrade.B:
        return 'Good';
      case PTMGrade.C:
        return 'Needs Improvement';
      case PTMGrade.D:
        return 'Needs Support';
    }
  }

  String get letter {
    switch (this) {
      case PTMGrade.A:
        return 'A';
      case PTMGrade.B:
        return 'B';
      case PTMGrade.C:
        return 'C';
      case PTMGrade.D:
        return 'D';
    }
  }

  Color get color {
    switch (this) {
      case PTMGrade.A:
        return Colors.green;
      case PTMGrade.B:
        return Colors.green.shade300;
      case PTMGrade.C:
        return Colors.orange;
      case PTMGrade.D:
        return Colors.red;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PTMGrade.A:
        return Colors.green.shade50;
      case PTMGrade.B:
        return Colors.green.shade50;
      case PTMGrade.C:
        return Colors.orange.shade50;
      case PTMGrade.D:
        return Colors.red.shade50;
    }
  }

  int get starRating {
    switch (this) {
      case PTMGrade.A:
        return 5;
      case PTMGrade.B:
        return 4;
      case PTMGrade.C:
        return 3;
      case PTMGrade.D:
        return 2;
    }
  }

  static PTMGrade fromScore(double score) {
    if (score >= 85) return PTMGrade.A;
    if (score >= 70) return PTMGrade.B;
    if (score >= 50) return PTMGrade.C;
    return PTMGrade.D;
  }
}

/// Subject-wise performance data for PTM report
class SubjectPerformance {
  final String subject;
  final double understandingScore; // 0-100
  final double testScore; // 0-100
  final double sps; // Subject Performance Score (0-100)
  final PTMGrade grade;
  final int topicsEvaluated;
  final int testsTaken;
  final bool hasUnderstandingData;
  final bool hasTestData;
  final String remark;

  SubjectPerformance({
    required this.subject,
    required this.understandingScore,
    required this.testScore,
    required this.sps,
    required this.grade,
    required this.topicsEvaluated,
    required this.testsTaken,
    required this.hasUnderstandingData,
    required this.hasTestData,
    required this.remark,
  });

  /// Get understanding stars (out of 5)
  int get understandingStars {
    if (!hasUnderstandingData) return 0;
    if (understandingScore >= 90) return 5;
    if (understandingScore >= 75) return 4;
    if (understandingScore >= 60) return 3;
    if (understandingScore >= 40) return 2;
    return 1;
  }

  /// Get data source description for parents
  String get dataSourceNote {
    if (hasUnderstandingData && hasTestData) {
      return 'Based on classroom understanding and test performance';
    } else if (hasUnderstandingData) {
      return 'Based on classroom understanding (no test conducted yet)';
    } else if (hasTestData) {
      return 'Based on test performance only';
    }
    return 'No data available';
  }
}
