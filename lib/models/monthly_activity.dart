class MonthlyActivity {
  final int id;
  final String name;
  final String? date;
  final String? purpose;
  final String centerName;
  final DateTime? createdAt;

  MonthlyActivity({
    required this.id,
    required this.name,
    this.date,
    this.purpose,
    required this.centerName,
    this.createdAt,
  });

  factory MonthlyActivity.fromMap(Map<String, dynamic> map, int id) {
    return MonthlyActivity(
      id: id,
      name: map['name'] as String,
      date: map['date'] as String?,
      purpose: map['purpose'] as String?,
      centerName: (map['centerName'] ?? map['center_name'] ?? '') as String,
      createdAt: map['createdAt'] != null || map['created_at'] != null
          ? DateTime.parse((map['createdAt'] ?? map['created_at']) as String)
          : null,
    );
  }

  factory MonthlyActivity.fromSupabase(Map<String, dynamic> map) {
    return MonthlyActivity(
      id: map['id'] as int,
      name: map['name'] as String,
      date: map['date'] as String?,
      purpose: map['purpose'] as String?,
      centerName: map['center_name'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'purpose': purpose,
      'centerName': centerName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'date': date,
      'purpose': purpose,
      'center_name': centerName,
    };
  }

  MonthlyActivity copyWith({
    int? id,
    String? name,
    String? date,
    String? purpose,
    String? centerName,
    DateTime? createdAt,
  }) {
    return MonthlyActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      purpose: purpose ?? this.purpose,
      centerName: centerName ?? this.centerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
