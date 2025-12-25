# Complete Student Enrollment Implementation

This document contains ALL the code needed for the student enrollment feature. Copy each section into the corresponding file.

---

## 1. lib/providers/student_details_provider.dart

```dart
import 'package:flutter/foundation.dart';
import '../models/student_details.dart';
import '../services/student_details_service.dart';

class StudentDetailsProvider with ChangeNotifier {
  final StudentDetailsService _service = StudentDetailsService();
  
  StudentDetails? _currentStudentDetails;
  bool _isLoading = false;
  String? _error;

  StudentDetails? get currentStudentDetails => _currentStudentDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudentDetails(int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStudentDetails = await _service.getStudentDetails(studentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveStudentDetails({
    required int studentId,
    required StudentDetails details,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStudentDetails = await _service.upsertStudentDetails(
        studentId: studentId,
        details: details,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> hasEnrollmentDetails(int studentId) async {
    try {
      return await _service.hasEnrollmentDetails(studentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFields({
    required int studentId,
    required Map<String, dynamic> updates,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStudentDetails = await _service.updateStudentDetailsFields(
        studentId: studentId,
        updates: updates,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearDetails() {
    _currentStudentDetails = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

---

## 2. lib/pages/student_enrollment_page.dart (Part 1 of 3)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/student_details.dart';
import '../providers/student_details_provider.dart';

class StudentEnrollmentPage extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentEnrollmentPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentEnrollmentPage> createState() => _StudentEnrollmentPageState();
}

class _StudentEnrollmentPageState extends State<StudentEnrollmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _aadhaarController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentOccupationController = TextEditingController();
  String _parentRelationship = 'Father';
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _country = 'India';
  String? _bloodGroup;
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  bool _hasDisability = false;
  final _disabilityTypeController = TextEditingController();
  final _disabilityCertController = TextEditingController();
  final _specialNeedsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String _emergencyRelationship = 'Father';
  String _mediumOfInstruction = 'English';
  DateTime? _enrollmentDate;
  final _previousSchoolController = TextEditingController();
  final _transferCertController = TextEditingController();

  final List<String> _relationships = ['Father', 'Mother', 'Guardian', 'Uncle', 'Aunt', 'Grandparent', 'Sibling', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _mediums = ['English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu', 'Kannada', 'Bengali', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final provider = context.read<StudentDetailsProvider>();
    await provider.loadStudentDetails(widget.studentId);
    final details = provider.currentStudentDetails;
    if (details != null) _populateForm(details);
    setState(() => _isLoading = false);
  }

  void _populateForm(StudentDetails details) {
    _aadhaarController.text = details.aadhaarId ?? '';
    _parentNameController.text = details.parentGuardianName;
    _parentPhoneController.text = details.parentGuardianPhone ?? '';
    _parentEmailController.text = details.parentGuardianEmail ?? '';
    _parentOccupationController.text = details.parentGuardianOccupation ?? '';
    _parentRelationship = details.parentGuardianRelationship ?? 'Father';
    _addressLine1Controller.text = details.addressLine1 ?? '';
    _addressLine2Controller.text = details.addressLine2 ?? '';
    _cityController.text = details.city ?? '';
    _stateController.text = details.state ?? '';
    _pincodeController.text = details.pincode ?? '';
    _country = details.country ?? 'India';
    _bloodGroup = details.bloodGroup;
    _allergiesController.text = details.allergies ?? '';
    _medicalConditionsController.text = details.medicalConditions ?? '';
    _medicationsController.text = details.currentMedications ?? '';
    _hasDisability = details.hasDisability;
    _disabilityTypeController.text = details.disabilityType ?? '';
    _disabilityCertController.text = details.disabilityCertificateNumber ?? '';
    _specialNeedsController.text = details.specialNeeds ?? '';
    _emergencyNameController.text = details.emergencyContactName ?? '';
    _emergencyPhoneController.text = details.emergencyContactPhone ?? '';
    _emergencyRelationship = details.emergencyContactRelationship ?? 'Father';
    _mediumOfInstruction = details.mediumOfInstruction ?? 'English';
    _enrollmentDate = details.enrollmentDate;
    _previousSchoolController.text = details.previousSchool ?? '';
    _transferCertController.text = details.transferCertificateNumber ?? '';
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _parentOccupationController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _medicationsController.dispose();
    _disabilityTypeController.dispose();
    _disabilityCertController.dispose();
    _specialNeedsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _previousSchoolController.dispose();
    _transferCertController.dispose();
    super.dispose();
  }
```

---

## 3. lib/pages/student_enrollment_page.dart (Part 2 of 3)

Add this to the same file after the dispose method:

```dart
  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final details = StudentDetails(
      studentId: widget.studentId,
      aadhaarId: _aadhaarController.text.isEmpty ? null : _aadhaarController.text,
      parentGuardianName: _parentNameController.text,
      parentGuardianRelationship: _parentRelationship,
      parentGuardianPhone: _parentPhoneController.text.isEmpty ? null : _parentPhoneController.text,
      parentGuardianEmail: _parentEmailController.text.isEmpty ? null : _parentEmailController.text,
      parentGuardianOccupation: _parentOccupationController.text.isEmpty ? null : _parentOccupationController.text,
      addressLine1: _addressLine1Controller.text.isEmpty ? null : _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      state: _stateController.text.isEmpty ? null : _stateController.text,
      pincode: _pincodeController.text.isEmpty ? null : _pincodeController.text,
      country: _country,
      bloodGroup: _bloodGroup,
      allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
      medicalConditions: _medicalConditionsController.text.isEmpty ? null : _medicalConditionsController.text,
      currentMedications: _medicationsController.text.isEmpty ? null : _medicationsController.text,
      hasDisability: _hasDisability,
      disabilityType: _disabilityTypeController.text.isEmpty ? null : _disabilityTypeController.text,
      disabilityCertificateNumber: _disabilityCertController.text.isEmpty ? null : _disabilityCertController.text,
      specialNeeds: _specialNeedsController.text.isEmpty ? null : _specialNeedsController.text,
      emergencyContactName: _emergencyNameController.text.isEmpty ? null : _emergencyNameController.text,
      emergencyContactRelationship: _emergencyRelationship,
      emergencyContactPhone: _emergencyPhoneController.text.isEmpty ? null : _emergencyPhoneController.text,
      mediumOfInstruction: _mediumOfInstruction,
      enrollmentDate: _enrollmentDate,
      previousSchool: _previousSchoolController.text.isEmpty ? null : _previousSchoolController.text,
      transferCertificateNumber: _transferCertController.text.isEmpty ? null : _transferCertController.text,
    );

    final provider = context.read<StudentDetailsProvider>();
    final success = await provider.saveStudentDetails(studentId: widget.studentId, details: details);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment details saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectEnrollmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _enrollmentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _enrollmentDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enrollment: ${widget.studentName}'),
        actions: [
          TextButton.icon(
            onPressed: _saveDetails,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAadhaarSection(),
                  const SizedBox(height: 24),
                  _buildParentGuardianSection(),
                  const SizedBox(height: 24),
                  _buildAddressSection(),
                  const SizedBox(height: 24),
                  _buildMedicalSection(),
                  const SizedBox(height: 24),
                  _buildDisabilitySection(),
                  const SizedBox(height: 24),
                  _buildEmergencyContactSection(),
                  const SizedBox(height: 24),
                  _buildAcademicSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
```

---

## 4. lib/pages/student_enrollment_page.dart (Part 3 of 3)

Continue adding to the same file:

```dart
  Widget _buildAadhaarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Identification', Icons.badge),
            TextFormField(
              controller: _aadhaarController,
              decoration: const InputDecoration(labelText: 'Aadhaar ID', hintText: '12-digit Aadhaar number'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              validator: (v) => v != null && v.isNotEmpty && v.length != 12 ? 'Enter valid 12-digit Aadhaar' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentGuardianSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Parent / Guardian', Icons.family_restroom),
            TextFormField(
              controller: _parentNameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _parentRelationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _parentRelationship = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentPhoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentOccupationController,
              decoration: const InputDecoration(labelText: 'Occupation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Address', Icons.home),
            TextFormField(controller: _addressLine1Controller, decoration: const InputDecoration(labelText: 'Address Line 1')),
            const SizedBox(height: 12),
            TextFormField(controller: _addressLine2Controller, decoration: const InputDecoration(labelText: 'Address Line 2')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _country,
                    decoration: const InputDecoration(labelText: 'Country'),
                    onChanged: (v) => _country = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Medical & Health', Icons.medical_services),
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(labelText: 'Allergies', hintText: 'List any known allergies'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicalConditionsController,
              decoration: const InputDecoration(labelText: 'Medical Conditions', hintText: 'Any chronic conditions'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(labelText: 'Current Medications'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Disability Information', Icons.accessible),
            SwitchListTile(
              title: const Text('Has Disability'),
              value: _hasDisability,
              onChanged: (v) => setState(() => _hasDisability = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasDisability) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _disabilityTypeController, decoration: const InputDecoration(labelText: 'Disability Type')),
              const SizedBox(height: 12),
              TextFormField(controller: _disabilityCertController, decoration: const InputDecoration(labelText: 'Certificate Number')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialNeedsController,
                decoration: const InputDecoration(labelText: 'Special Needs / Accommodations'),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Emergency Contact', Icons.emergency),
            TextFormField(controller: _emergencyNameController, decoration: const InputDecoration(labelText: 'Contact Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _emergencyRelationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _emergencyRelationship = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Academic Information', Icons.school),
            DropdownButtonFormField<String>(
              value: _mediumOfInstruction,
              decoration: const InputDecoration(labelText: 'Medium of Instruction'),
              items: _mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _mediumOfInstruction = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enrollment Date'),
              subtitle: Text(_enrollmentDate != null
                  ? '${_enrollmentDate!.day}/${_enrollmentDate!.month}/${_enrollmentDate!.year}'
                  : 'Not set'),
              trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _selectEnrollmentDate),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _previousSchoolController, decoration: const InputDecoration(labelText: 'Previous School')),
            const SizedBox(height: 12),
            TextFormField(controller: _transferCertController, decoration: const InputDecoration(labelText: 'Transfer Certificate Number')),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<StudentDetailsProvider>(
      builder: (context, provider, _) {
        return ElevatedButton(
          onPressed: provider.isLoading ? null : _saveDetails,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: provider.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Enrollment Details', style: TextStyle(fontSize: 16)),
        );
      },
    );
  }
}
```

---

## Instructions

1. Copy the code from section 1 into `lib/providers/student_details_provider.dart`
2. Copy sections 2, 3, and 4 into `lib/pages/student_enrollment_page.dart` (combine them into one file)
3. The other files (models, services) should already be complete
4. Register the provider in your main.dart if not already done

These files are now complete and ready to use!
