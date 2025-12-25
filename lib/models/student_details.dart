class StudentDetails {
  final int studentId;
  final String? aadhaarId;
  final String parentGuardianName;
  final String? parentGuardianRelationship;
  final String? parentGuardianPhone;
  final String? parentGuardianEmail;
  final String? parentGuardianOccupation;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? currentMedications;
  final bool hasDisability;
  final String? disabilityType;
  final String? disabilityCertificateNumber;
  final String? specialNeeds;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final String? mediumOfInstruction;
  final DateTime? enrollmentDate;
  final String? previousSchool;
  final String? transferCertificateNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentDetails({
    required this.studentId,
    this.aadhaarId,
    required this.parentGuardianName,
    this.parentGuardianRelationship,
    this.parentGuardianPhone,
    this.parentGuardianEmail,
    this.parentGuardianOccupation,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.country = 'India',
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.currentMedications,
    this.hasDisability = false,
    this.disabilityType,
    this.disabilityCertificateNumber,
    this.specialNeeds,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.mediumOfInstruction = 'English',
    this.enrollmentDate,
    this.previousSchool,
    this.transferCertificateNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    return StudentDetails(
      studentId: json['student_id'] as int,
      aadhaarId: json['aadhaar_id'] as String?,
      parentGuardianName: json['parent_guardian_name'] as String,
      parentGuardianRelationship: json['parent_guardian_relationship'] as String?,
      parentGuardianPhone: json['parent_guardian_phone'] as String?,
      parentGuardianEmail: json['parent_guardian_email'] as String?,
      parentGuardianOccupation: json['parent_guardian_occupation'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      country: json['country'] as String? ?? 'India',
      bloodGroup: json['blood_group'] as String?,
      allergies: json['allergies'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      currentMedications: json['current_medications'] as String?,
      hasDisability: json['has_disability'] as bool? ?? false,
      disabilityType: json['disability_type'] as String?,
      disabilityCertificateNumber: json['disability_certificate_number'] as String?,
      specialNeeds: json['special_needs'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactRelationship: json['emergency_contact_relationship'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      mediumOfInstruction: json['medium_of_instruction'] as String? ?? 'English',
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.parse(json['enrollment_date'] as String)
          : null,
      previousSchool: json['previous_school'] as String?,
      transferCertificateNumber: json['transfer_certificate_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'aadhaar_id': aadhaarId,
      'parent_guardian_name': parentGuardianName,
      'parent_guardian_relationship': parentGuardianRelationship,
      'parent_guardian_phone': parentGuardianPhone,
      'parent_guardian_email': parentGuardianEmail,
      'parent_guardian_occupation': parentGuardianOccupation,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'current_medications': currentMedications,
      'has_disability': hasDisability,
      'disability_type': disabilityType,
      'disability_certificate_number': disabilityCertificateNumber,
      'special_needs': specialNeeds,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relationship': emergencyContactRelationship,
      'emergency_contact_phone': emergencyContactPhone,
      'medium_of_instruction': mediumOfInstruction,
      'enrollment_date': enrollmentDate?.toIso8601String().split('T')[0],
      'previous_school': previousSchool,
      'transfer_certificate_number': transferCertificateNumber,
    };
  }

  StudentDetails copyWith({
    int? studentId,
    String? aadhaarId,
    String? parentGuardianName,
    String? parentGuardianRelationship,
    String? parentGuardianPhone,
    String? parentGuardianEmail,
    String? parentGuardianOccupation,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? bloodGroup,
    String? allergies,
    String? medicalConditions,
    String? currentMedications,
    bool? hasDisability,
    String? disabilityType,
    String? disabilityCertificateNumber,
    String? specialNeeds,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? mediumOfInstruction,
    DateTime? enrollmentDate,
    String? previousSchool,
    String? transferCertificateNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentDetails(
      studentId: studentId ?? this.studentId,
      aadhaarId: aadhaarId ?? this.aadhaarId,
      parentGuardianName: parentGuardianName ?? this.parentGuardianName,
      parentGuardianRelationship: parentGuardianRelationship ?? this.parentGuardianRelationship,
      parentGuardianPhone: parentGuardianPhone ?? this.parentGuardianPhone,
      parentGuardianEmail: parentGuardianEmail ?? this.parentGuardianEmail,
      parentGuardianOccupation: parentGuardianOccupation ?? this.parentGuardianOccupation,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      hasDisability: hasDisability ?? this.hasDisability,
      disabilityType: disabilityType ?? this.disabilityType,
      disabilityCertificateNumber: disabilityCertificateNumber ?? this.disabilityCertificateNumber,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      mediumOfInstruction: mediumOfInstruction ?? this.mediumOfInstruction,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      previousSchool: previousSchool ?? this.previousSchool,
      transferCertificateNumber: transferCertificateNumber ?? this.transferCertificateNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
