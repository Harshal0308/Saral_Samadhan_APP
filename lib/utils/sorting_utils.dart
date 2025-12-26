import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/schedule_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';

/// Utility class for consistent sorting across the application
/// Ensures all data is displayed in ascending order
class SortingUtils {
  /// Sort students by class (1, 2, 3...), then by roll number (1, 2, 3...), then by name (A-Z)
  /// Use this when class is the primary display criteria
  static List<Student> sortStudents(List<Student> students) {
    final sortedList = List<Student>.from(students);
    sortedList.sort((a, b) {
      // First sort by class batch (1, 2, 3, 4, 5...)
      final classComparison = _compareClassBatch(a.classBatch, b.classBatch);
      if (classComparison != 0) return classComparison;
      
      // Then by roll number (1, 2, 3, 4, 5...)
      final rollComparison = _compareRollNumber(a.rollNo, b.rollNo);
      if (rollComparison != 0) return rollComparison;
      
      // Finally by name (A-Z)
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sortedList;
  }
  
  /// Sort students by name (A-Z), then by class (1, 2, 3...), then by roll number (1, 2, 3...)
  /// Use this when name is the primary display criteria
  static List<Student> sortStudentsByName(List<Student> students) {
    final sortedList = List<Student>.from(students);
    sortedList.sort((a, b) {
      // First sort by name (A-Z)
      final nameComparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (nameComparison != 0) return nameComparison;
      
      // Then by class batch (1, 2, 3, 4, 5...)
      final classComparison = _compareClassBatch(a.classBatch, b.classBatch);
      if (classComparison != 0) return classComparison;
      
      // Finally by roll number (1, 2, 3, 4, 5...)
      return _compareRollNumber(a.rollNo, b.rollNo);
    });
    return sortedList;
  }
  
  /// Sort class batches in ascending order (1, 2, 3, etc.)
  static List<String> sortClassBatches(List<String> classBatches) {
    final sortedList = List<String>.from(classBatches);
    sortedList.sort((a, b) => _compareClassBatch(a, b));
    return sortedList;
  }
  
  /// Sort names in ascending alphabetical order
  static List<String> sortNames(List<String> names) {
    final sortedList = List<String>.from(names);
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }
  
  /// Sort subjects in ascending alphabetical order
  static List<String> sortSubjects(List<String> subjects) {
    final sortedList = List<String>.from(subjects);
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }
  
  /// Sort topics in ascending alphabetical order
  static List<String> sortTopics(List<String> topics) {
    final sortedList = List<String>.from(topics);
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }
  
  /// Sort center names in ascending alphabetical order
  static List<String> sortCenterNames(List<String> centerNames) {
    final sortedList = List<String>.from(centerNames);
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }
  
  /// Sort volunteer names in ascending alphabetical order
  static List<String> sortVolunteerNames(List<String> volunteerNames) {
    final sortedList = List<String>.from(volunteerNames);
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }
  
  /// Sort roll numbers in ascending order (handles both numeric and alphanumeric)
  static List<String> sortRollNumbers(List<String> rollNumbers) {
    final sortedList = List<String>.from(rollNumbers);
    sortedList.sort((a, b) => _compareRollNumber(a, b));
    return sortedList;
  }
  
  /// Sort attendance records by date (ascending - oldest first)
  static List<AttendanceRecord> sortAttendanceRecords(List<AttendanceRecord> records) {
    final sortedList = List<AttendanceRecord>.from(records);
    sortedList.sort((a, b) => a.date.compareTo(b.date));
    return sortedList;
  }
  
  /// Sort volunteer reports by volunteer name (A-Z), then by date (newest first for same volunteer)
  static List<VolunteerReport> sortVolunteerReports(List<VolunteerReport> reports) {
    final sortedList = List<VolunteerReport>.from(reports);
    sortedList.sort((a, b) {
      // First by volunteer name (A-Z)
      final nameComparison = a.volunteerName.toLowerCase().compareTo(b.volunteerName.toLowerCase());
      if (nameComparison != 0) return nameComparison;
      
      // Then by date (newest first for same volunteer)
      return DateTime.fromMillisecondsSinceEpoch(b.id).compareTo(DateTime.fromMillisecondsSinceEpoch(a.id));
    });
    return sortedList;
  }
  
  /// Sort events by date (newest first)
  static List<Event> sortEvents(List<Event> events) {
    final sortedList = List<Event>.from(events);
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }
  
  /// Sort schedules by date (newest first), then by time
  static List<ScheduleEntry> sortSchedules(List<ScheduleEntry> schedules) {
    final sortedList = List<ScheduleEntry>.from(schedules);
    sortedList.sort((a, b) {
      // First by date (newest first)
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      
      // Then by time (earliest first for same date)
      final timeComparison = a.time.hour.compareTo(b.time.hour);
      if (timeComparison != 0) return timeComparison;
      
      return a.time.minute.compareTo(b.time.minute);
    });
    return sortedList;
  }
  
  /// Sort notifications by date (newest first)
  static List<AppNotification> sortNotifications(List<AppNotification> notifications) {
    final sortedList = List<AppNotification>.from(notifications);
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }
  
  /// Helper method to compare class batches (handles numeric and alphanumeric)
  static int _compareClassBatch(String a, String b) {
    // Try to parse as numbers first
    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);
    
    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }
    
    // If not both numbers, compare as strings
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
  
  /// Helper method to compare roll numbers (handles numeric and alphanumeric)
  static int _compareRollNumber(String a, String b) {
    // Try to parse as numbers first
    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);
    
    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }
    
    // If not both numbers, compare as strings
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
  
  /// Sort a map by keys in ascending order
  static Map<String, T> sortMapByKeys<T>(Map<String, T> map) {
    final sortedKeys = map.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final sortedMap = <String, T>{};
    for (final key in sortedKeys) {
      sortedMap[key] = map[key]!;
    }
    return sortedMap;
  }
  
  /// Sort a list of maps by a specific key
  static List<Map<String, dynamic>> sortMapListByKey(List<Map<String, dynamic>> list, String key) {
    final sortedList = List<Map<String, dynamic>>.from(list);
    sortedList.sort((a, b) {
      final aValue = a[key]?.toString() ?? '';
      final bValue = b[key]?.toString() ?? '';
      return aValue.toLowerCase().compareTo(bValue.toLowerCase());
    });
    return sortedList;
  }
}