import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_details.dart';
import '../services/student_details_service.dart';

class StudentEnrollmentPageComplete extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentEnrollmentPageComplete({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentEnrollmentPageComplete> createState() => _StudentEnrollmentPageCompleteState();
}

class _StudentEnrollmentPageCompleteState extends State<StudentEnrollmentPageComplete> {
  final _formKey = GlobalKey<FormState>();
  final StudentDetailsService _service = StudentDetailsService();
  bool _isLoading = true;

  // Aadhaar
  final _aadhaarController = TextEditingController();

  // Parent/Guardian
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentOccupationController = TextEditingController();
  String _parentRelationship = 'Father';

  // Address
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _country = 'India';

  // Medical
  String? _bloodGroup;
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  // Disability
  bool _hasDisability = false;
  final _disabilityTypeController = TextEditingController();
  final _disabilityCertController = TextEditingController();
  final _specialNeedsController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String _emergencyRelationship = 'Father';

  // Academic
  String _mediumOfInstruction = 'English';
  DateTime? _enrollmentDate;
  final _previousSchoolController = TextEditingController();
  final _transferCertController = TextEditingController();

  final List<String> _relationships = [
    'Father', 'Mother', 'Guardian', 'Uncle', 'Aunt', 'Grandparent', 'Sibling', 'Other'
  ];

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final List<String> _mediums = [
    'English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu', 'Kannada', 'Bengali', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    try {
      final details = await _service.getStudentDetails(widget.studentId);
      if (details != null) {
        _populateForm(details);
      }
    } catch (e) {
      print('Error loading details: $e');
    }
    
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

  Future<void> _saveDetails({bool isPartialSave = false}) async {
    if (!isPartialSave && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final details = StudentDetails(
      studentId: widget.studentId,
      aadhaarId: _aadhaarController.text.isEmpty ? null : _aadhaarController.text,
      parentGuardianName: _parentNameController.text.isEmpty ? 'Unknown' : _parentNameController.text,
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

    try {
      await _service.upsertStudentDetails(
        studentId: widget.studentId,
        details: details,
      );

      if (mounted) {
        final message = isPartialSave 
            ? 'Enrollment details saved for later completion'
            : 'Enrollment details saved successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectEnrollmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _enrollmentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _enrollmentDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enrollment: ${widget.studentName}'),
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
                  _buildActionButtons(),
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
              decoration: const InputDecoration(labelText: 'Name'),
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
              TextFormField(
                controller: _disabilityTypeController,
                decoration: const InputDecoration(labelText: 'Disability Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _disabilityCertController,
                decoration: const InputDecoration(labelText: 'Certificate Number'),
              ),
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
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
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
            TextFormField(
              controller: _previousSchoolController,
              decoration: const InputDecoration(labelText: 'Previous School'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _transferCertController,
              decoration: const InputDecoration(labelText: 'Transfer Certificate Number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Button (Full Save)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveDetails(isPartialSave: false),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        // Later Button (Partial Save)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _saveDetails(isPartialSave: true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.orange),
              foregroundColor: Colors.orange,
            ),
            child: const Text('Later', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}