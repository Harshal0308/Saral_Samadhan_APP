class ReminderSettings {
  final bool scheduleRemindersEnabled;
  final int scheduleReminderMinutesBefore; // Minutes before scheduled time
  final bool attendanceRemindersEnabled;
  final String attendanceReminderTime; // Format: "HH:mm"
  final List<int> attendanceReminderDays; // 1=Monday, 7=Sunday

  ReminderSettings({
    this.scheduleRemindersEnabled = true,
    this.scheduleReminderMinutesBefore = 30,
    this.attendanceRemindersEnabled = true,
    this.attendanceReminderTime = "09:00",
    this.attendanceReminderDays = const [1, 2, 3, 4, 5], // Mon-Fri by default
  });

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      scheduleRemindersEnabled: map['scheduleRemindersEnabled'] as bool? ?? true,
      scheduleReminderMinutesBefore: map['scheduleReminderMinutesBefore'] as int? ?? 30,
      attendanceRemindersEnabled: map['attendanceRemindersEnabled'] as bool? ?? true,
      attendanceReminderTime: map['attendanceReminderTime'] as String? ?? "09:00",
      attendanceReminderDays: (map['attendanceReminderDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleRemindersEnabled': scheduleRemindersEnabled,
      'scheduleReminderMinutesBefore': scheduleReminderMinutesBefore,
      'attendanceRemindersEnabled': attendanceRemindersEnabled,
      'attendanceReminderTime': attendanceReminderTime,
      'attendanceReminderDays': attendanceReminderDays,
    };
  }

  ReminderSettings copyWith({
    bool? scheduleRemindersEnabled,
    int? scheduleReminderMinutesBefore,
    bool? attendanceRemindersEnabled,
    String? attendanceReminderTime,
    List<int>? attendanceReminderDays,
  }) {
    return ReminderSettings(
      scheduleRemindersEnabled: scheduleRemindersEnabled ?? this.scheduleRemindersEnabled,
      scheduleReminderMinutesBefore: scheduleReminderMinutesBefore ?? this.scheduleReminderMinutesBefore,
      attendanceRemindersEnabled: attendanceRemindersEnabled ?? this.attendanceRemindersEnabled,
      attendanceReminderTime: attendanceReminderTime ?? this.attendanceReminderTime,
      attendanceReminderDays: attendanceReminderDays ?? this.attendanceReminderDays,
    );
  }
}
