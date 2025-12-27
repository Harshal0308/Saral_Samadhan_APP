import 'package:flutter/material.dart';
import '../models/student_details.dart';
import '../services/student_details_service.dart';
import '../pages/student_enrollment_page_complete.dart';

class StudentDetailsViewPage extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentDetailsViewPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailsViewPage> createState() => _StudentDetailsViewPageState();
}

class _StudentDetailsViewPageState extends State<StudentDetailsViewPage> {
  final StudentDetailsService _service = StudentDetailsService();
  bool _isLoading = true;
  StudentDetails? _details;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      _details = await _service.getStudentDetails(widget.studentId);
    } catch (e) {
      // Handle error silently or show a message
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEnrollmentPageComplete(
          studentId: widget.studentId,
          studentName: widget.studentName,
        ),
      ),
    );
    
    if (result == true) {
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} - Details'),
        actions: [
          IconButton(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
              ? _buildNoDetailsView()
              : _buildDetailsView(),
    );
  }

  Widget _buildNoDetailsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No enrollment details found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the edit button to add enrollment details',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.add),
            label: const Text('Add Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_details!.aadhaarId != null) _buildIdentificationSection(),
          _buildParentGuardianSection(),
          _buildAddressSection(),
          _buildMedicalSection(),
          if (_details!.hasDisability) _buildDisabilitySection(),
          _buildEmergencyContactSection(),
          _buildAcademicSection(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey,
                fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return _buildSectionCard(
      'Identification',
      Icons.badge,
      [
        _buildDetailRow('Aadhaar ID', _details!.aadhaarId),
      ],
    );
  }

  Widget _buildParentGuardianSection() {
    return _buildSectionCard(
      'Parent / Guardian',
      Icons.family_restroom,
      [
        _buildDetailRow('Name', _details!.parentGuardianName),
        _buildDetailRow('Relationship', _details!.parentGuardianRelationship),
        _buildDetailRow('Phone', _details!.parentGuardianPhone),
        _buildDetailRow('Email', _details!.parentGuardianEmail),
        _buildDetailRow('Occupation', _details!.parentGuardianOccupation),
      ],
    );
  }

  Widget _buildAddressSection() {
    final hasAddress = _details!.addressLine1 != null ||
        _details!.city != null ||
        _details!.state != null ||
        _details!.pincode != null;

    if (!hasAddress) return const SizedBox.shrink();

    return _buildSectionCard(
      'Address',
      Icons.home,
      [
        _buildDetailRow('Address Line 1', _details!.addressLine1),
        _buildDetailRow('Address Line 2', _details!.addressLine2),
        _buildDetailRow('City', _details!.city),
        _buildDetailRow('State', _details!.state),
        _buildDetailRow('Pincode', _details!.pincode),
        _buildDetailRow('Country', _details!.country),
      ],
    );
  }

  Widget _buildMedicalSection() {
    final hasMedical = _details!.bloodGroup != null ||
        _details!.allergies != null ||
        _details!.medicalConditions != null ||
        _details!.currentMedications != null;

    if (!hasMedical) return const SizedBox.shrink();

    return _buildSectionCard(
      'Medical & Health',
      Icons.medical_services,
      [
        _buildDetailRow('Blood Group', _details!.bloodGroup),
        _buildDetailRow('Allergies', _details!.allergies),
        _buildDetailRow('Medical Conditions', _details!.medicalConditions),
        _buildDetailRow('Current Medications', _details!.currentMedications),
      ],
    );
  }

  Widget _buildDisabilitySection() {
    return _buildSectionCard(
      'Disability Information',
      Icons.accessible,
      [
        _buildDetailRow('Has Disability', _details!.hasDisability ? 'Yes' : 'No'),
        if (_details!.hasDisability) ...[
          _buildDetailRow('Disability Type', _details!.disabilityType),
          _buildDetailRow('Certificate Number', _details!.disabilityCertificateNumber),
          _buildDetailRow('Special Needs', _details!.specialNeeds),
        ],
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    final hasEmergency = _details!.emergencyContactName != null ||
        _details!.emergencyContactPhone != null;

    if (!hasEmergency) return const SizedBox.shrink();

    return _buildSectionCard(
      'Emergency Contact',
      Icons.emergency,
      [
        _buildDetailRow('Contact Name', _details!.emergencyContactName),
        _buildDetailRow('Relationship', _details!.emergencyContactRelationship),
        _buildDetailRow('Phone Number', _details!.emergencyContactPhone),
      ],
    );
  }

  Widget _buildAcademicSection() {
    final hasAcademic = _details!.enrollmentDate != null ||
        _details!.previousSchool != null ||
        _details!.transferCertificateNumber != null;

    return _buildSectionCard(
      'Academic Information',
      Icons.school,
      [
        _buildDetailRow('Medium of Instruction', _details!.mediumOfInstruction),
        _buildDetailRow(
          'Enrollment Date',
          _details!.enrollmentDate != null
              ? '${_details!.enrollmentDate!.day}/${_details!.enrollmentDate!.month}/${_details!.enrollmentDate!.year}'
              : null,
        ),
        if (hasAcademic) ...[
          _buildDetailRow('Previous School', _details!.previousSchool),
          _buildDetailRow('Transfer Certificate', _details!.transferCertificateNumber),
        ],
      ],
    );
  }
}