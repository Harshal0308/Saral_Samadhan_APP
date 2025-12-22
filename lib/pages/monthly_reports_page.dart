import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/monthly_report_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class MonthlyReportsPage extends StatefulWidget {
  const MonthlyReportsPage({super.key});

  @override
  State<MonthlyReportsPage> createState() => _MonthlyReportsPageState();
}

class _MonthlyReportsPageState extends State<MonthlyReportsPage> {
  DateTime _selectedMonth = DateTime.now();
  String _selectedCenter = 'All Centers';
  bool _isGenerating = false;
  Map<String, dynamic>? _currentReport;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);

      await Future.wait([
        studentProvider.fetchStudents(),
        attendanceProvider.fetchAttendanceRecords(),
        volunteerProvider.fetchReports(),
      ]);

      final report = await MonthlyReportService.generateMonthlyReport(
        students: studentProvider.students,
        attendanceRecords: attendanceProvider.attendanceRecords,
        volunteerReports: volunteerProvider.reports,
        month: _selectedMonth,
        centerName: _selectedCenter == 'All Centers' ? null : _selectedCenter,
      );

      setState(() {
        _currentReport = report;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (_currentReport != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReport,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: _isGenerating
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
                  if (_currentReport != null) ...[
                    _buildExecutiveSummaryCard(),
                    const SizedBox(height: 16),
                    _buildEnrollmentCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceCard(),
                    const SizedBox(height: 16),
                    _buildLearningCard(),
                    const SizedBox(height: 16),
                    _buildRiskAnalysisCard(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                    const SizedBox(height: 16),
                    _buildRecommendationsCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFiltersCard() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final centers = ['All Centers', ...studentProvider.getAllCenters()];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCenter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Center',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: centers.map((center) {
                      return DropdownMenuItem(
                        value: center, 
                        child: Text(
                          center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCenter = value!;
                      });
                      _generateReport();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: () => _selectMonth(context),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: Text(
                      DateFormat('MMM yyyy').format(_selectedMonth),
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryCard() {
    final summary = _currentReport!['summary'] as Map<String, dynamic>;
    final monthName = DateFormat('MMMM yyyy').format(_currentReport!['reportMonth']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Executive Summary - $monthName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Health Score
            Center(
              child: Column(
                children: [
                  Text(
                    '${(summary['healthScore'] as double).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getHealthScoreColor(summary['healthScore'] as double),
                    ),
                  ),
                  const Text('Health Score (out of 100)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Key Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard('Students', '${summary['totalStudents']}', Icons.people, Colors.blue),
                _buildMetricCard('Attendance', '${(summary['overallAttendance'] as double).toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
                _buildMetricCard('Teaching Days', '${summary['teachingDays']}/${summary['workingDays']}', Icons.calendar_today, Colors.orange),
                _buildMetricCard('Vol. Hours', '${(summary['volunteerHours'] as double).toStringAsFixed(1)}h', Icons.volunteer_activism, Colors.purple),
                _buildMetricCard('At Risk', '${summary['atRiskStudents']}', Icons.warning, Colors.red),
                _buildMetricCard('Dropout', '${summary['dropoutSignals']}', Icons.trending_down, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard() {
    final enrollment = _currentReport!['enrollment'] as Map<String, dynamic>;
    final byCenter = enrollment['byCenter'] as Map<String, int>? ?? {};
    final byClass = enrollment['byClass'] as Map<String, int>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👨‍🎓 Enrollment Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (byCenter.isNotEmpty && _selectedCenter == 'All Centers') ...[
              const Text('By Center:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...byCenter.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${entry.value} students', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
            
            if (byClass.isNotEmpty) ...[
              const Text('By Class:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...byClass.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${entry.value} students', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final attendance = _currentReport!['attendance'] as Map<String, dynamic>;
    final overall = attendance['overall'] as double? ?? 0.0;
    final monthWise = attendance['monthWise'] as Map<String, double>? ?? {};
    final centerWise = attendance['centerWise'] as Map<String, double>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Attendance Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: Column(
                children: [
                  Text(
                    '${overall.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: overall >= 75 ? Colors.green : overall >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const Text('Overall Attendance Rate'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (centerWise.isNotEmpty && _selectedCenter == 'All Centers') ...[
              const Text('By Center:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...centerWise.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value >= 75 ? Colors.green : entry.value >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text('${entry.value.toStringAsFixed(1)}%', textAlign: TextAlign.end),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCard() {
    final learning = _currentReport!['learning'] as Map<String, dynamic>;
    final averageMarks = learning['averageMarksBySubject'] as Map<String, double>? ?? {};
    final passFailRatio = learning['passFailRatio'] as Map<String, Map<String, int>>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Learning & Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (averageMarks.isNotEmpty) ...[
              const Text('Average Marks by Subject:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...averageMarks.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${entry.value.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
            
            if (passFailRatio.isNotEmpty) ...[
              const Text('Pass Rate by Subject:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...passFailRatio.entries.map((entry) {
                final pass = entry.value['pass'] ?? 0;
                final fail = entry.value['fail'] ?? 0;
                final total = pass + fail;
                final passRate = total > 0 ? (pass / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text('${passRate.toStringAsFixed(1)}% ($pass/$total)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysisCard() {
    final risks = _currentReport!['risks'] as Map<String, dynamic>;
    final atRiskStudents = risks['atRiskStudents'] as List<Student>? ?? [];
    final dropoutSignals = risks['dropoutSignals'] as List<Map<String, dynamic>>? ?? [];
    final decliningPerformance = risks['decliningPerformance'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Risk Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildRiskStat('At Risk\nStudents', atRiskStudents.length, Colors.orange),
                _buildRiskStat('Dropout\nSignals', dropoutSignals.length, Colors.red),
                _buildRiskStat('Declining\nPerformance', decliningPerformance.length, Colors.purple),
              ],
            ),
            
            if (dropoutSignals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('High-Risk Students:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...dropoutSignals.take(3).map((signal) {
                final student = signal['student'] as Student;
                final consecutiveAbsences = signal['consecutiveAbsences'] as int;
                final riskLevel = signal['riskLevel'] as String;
                
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: riskLevel == 'High' ? Colors.red : 
                                   riskLevel == 'Medium' ? Colors.orange : Colors.yellow,
                    child: Text(student.name[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(student.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text('${student.rollNo} - $consecutiveAbsences days absent', style: const TextStyle(fontSize: 12)),
                  trailing: Text(riskLevel, style: TextStyle(
                    color: riskLevel == 'High' ? Colors.red : 
                           riskLevel == 'Medium' ? Colors.orange : Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )),
                );
              }).toList(),
              if (dropoutSignals.length > 3)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('... and ${dropoutSignals.length - 3} more students at risk'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final insights = _currentReport!['insights'] as List<String>? ?? [];

    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Key Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(insight)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _currentReport!['recommendations'] as List<String>? ?? [];

    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Action Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskStat(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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

  Future<void> _shareReport() async {
    if (_currentReport == null) return;

    final reportText = MonthlyReportService.generateReportText(_currentReport!);
    final monthName = DateFormat('MMMM_yyyy').format(_currentReport!['reportMonth']);
    final centerName = _currentReport!['centerName'].toString().replaceAll(' ', '_');
    
    await Share.share(
      reportText,
      subject: 'Monthly Student Analytics Report - $monthName - $centerName',
    );
  }
}