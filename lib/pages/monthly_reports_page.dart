import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/volunteer_management_provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/services/teacher_service.dart';
import 'package:samadhan_app/services/visit_service.dart';
import 'package:samadhan_app/models/teacher.dart';
import 'package:samadhan_app/models/volunteer.dart';
import 'package:samadhan_app/models/visit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MonthlyReportsPage extends StatefulWidget {
  const MonthlyReportsPage({super.key});

  @override
  State<MonthlyReportsPage> createState() => _MonthlyReportsPageState();
}

class _MonthlyReportsPageState extends State<MonthlyReportsPage> {
  DateTime _selectedMonth = DateTime.now();
  String _selectedCenter = '';
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  
  // Feedback text controllers
  final TextEditingController _problemsFeedbackController = TextEditingController();
  final TextEditingController _suggestionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _problemsFeedbackController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Get center from user settings
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? '';
    
    if (selectedCenter.isNotEmpty) {
      setState(() {
        _selectedCenter = selectedCenter;
      });
    } else {
      // Fallback to first center from students if no center selected
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.fetchStudents();
      final centers = studentProvider.getAllCenters();
      if (centers.isNotEmpty) {
        setState(() {
          _selectedCenter = centers.first;
        });
      }
    }
    
    await _generateReport();
  }

  Future<void> _generateReport() async {
    if (_selectedCenter.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
      final volunteerManagementProvider = Provider.of<VolunteerManagementProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      await Future.wait([
        studentProvider.fetchStudents(),
        attendanceProvider.fetchAttendanceRecords(),
        volunteerProvider.fetchReports(),
        volunteerManagementProvider.fetchVolunteers(),
        eventProvider.loadEvents(),
      ]);

      // Get center details from Supabase
      final centerData = await _fetchCenterDetails(_selectedCenter);
      
      // Get teacher/center head info
      final teacherService = TeacherService();
      final teachers = await teacherService.getTeachersByCenter(_selectedCenter);
      final centerHead = teachers.isNotEmpty ? teachers.first.name : '';

      // Filter data for selected month and center
      final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      final students = studentProvider.getStudentsByCenter(_selectedCenter);
      final attendanceRecords = attendanceProvider.getAttendanceByCenter(_selectedCenter)
          .where((r) => r.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                       r.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .toList();
      final volunteerReports = volunteerProvider.getReportsByCenter(_selectedCenter);
      
      // Filter events for selected month and center
      // Include events with matching center OR empty center (for backward compatibility)
      final events = eventProvider.events
          .where((e) => (e.centerName == _selectedCenter || e.centerName.isEmpty) &&
                       e.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                       e.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .toList();
      
      print('📊 Monthly Report - Found ${events.length} events for $_selectedCenter in ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
      for (var e in events) {
        print('   - ${e.title} on ${DateFormat('dd/MM/yyyy').format(e.date)} (center: ${e.centerName})');
      }

      // Calculate average attendance
      double avgAttendance = 0.0;
      if (attendanceRecords.isNotEmpty && students.isNotEmpty) {
        int totalPresent = 0;
        int totalPossible = 0;
        for (var record in attendanceRecords) {
          for (var student in students) {
            final key = '${student.rollNo}_${student.classBatch}';
            if (record.attendance.containsKey(key)) {
              totalPossible++;
              if (record.attendance[key] == true) {
                totalPresent++;
              }
            }
          }
        }
        if (totalPossible > 0) {
          avgAttendance = (totalPresent / totalPossible) * 100;
        }
      }

      // Get volunteer data from the new volunteer management system
      List<MonthlyVolunteerReport> monthlyVolunteerData = [];
      try {
        monthlyVolunteerData = await volunteerManagementProvider.getMonthlyReport(
          _selectedCenter,
          reportMonth: _selectedMonth,
        );
      } catch (e) {
        print('⚠️ Could not get monthly volunteer data from cloud, falling back to local calculation: $e');
        
        // Fallback: Calculate from volunteer reports (old method)
        final uniqueVolunteers = volunteerReports.map((r) => r.volunteerName).toSet();
        for (var volunteerName in uniqueVolunteers) {
          final reports = volunteerReports.where((r) => r.volunteerName == volunteerName).toList();
          int attendanceCount = 0;
          for (var report in reports) {
            if (report.inTime.isNotEmpty && report.outTime.isNotEmpty) {
              attendanceCount++;
            }
          }
          monthlyVolunteerData.add(MonthlyVolunteerReport(
            volunteerName: volunteerName,
            attendanceCount: attendanceCount,
            firstReportDate: DateTime.now(), // Placeholder
            lastReportDate: DateTime.now(), // Placeholder
            daysActive: attendanceCount,
          ));
        }
      }

      // Build volunteer details for the report
      final volunteerDetails = monthlyVolunteerData.map((v) => {
        'name': v.volunteerName,
        'attendance': v.attendanceCount,
        'homeVisits': '', // Leave blank as per requirement
      }).toList();

      // Build activities data from events
      final activitiesData = _buildActivitiesData(events);

      // Fetch visit data for the month
      List<Visit> monthlyVisits = [];
      try {
        final visitService = VisitService();
        final allVisits = await visitService.getVisits(_selectedCenter);
        monthlyVisits = allVisits.where((visit) =>
            visit.visitDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            visit.visitDate.isBefore(monthEnd.add(const Duration(days: 1)))
        ).toList();
        print('📊 Found ${monthlyVisits.length} visits for ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
      } catch (e) {
        print('⚠️ Error fetching visits for monthly report: $e');
        monthlyVisits = [];
      }

      setState(() {
        _reportData = {
          'centerName': _selectedCenter,
          'centerHead': centerHead,
          'totalStudents': students.length,
          'avgAttendance': avgAttendance,
          'volunteerCount': monthlyVolunteerData.length,
          'volunteerDetails': volunteerDetails,
          'monthlyExpenditure': '', // Leave blank
          'activities': activitiesData,
          'month': _selectedMonth,
          'visits': monthlyVisits,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchCenterDetails(String centerName) async {
    try {
      final response = await Supabase.instance.client
          .from('centers')
          .select()
          .eq('name', centerName)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching center details: $e');
      return null;
    }
  }

  Map<String, Map<String, String>> _buildActivitiesData(List<Event> events) {
    // Fixed activity rows as per requirement
    final fixedActivities = [
      'Bal Sabha',
      'Monthly test',
      'Parents meet',
      'Volunteer meet',
      'Sports',
      'Art',
      'Centre cleaning',
      'Seva Day',
    ];

    final activitiesData = <String, Map<String, String>>{};
    
    // Initialize fixed activities with empty values
    for (var activity in fixedActivities) {
      activitiesData[activity] = {
        'date': '',
        'purpose': '',
      };
    }

    print('📋 Building activities data from ${events.length} events');

    // Process all events
    for (var event in events) {
      final eventTitle = event.title.trim();
      final eventTitleLower = eventTitle.toLowerCase();
      String? matchedActivity;
      
      // Try to match with fixed activities
      for (var activity in fixedActivities) {
        final activityLower = activity.toLowerCase();
        if (eventTitleLower == activityLower ||
            eventTitleLower.contains(activityLower) ||
            activityLower.contains(eventTitleLower)) {
          matchedActivity = activity;
          break;
        }
      }
      
      if (matchedActivity != null) {
        // Update existing fixed activity
        activitiesData[matchedActivity] = {
          'date': DateFormat('dd/MM/yyyy').format(event.date),
          'purpose': event.description,
        };
        print('   ✓ Matched "${event.title}" to fixed activity "$matchedActivity"');
      } else {
        // Add as custom activity
        activitiesData[eventTitle] = {
          'date': DateFormat('dd/MM/yyyy').format(event.date),
          'purpose': event.description,
        };
        print('   + Added custom activity "${event.title}"');
      }
    }

    return activitiesData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (_reportData != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Generate PDF',
              onPressed: _generateAndSharePdf,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: _printReport,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating monthly report...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersCard(),
                  const SizedBox(height: 16),
                  if (_reportData != null) ...[
                    _buildReportTitleCard(),
                    const SizedBox(height: 16),
                    _buildCentreDetailsCard(),
                    const SizedBox(height: 16),
                    _buildMonthlyActivitiesCard(),
                    const SizedBox(height: 16),
                    _buildVolunteersDetailsCard(),
                    const SizedBox(height: 16),
                    _buildVisitsCard(),
                    const SizedBox(height: 16),
                    _buildFeedbackCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: () => _selectMonth(context),
                  icon: const Icon(Icons.calendar_month, size: 20),
                  label: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTitleCard() {
    final monthName = DateFormat('MMMM yyyy').format(_reportData!['month']);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'CENTRE MONTHLY PROGRESS REPORT OF THE MONTH: $monthName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCentreDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Centre Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                _buildTableRow('Name of the Centre', _reportData!['centerName'] ?? ''),
                _buildTableRow('Centre Head', _reportData!['centerHead'] ?? ''),
                _buildTableRow('Total students enrolled', '${_reportData!['totalStudents']}'),
                _buildTableRow('Average Students\' attendance', 
                    '${(_reportData!['avgAttendance'] as double).toStringAsFixed(1)}%'),
                _buildTableRow('No. of Volunteers', '${_reportData!['volunteerCount']}'),
                _buildTableRow('Total Monthly expenditure', _reportData!['monthlyExpenditure'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildMonthlyActivitiesCard() {
    final activities = _reportData!['activities'] as Map<String, Map<String, String>>;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...activities.entries.map((entry) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(entry.key),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(entry.value['date'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 200,
                          child: Text(entry.value['purpose'] ?? ''),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteersDetailsCard() {
    final volunteers = _reportData!['volunteerDetails'] as List<Map<String, dynamic>>;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Volunteers Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Volunteer\'s Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No. of Home Visits', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...volunteers.map((v) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(v['name'] ?? ''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${v['attendance']}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(v['homeVisits'] ?? ''),
                    ),
                  ],
                )),
                if (volunteers.isEmpty)
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No volunteers found'),
                      ),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('')),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsCard() {
    final visits = _reportData?['visits'] as List<Visit>? ?? [];
    print('🔍 Building visits card with ${visits.length} visits');
    for (var visit in visits) {
      print('📋 Visit: ${visit.name} - ${visit.contact} - ${visit.purpose}');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Visits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${visits.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (visits.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'No visits recorded for this month',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Visitor/Donor Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Contact No.', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...visits.map((visit) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(visit.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(visit.contact),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(visit.purpose),
                      ),
                    ],
                  )).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Problems Faced / Feedback:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _problemsFeedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter problems faced or feedback...',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suggestions Received Throughout Month:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _suggestionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter suggestions received...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _generateReport();
    }
  }

  Future<pw.Document> _buildPdfDocument() async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(_reportData!['month']);
    final activities = _reportData!['activities'] as Map<String, Map<String, String>>;
    final volunteers = _reportData!['volunteerDetails'] as List<Map<String, dynamic>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return [
            // SECTION 1 - Report Title
            pw.Center(
              child: pw.Text(
                'CENTRE MONTHLY PROGRESS REPORT OF THE MONTH: $monthName',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 20),

            // SECTION 2 - Centre Details
            pw.Text('Centre Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _buildPdfTableRow('Name of the Centre', _reportData!['centerName'] ?? ''),
                _buildPdfTableRow('Centre Head', _reportData!['centerHead'] ?? ''),
                _buildPdfTableRow('Total students enrolled', '${_reportData!['totalStudents']}'),
                _buildPdfTableRow('Average Students\' attendance', 
                    '${(_reportData!['avgAttendance'] as double).toStringAsFixed(1)}%'),
                _buildPdfTableRow('No. of Volunteers', '${_reportData!['volunteerCount']}'),
                _buildPdfTableRow('Total Monthly expenditure', _reportData!['monthlyExpenditure'] ?? ''),
              ],
            ),
            pw.SizedBox(height: 20),

            // SECTION 3 - Monthly Activities
            pw.Text('Monthly Activities', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfHeaderCell('Activity'),
                    _buildPdfHeaderCell('Proposed Date'),
                    _buildPdfHeaderCell('Actual Date'),
                    _buildPdfHeaderCell('Purpose'),
                  ],
                ),
                ...activities.entries.map((entry) => pw.TableRow(
                  children: [
                    _buildPdfCell(entry.key),
                    _buildPdfCell(entry.value['proposedDate'] ?? ''),
                    _buildPdfCell(entry.value['actualDate'] ?? ''),
                    _buildPdfCell(entry.value['purpose'] ?? ''),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),

            // SECTION 4 - Volunteers Details
            pw.Text('Volunteers Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfHeaderCell('Volunteer\'s Name'),
                    _buildPdfHeaderCell('Attendance'),
                    _buildPdfHeaderCell('No. of Home Visits'),
                  ],
                ),
                ...volunteers.map((v) => pw.TableRow(
                  children: [
                    _buildPdfCell(v['name'] ?? ''),
                    _buildPdfCell('${v['attendance']}'),
                    _buildPdfCell(v['homeVisits'] ?? ''),
                  ],
                )),
                if (volunteers.isEmpty)
                  pw.TableRow(
                    children: [
                      _buildPdfCell('No volunteers found'),
                      _buildPdfCell(''),
                      _buildPdfCell(''),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),

            // SECTION 5 - Visits
            pw.Text('Visits', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            () {
              final visits = _reportData?['visits'] as List<Visit>? ?? [];
              if (visits.isEmpty) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('No visits recorded for this month', style: const pw.TextStyle(fontSize: 10)),
                );
              }
              
              return pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildPdfHeaderCell('Visitor/Donor Name'),
                      _buildPdfHeaderCell('Contact No.'),
                      _buildPdfHeaderCell('Purpose'),
                    ],
                  ),
                  ...visits.map((visit) => pw.TableRow(
                    children: [
                      _buildPdfCell(visit.name),
                      _buildPdfCell(visit.contact),
                      _buildPdfCell(visit.purpose),
                    ],
                  )).toList(),
                ],
              );
            }(),
            pw.SizedBox(height: 20),

            // SECTION 6 - Feedback
            pw.Text('Feedback', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Problems Faced / Feedback:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Text(
                _problemsFeedbackController.text.isEmpty 
                    ? ' ' 
                    : _problemsFeedbackController.text,
                style: const pw.TextStyle(fontSize: 10),
              ),
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 50),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Suggestions Received Throughout Month:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Text(
                _suggestionsController.text.isEmpty 
                    ? ' ' 
                    : _suggestionsController.text,
                style: const pw.TextStyle(fontSize: 10),
              ),
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 50),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  Future<void> _generateAndSharePdf() async {
    if (_reportData == null) return;

    try {
      setState(() => _isLoading = true);

      final pdf = await _buildPdfDocument();
      final bytes = await pdf.save();

      final monthName = DateFormat('MMMM_yyyy').format(_reportData!['month']);
      final centerName = (_reportData!['centerName'] as String).replaceAll(' ', '_');
      final fileName = 'Monthly_Report_${centerName}_$monthName.pdf';

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      setState(() => _isLoading = false);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Monthly Report - ${_reportData!['centerName']} - $monthName',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _printReport() async {
    if (_reportData == null) return;

    try {
      final pdf = await _buildPdfDocument();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Monthly_Report_${_reportData!['centerName']}_${DateFormat('MMMM_yyyy').format(_reportData!['month'])}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing report: $e')),
        );
      }
    }
  }
}
