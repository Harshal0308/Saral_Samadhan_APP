class Visit {
  final int? id;
  final String name;
  final String contact;
  final String purpose;
  final DateTime visitDate;
  final DateTime timestamp;
  final String centerName;

  Visit({
    this.id,
    required this.name,
    required this.contact,
    required this.purpose,
    required this.visitDate,
    required this.timestamp,
    required this.centerName,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'contact': contact,
      'purpose': purpose,
      'visit_date': visitDate.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'center_name': centerName,
    };
    
    // Only include id if it's not null (for updates)
    if (id != null) {
      json['id'] = id!;
    }
    
    return json;
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      purpose: json['purpose'] ?? '',
      visitDate: DateTime.parse(json['visit_date']),
      timestamp: DateTime.parse(json['timestamp']),
      centerName: json['center_name'] ?? '',
    );
  }

  Visit copyWith({
    int? id,
    String? name,
    String? contact,
    String? purpose,
    DateTime? visitDate,
    DateTime? timestamp,
    String? centerName,
  }) {
    return Visit(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      purpose: purpose ?? this.purpose,
      visitDate: visitDate ?? this.visitDate,
      timestamp: timestamp ?? this.timestamp,
      centerName: centerName ?? this.centerName,
    );
  }
}