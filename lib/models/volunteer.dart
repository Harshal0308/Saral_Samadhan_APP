class Volunteer {
  final int id;
  final String name;
  final String centerName;
  final int attendanceCount;
  final DateTime firstReportDate;
  final DateTime lastReportDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Volunteer({
    required this.id,
    required this.name,
    required this.centerName,
    required this.attendanceCount,
    required this.firstReportDate,
    required this.lastReportDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Volunteer.fromMap(Map<String, dynamic> map) {
    return Volunteer(
      id: map['id'] as int,
      name: map['name'] as String,
      centerName: map['center_name'] as String,
      attendanceCount: map['attendance_count'] as int,
      firstReportDate: DateTime.parse(map['first_report_date'] as String),
      lastReportDate: DateTime.parse(map['last_report_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'center_name': centerName,
      'attendance_count': attendanceCount,
      'first_report_date': firstReportDate.toIso8601String().split('T')[0],
      'last_report_date': lastReportDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VolunteerSuggestion {
  final String name;
  final int attendanceCount;
  final DateTime lastReportDate;

  VolunteerSuggestion({
    required this.name,
    required this.attendanceCount,
    required this.lastReportDate,
  });

  factory VolunteerSuggestion.fromMap(Map<String, dynamic> map) {
    return VolunteerSuggestion(
      name: map['volunteer_name'] as String,
      attendanceCount: map['attendance_count'] as int,
      lastReportDate: DateTime.parse(map['last_report_date'] as String),
    );
  }
}

class MonthlyVolunteerReport {
  final String volunteerName;
  final int attendanceCount;
  final DateTime firstReportDate;
  final DateTime lastReportDate;
  final int daysActive;

  MonthlyVolunteerReport({
    required this.volunteerName,
    required this.attendanceCount,
    required this.firstReportDate,
    required this.lastReportDate,
    required this.daysActive,
  });

  factory MonthlyVolunteerReport.fromMap(Map<String, dynamic> map) {
    return MonthlyVolunteerReport(
      volunteerName: map['volunteer_name'] as String,
      attendanceCount: map['attendance_count'] as int,
      firstReportDate: DateTime.parse(map['first_report_date'] as String),
      lastReportDate: DateTime.parse(map['last_report_date'] as String),
      daysActive: map['days_active'] as int,
    );
  }
}