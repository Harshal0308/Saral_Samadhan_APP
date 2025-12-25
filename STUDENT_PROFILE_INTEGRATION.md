# Student Profile Integration - Implementation Guide

This document contains the complete code for integrating enrollment details into the Student Profile page with tabs.

## File 1: lib/widgets/student_details_view_widget.dart

Create this new file with the following content:

```dart
import 'package:flutter/material.dart';
import '../models/student_details.dart';

class StudentDetailsViewWidget extends StatelessWidget {
  final StudentDetails? details;
  final VoidCallback onEdit;

  const StudentDetailsViewWidget({
    super.key,
    required this.details,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (details == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Enrollment details not completed',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.add),
              label: const Text('Add Enrollment Details'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEditButton(),
        const SizedBox(height: 16),
        _buildIdentificationSection(),
        const SizedBox(height: 16),
        _buildParentGuardianSection(),
        const SizedBox(height: 16),
        _buildAddressSection(),
        const SizedBox(height: 16),
        _buildMedicalSection(),
        if (details!.hasDisability) ...[
          const SizedBox(height: 16),
          _buildDisabilitySection(),
        ],
        const SizedBox(height: 16),
        _buildEmergencyContactSection(),
        const SizedBox(height: 16),
        _buildAcademicSection(),
      ],
    );
  }

  Widget _buildEditButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Details'),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Identification', Icons.badge),
            _buildInfoRow('Aadhaar ID', details!.aadhaarId),
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
            _buildInfoRow('Name', details!.parentGuardianName),
            _buildInfoRow('Relationship', details!.parentGuardianRelationship),
            _buildInfoRow('Phone', details!.parentGuardianPhone),
            _buildInfoRow('Email', details!.parentGuardianEmail),
            _buildInfoRow('Occupation', details!.parentGuardianOccupation),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final address = [
      details!.addressLine1,
      details!.addressLine2,
      details!.city,
      details!.state,
      details!.pincode,
      details!.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Address', Icons.home),
            _buildInfoRow('Full Address', address.isNotEmpty ? address : null),
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
            _buildInfoRow('Blood Group', details!.bloodGroup),
            _buildInfoRow('Allergies', details!.allergies),
            _buildInfoRow('Medical Conditions', details!.medicalConditions),
            _buildInfoRow('Current Medications', details!.currentMedications),
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
            _buildInfoRow('Disability Type', details!.disabilityType),
            _buildInfoRow('Certificate Number', details!.disabilityCertificateNumber),
            _buildInfoRow('Special Needs', details!.specialNeeds),
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
            _buildInfoRow('Name', details!.emergencyContactName),
            _buildInfoRow('Relationship', details!.emergencyContactRelationship),
            _buildInfoRow('Phone', details!.emergencyContactPhone),
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
            _buildInfoRow('Medium of Instruction', details!.mediumOfInstruction),
            _buildInfoRow(
              'Enrollment Date',
              details!.enrollmentDate != null
                  ? '${details!.enrollmentDate!.day}/${details!.enrollmentDate!.month}/${details!.enrollmentDate!.year}'
                  : null,
            ),
            _buildInfoRow('Previous School', details!.previousSchool),
            _buildInfoRow('Transfer Certificate', details!.transferCertificateNumber),
          ],
        ),
      ),
    );
  }
}
```

## File 2: lib/pages/student_profile_with_tabs_page.dart

Create this new file with the following content:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_details.dart';
import '../providers/student_details_provider.dart';
import '../providers/student_provider.dart';
import '../pages/student_enrollment_page.dart';
import '../pages/student_profile_analytics_page.dart';
import '../widgets/student_details_view_widget.dart';

class StudentProfileWithTabsPage extends StatefulWidget {
  final Student student;

  const StudentProfileWithTabsPage({super.key, required this.student});

  @override
  State<StudentProfileWithTabsPage> createState() => _StudentProfileWithTabsPageState();
}

class _StudentProfileWithTabsPageState extends State<StudentProfileWithTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrollmentDetails();
  }

  Future<void> _loadEnrollmentDetails() async {
    setState(() => _isLoadingDetails = true);
    final provider = context.read<StudentDetailsProvider>();
    await provider.loadStudentDetails(widget.student.id);
    setState(() => _isLoadingDetails = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEnrollmentPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEnrollmentPage(
          studentId: widget.student.id,
          studentName: widget.student.name,
        ),
      ),
    );

    if (result == true) {
      _loadEnrollmentDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress', icon: Icon(Icons.analytics)),
            Tab(text: 'Details', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Progress Tab
          StudentProfileAnalyticsPage(student: widget.student),
          
          // Details Tab
          _isLoadingDetails
              ? const Center(child: CircularProgressIndicator())
              : Consumer<StudentDetailsProvider>(
                  builder: (context, provider, _) {
                    return StudentDetailsViewWidget(
                      details: provider.currentStudentDetails,
                      onEdit: _navigateToEnrollmentPage,
                    );
                  },
                ),
        ],
      ),
    );
  }
}
```

## Integration Steps

1. **Create the widget file**: Create `lib/widgets/student_details_view_widget.dart` with the code above
2. **Create the page file**: Create `lib/pages/student_profile_with_tabs_page.dart` with the code above
3. **Update navigation**: Replace any navigation to `StudentProfileAnalyticsPage` with `StudentProfileWithTabsPage`

## Usage Example

```dart
// Navigate to student profile with tabs
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StudentProfileWithTabsPage(
      student: selectedStudent,
    ),
  ),
);
```

## Features

✅ Two tabs: Progress and Details
✅ Progress tab shows existing analytics
✅ Details tab shows enrollment information in read-only format
✅ "Edit Details" button navigates to enrollment page
✅ Shows "Enrollment details not completed" when no data exists
✅ Clean, organized sections with icons
✅ Automatic refresh after editing
✅ Handles null values gracefully

## Notes

- The student ID is handled internally and never exposed to the user
- All enrollment data is fetched from the `student_details` table
- The page uses the existing `StudentDetailsProvider` for state management
- Disability section only shows when `hasDisability` is true
