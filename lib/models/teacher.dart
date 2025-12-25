class Teacher {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String centerName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Teacher({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.centerName,
    this.role = 'teacher',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      phoneNumber: map['phone_number'] as String,
      centerName: map['center_name'] as String,
      role: map['role'] as String? ?? 'teacher',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'center_name': centerName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Teacher copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? centerName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      centerName: centerName ?? this.centerName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Teacher(id: $id, email: $email, name: $name, centerName: $centerName, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}