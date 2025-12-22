import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/analytics_service.dart';
import 'package:samadhan_app/data/subjects_topics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StudentAnalyticsDashboardPage extends StatefulWidget {
  final String? centerName;

  const StudentAnalyticsDashboardPage({super.key, this.centerName});

  @override
  State<StudentAnalyticsDashboardPage> createState() => _StudentAnalyticsDashboardPageState();
}

class _StudentAnalyticsDashboardPageState extends State<StudentAnalyticsDashboardPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();
  String _selectedCenter = 'All Centers';
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    if (widget.centerName != null) {
      _selectedCenter = widget.centerName!;
    }
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);

    await Future.wait([
      studentProvider.fetchStudents(),
      attendanceProvider.fetchAttendanceRecords(),
      volunteerProvider.fetchReports(),
    ]);

    // Filter data by selected center
    List<Student> students = _selectedCenter == 'All Centers'
        ? studentProvider.students
        : studentProvider.students.where((s) => s.centerName == _selectedCenter).toList();

    // Get attendance records for date range
    final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByDateRange(_startDate, _endDate);
    final filteredAttendance = _selectedCenter == 'All Centers'
        ? attendanceRecords
        : attendanceRecords.where((r) => r.centerName == _selectedCenter).toList();

    final volunteerReports = volunteerProvider.reports;
    final filteredReports = _selectedCenter == 'All Centers'
        ? volunteerReports
        : volunteerReports.where((r) => r.centerName == _selectedCenter).toList();

    // Generate comprehensive analytics
    final analytics = AnalyticsService.generateStudentAnalyticsSummary(
      students,
      filteredAttendance,
      filteredReports,
      SubjectsTopics.subjectsWithTopics,
    );

    setState(() {
      _analyticsData = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Analytics Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFiltersCard(),
                    const SizedBox(height: 16),
                    _buildEnrollmentOverviewCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceAnalyticsCard(),
                    const SizedBox(height: 16),
                    _buildLearningCoverageCard(),
                    const SizedBox(height: 16),
                    _buildTestPerformanceCard(),
                    const SizedBox(height: 16),
                    _buildRiskAnalysisCard(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                  ],
                ),
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
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
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
                        child: Text(center, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCenter = value!;
                      });
                      _loadAnalyticsData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      '${DateFormat('MM/dd').format(_startDate)} - ${DateFormat('MM/dd').format(_endDate)}',
                      style: const TextStyle(fontSize: 11),
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

  Widget _buildEnrollmentOverviewCard() {
    final enrollment = _analyticsData['enrollment'] as Map<String, dynamic>? ?? {};
    final total = enrollment['total'] as int? ?? 0;
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
              '👨‍🎓 Student Enrollment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Total Students
            Center(
              child: Column(
                children: [
                  Text(
                    total.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text('Total Students'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Enrollment by Center Chart
            if (byCenter.isNotEmpty) ...[
              const Text(
                'Enrollment by Center',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: byCenter.entries.map((entry) {
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${entry.key}\n${entry.value}\n(${percentage.toStringAsFixed(1)}%)',
                        color: _getColorForIndex(byCenter.keys.toList().indexOf(entry.key)),
                        radius: 80,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Enrollment by Class
            if (byClass.isNotEmpty) ...[
              const Text(
                'Enrollment by Class',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...byClass.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForIndex(byClass.keys.toList().indexOf(entry.key)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}'),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceAnalyticsCard() {
    final attendance = _analyticsData['attendance'] as Map<String, dynamic>? ?? {};
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
              '📊 Attendance Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Overall Attendance
            Center(
              child: Column(
                children: [
                  Text(
                    '${overall.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: overall >= 75 ? Colors.green : overall >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const Text('Overall Attendance'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Month-wise Attendance Trend
            if (monthWise.isNotEmpty) ...[
              const Text(
                'Month-wise Attendance Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final months = monthWise.keys.toList()..sort();
                            if (value.toInt() >= 0 && value.toInt() < months.length) {
                              final month = months[value.toInt()];
                              return Text(month.substring(5), style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: () {
                          final months = monthWise.keys.toList()..sort();
                          return months.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), monthWise[entry.value]!);
                          }).toList();
                        }(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Center-wise Attendance
            if (centerWise.isNotEmpty && _selectedCenter == 'All Centers') ...[
              const Text(
                'Center-wise Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...centerWise.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
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
                    Text('${entry.value.toStringAsFixed(1)}%'),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCoverageCard() {
    final learning = _analyticsData['learning'] as Map<String, dynamic>? ?? {};
    final coverage = learning['coverage'] as Map<Student, Map<String, double>>? ?? {};

    if (coverage.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No learning coverage data available'),
          ),
        ),
      );
    }

    // Calculate average coverage per subject
    final Map<String, double> subjectAverages = {};
    final Map<String, int> subjectCounts = {};

    coverage.forEach((student, subjects) {
      subjects.forEach((subject, percentage) {
        subjectAverages[subject] = (subjectAverages[subject] ?? 0) + percentage;
        subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
      });
    });

    subjectAverages.forEach((subject, total) {
      subjectAverages[subject] = total / subjectCounts[subject]!;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Learning Coverage (% Syllabus Completed)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Average coverage across all subjects
            Center(
              child: Column(
                children: [
                  Text(
                    '${subjectAverages.values.isEmpty ? 0 : (subjectAverages.values.reduce((a, b) => a + b) / subjectAverages.length).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const Text('Average Syllabus Coverage'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Subject-wise coverage
            const Text(
              'Subject-wise Coverage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...subjectAverages.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key),
                  ),
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
                  Text('${entry.value.toStringAsFixed(1)}%'),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPerformanceCard() {
    final learning = _analyticsData['learning'] as Map<String, dynamic>? ?? {};
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
              '🎯 Test Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (averageMarks.isNotEmpty) ...[
              // Overall average
              Center(
                child: Column(
                  children: [
                    Text(
                      '${averageMarks.values.isEmpty ? 0 : (averageMarks.values.reduce((a, b) => a + b) / averageMarks.length).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Text('Overall Average Marks'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Subject-wise average marks
              const Text(
                'Average Marks by Subject',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            final subjects = averageMarks.keys.toList();
                            if (value.toInt() >= 0 && value.toInt() < subjects.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  subjects[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: averageMarks.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final average = entry.value.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: average,
                            color: average >= 75 ? Colors.green : average >= 50 ? Colors.orange : Colors.red,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Pass/Fail Ratio
            if (passFailRatio.isNotEmpty) ...[
              const Text(
                'Pass/Fail Ratio by Subject',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...passFailRatio.entries.map((entry) {
                final pass = entry.value['pass'] ?? 0;
                final fail = entry.value['fail'] ?? 0;
                final total = pass + fail;
                final passRate = total > 0 ? (pass / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: passRate / 100,
                          backgroundColor: Colors.red.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${passRate.toStringAsFixed(1)}% ($pass/$total)'),
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
    final risks = _analyticsData['risks'] as Map<String, dynamic>? ?? {};
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
            
            // Risk Summary
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildRiskStat('At Risk\n(Low Attendance)', atRiskStudents.length, Colors.orange),
                _buildRiskStat('Dropout\nSignals', dropoutSignals.length, Colors.red),
                _buildRiskStat('Declining\nPerformance', decliningPerformance.length, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            
            // Dropout Signals Details
            if (dropoutSignals.isNotEmpty) ...[
              const Text(
                'Students with Dropout Signals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...dropoutSignals.take(5).map((signal) {
                final student = signal['student'] as Student;
                final consecutiveAbsences = signal['consecutiveAbsences'] as int;
                final riskLevel = signal['riskLevel'] as String;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: riskLevel == 'High' ? Colors.red : 
                                   riskLevel == 'Medium' ? Colors.orange : Colors.yellow,
                    child: Text(student.name[0].toUpperCase()),
                  ),
                  title: Text(student.name),
                  subtitle: Text('${student.rollNo} - ${student.classBatch}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$consecutiveAbsences days',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskLevel == 'High' ? Colors.red : 
                                 riskLevel == 'Medium' ? Colors.orange : Colors.yellow,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (dropoutSignals.length > 5)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('... and ${dropoutSignals.length - 5} more'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final insights = _analyticsData['insights'] as List<String>? ?? [];

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

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

  Widget _buildRiskStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalyticsData();
    }
  }
}