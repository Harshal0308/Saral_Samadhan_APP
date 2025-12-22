import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CenterVolunteerAnalyticsPage extends StatefulWidget {
  const CenterVolunteerAnalyticsPage({super.key});

  @override
  State<CenterVolunteerAnalyticsPage> createState() => _CenterVolunteerAnalyticsPageState();
}

class _CenterVolunteerAnalyticsPageState extends State<CenterVolunteerAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to handle tab changes properly
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Force rebuild when tab is changing to ensure proper display
        setState(() {});
      }
    });
    
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);

      await Future.wait([
        studentProvider.fetchStudents(),
        attendanceProvider.fetchAttendanceRecords(),
        volunteerProvider.fetchReports(),
      ]);

      final students = studentProvider.students;
      final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByDateRange(_startDate, _endDate);
      final volunteerReports = volunteerProvider.reports;

      // Generate comprehensive analytics
      final analytics = {
        // Center Analytics
        'centerAttendanceComparison': AnalyticsService.getCenterAttendanceComparison(students, attendanceRecords),
        'centerPerformanceComparison': AnalyticsService.getCenterPerformanceComparison(students, volunteerReports),
        'centerVolunteerAnalysis': AnalyticsService.getCenterVolunteerAnalysis(students, volunteerReports),
        'centerClassPerformance': AnalyticsService.getCenterClassPerformance(students, attendanceRecords),
        'centerResourceUtilization': AnalyticsService.getCenterResourceUtilization(attendanceRecords, _startDate, _endDate),
        'centersNeedingIntervention': AnalyticsService.getCentersNeedingIntervention(students, attendanceRecords, volunteerReports),
        
        // Volunteer Analytics
        'volunteerContribution': AnalyticsService.getVolunteerContributionAnalysis(volunteerReports),
        'volunteerSessions': AnalyticsService.getVolunteerSessionAnalysis(volunteerReports),
        'volunteerSubjects': AnalyticsService.getVolunteerSubjectDistribution(volunteerReports),
        'volunteerImpact': AnalyticsService.getVolunteerImpactAnalysis(students, volunteerReports),
        'volunteerConsistency': AnalyticsService.getVolunteerConsistencyAnalysis(volunteerReports, _startDate),
        'topImpactVolunteers': AnalyticsService.getTopImpactVolunteers(students, volunteerReports),
        
        // Diagnostic Analytics
        'attendanceDropAnalysis': AnalyticsService.getAttendanceDropAnalysis(students, attendanceRecords, volunteerReports),
        'learningOutcomeDiagnosis': AnalyticsService.getLearningOutcomeDiagnosis(students, attendanceRecords, volunteerReports),
      };

      setState(() {
        _analyticsData = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Center & Volunteer Analytics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          tabs: const [
            Tab(text: 'Centers', icon: Icon(Icons.business)),
            Tab(text: 'Volunteers', icon: Icon(Icons.people)),
            Tab(text: 'Diagnostics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
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
                  Text('Analyzing center and volunteer data...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Prevent swipe gestures that might cause issues
              children: [
                _buildCenterAnalyticsTab(),
                _buildVolunteerAnalyticsTab(),
                _buildDiagnosticsTab(),
              ],
            ),
    );
  }

  Widget _buildCenterAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeCard(),
            const SizedBox(height: 16),
            _buildCenterComparisonCard(),
            const SizedBox(height: 16),
            _buildCenterPerformanceCard(),
            const SizedBox(height: 16),
            _buildResourceUtilizationCard(),
            const SizedBox(height: 16),
            _buildInterventionNeededCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeCard(),
            const SizedBox(height: 16),
            _buildTopVolunteersCard(),
            const SizedBox(height: 16),
            _buildVolunteerContributionCard(),
            const SizedBox(height: 16),
            _buildVolunteerImpactCard(),
            const SizedBox(height: 16),
            _buildVolunteerConsistencyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeCard(),
            const SizedBox(height: 16),
            _buildAttendanceDropAnalysisCard(),
            const SizedBox(height: 16),
            _buildLearningOutcomeDiagnosisCard(),
            const SizedBox(height: 16),
            _buildCorrelationAnalysisCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${DateFormat('MM/dd/yy').format(_startDate)} - ${DateFormat('MM/dd/yy').format(_endDate)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _selectDateRange(context),
              child: const Text('Change', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterComparisonCard() {
    final centerComparison = _analyticsData['centerAttendanceComparison'] as Map<String, Map<String, dynamic>>? ?? {};

    if (centerComparison.isEmpty) {
      return _buildEmptyCard('No center data available');
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
              '🏫 Center Attendance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Center comparison chart
            SizedBox(
              height: 300,
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
                          final centers = centerComparison.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < centers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                centers[value.toInt()],
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
                  barGroups: centerComparison.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final centerData = entry.value.value;
                    final attendanceRate = centerData['attendanceRate'] as double;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: attendanceRate,
                          color: attendanceRate >= 75 ? Colors.green : attendanceRate >= 50 ? Colors.orange : Colors.red,
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Center details
            ...centerComparison.entries.map((entry) {
              final centerName = entry.key;
              final data = entry.value;
              final attendanceRate = data['attendanceRate'] as double;
              final totalStudents = data['totalStudents'] as int;
              final sessionsHeld = data['sessionsHeld'] as int;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(centerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('$totalStudents students'),
                    ),
                    Expanded(
                      child: Text('$sessionsHeld sessions'),
                    ),
                    Expanded(
                      child: Text(
                        '${attendanceRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: attendanceRate >= 75 ? Colors.green : attendanceRate >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPerformanceCard() {
    final centerPerformance = _analyticsData['centerPerformanceComparison'] as Map<String, Map<String, dynamic>>? ?? {};

    if (centerPerformance.isEmpty) {
      return _buildEmptyCard('No performance data available');
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
              '📊 Center Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...centerPerformance.entries.map((entry) {
              final centerName = entry.key;
              final data = entry.value;
              final averageScore = data['averageScore'] as double;
              final passRate = data['passRate'] as double;
              final totalTests = data['totalTests'] as int;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        centerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildMetricColumn('Avg', '${averageScore.toStringAsFixed(0)}%', 
                              averageScore >= 75 ? Colors.green : averageScore >= 50 ? Colors.orange : Colors.red)),
                          Expanded(child: _buildMetricColumn('Pass', '${passRate.toStringAsFixed(0)}%', 
                              passRate >= 75 ? Colors.green : passRate >= 50 ? Colors.orange : Colors.red)),
                          Expanded(child: _buildMetricColumn('Tests', totalTests.toString(), Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceUtilizationCard() {
    final resourceUtilization = _analyticsData['centerResourceUtilization'] as Map<String, Map<String, dynamic>>? ?? {};

    if (resourceUtilization.isEmpty) {
      return _buildEmptyCard('No resource utilization data available');
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
              '⚡ Resource Utilization (Sessions Conducted vs Planned)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...resourceUtilization.entries.map((entry) {
              final centerName = entry.key;
              final data = entry.value;
              final plannedSessions = data['plannedSessions'] as int;
              final sessionsHeld = data['sessionsHeld'] as int;
              final utilizationRate = data['utilizationRate'] as double;
              final missedSessions = data['missedSessions'] as int;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(centerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${utilizationRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: utilizationRate >= 80 ? Colors.green : utilizationRate >= 60 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: utilizationRate / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        utilizationRate >= 80 ? Colors.green : utilizationRate >= 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sessionsHeld held / $plannedSessions planned ($missedSessions missed)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionNeededCard() {
    final interventions = _analyticsData['centersNeedingIntervention'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 Centers Needing Intervention',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (interventions.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text('All centers are performing well!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ...interventions.map((intervention) {
                final centerName = intervention['centerName'] as String;
                final priority = intervention['priority'] as String;
                final issues = intervention['issues'] as List<String>;
                final attendanceRate = intervention['attendanceRate'] as double;
                final totalStudents = intervention['totalStudents'] as int;
                
                Color priorityColor = Colors.orange;
                if (priority == 'High') priorityColor = Colors.red;
                if (priority == 'Low') priorityColor = Colors.yellow[700]!;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: priorityColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              centerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$priority Priority',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$totalStudents students • ${attendanceRate.toStringAsFixed(1)}% attendance'),
                        const SizedBox(height: 8),
                        ...issues.map((issue) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(issue)),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVolunteersCard() {
    final topVolunteers = _analyticsData['topImpactVolunteers'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Top Impact Volunteers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (topVolunteers.isEmpty)
              _buildEmptyCard('No volunteer data available')
            else
              ...topVolunteers.take(5).map((volunteer) {
                final name = volunteer['volunteerName'] as String;
                final impactScore = volunteer['impactScore'] as double;
                final totalHours = volunteer['totalHours'] as double;
                final studentsImpacted = volunteer['studentsImpacted'] as int;
                final averageScore = volunteer['averageScore'] as double;
                final sessionsCount = volunteer['sessionsCount'] as int;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${totalHours.toStringAsFixed(1)}h • $studentsImpacted students • $sessionsCount sessions'),
                              if (averageScore > 0)
                                Text('Avg student score: ${averageScore.toStringAsFixed(1)}%'),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${impactScore.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                            const Text('Impact Score', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerContributionCard() {
    final volunteerContribution = _analyticsData['volunteerContribution'] as Map<String, Map<String, dynamic>>? ?? {};

    if (volunteerContribution.isEmpty) {
      return _buildEmptyCard('No volunteer contribution data available');
    }

    // Calculate totals
    double totalHours = 0;
    int totalSessions = 0;
    Set<int> allStudentsImpacted = {};
    
    volunteerContribution.forEach((name, data) {
      totalHours += data['totalHours'] as double;
      totalSessions += data['sessionsCount'] as int;
      allStudentsImpacted.addAll(data['studentsImpacted'] as Set<int>);
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
              '🤝 Volunteer Contribution Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Summary stats
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildMetricColumn('Hours', '${totalHours.toStringAsFixed(0)}h', Colors.blue),
                _buildMetricColumn('Sessions', totalSessions.toString(), Colors.green),
                _buildMetricColumn('Students', allStudentsImpacted.length.toString(), Colors.orange),
                _buildMetricColumn('Volunteers', volunteerContribution.length.toString(), Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            
            // Top contributors by hours
            const Text('Top Contributors by Hours:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...(volunteerContribution.entries.toList()
                ..sort((a, b) => (b.value['totalHours'] as double).compareTo(a.value['totalHours'] as double)))
                .take(5)
                .map((entry) {
                  final name = entry.key;
                  final data = entry.value;
                  final hours = data['totalHours'] as double;
                  final sessions = data['sessionsCount'] as int;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name),
                        Text('${hours.toStringAsFixed(1)}h ($sessions sessions)'),
                      ],
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerImpactCard() {
    final volunteerImpact = _analyticsData['volunteerImpact'] as Map<String, Map<String, dynamic>>? ?? {};

    if (volunteerImpact.isEmpty) {
      return _buildEmptyCard('No volunteer impact data available');
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
              '📈 Volunteer Impact Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...(volunteerImpact.entries
                .where((entry) => (entry.value['averageScore'] as double) > 0)
                .toList()
                ..sort((a, b) => (b.value['averageScore'] as double).compareTo(a.value['averageScore'] as double)))
                .take(5)
                .map((entry) {
                  final name = entry.key;
                  final data = entry.value;
                  final averageScore = data['averageScore'] as double;
                  final passRate = data['passRate'] as double;
                  final studentsCount = data['studentsImpactedCount'] as int;
                  final testsGiven = data['testsGiven'] as int;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              _buildMetricColumn('Avg', '${averageScore.toStringAsFixed(0)}%', 
                                  averageScore >= 75 ? Colors.green : averageScore >= 50 ? Colors.orange : Colors.red),
                              _buildMetricColumn('Pass', '${passRate.toStringAsFixed(0)}%', 
                                  passRate >= 75 ? Colors.green : passRate >= 50 ? Colors.orange : Colors.red),
                              _buildMetricColumn('Students', studentsCount.toString(), Colors.blue),
                              _buildMetricColumn('Tests', testsGiven.toString(), Colors.purple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerConsistencyCard() {
    final volunteerConsistency = _analyticsData['volunteerConsistency'] as Map<String, Map<String, dynamic>>? ?? {};

    if (volunteerConsistency.isEmpty) {
      return _buildEmptyCard('No volunteer consistency data available');
    }

    // Separate by risk level
    final highRisk = <String, Map<String, dynamic>>{};
    final mediumRisk = <String, Map<String, dynamic>>{};
    final lowRisk = <String, Map<String, dynamic>>{};

    volunteerConsistency.forEach((name, data) {
      final riskLevel = data['riskLevel'] as String;
      if (riskLevel == 'High') {
        highRisk[name] = data;
      } else if (riskLevel == 'Medium') {
        mediumRisk[name] = data;
      } else {
        lowRisk[name] = data;
      }
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
              '⏰ Volunteer Consistency Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Risk summary
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildRiskStat('High Risk', highRisk.length, Colors.red),
                _buildRiskStat('Medium Risk', mediumRisk.length, Colors.orange),
                _buildRiskStat('Low Risk', lowRisk.length, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            
            // High risk volunteers
            if (highRisk.isNotEmpty) ...[
              const Text('High Risk Volunteers:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              const SizedBox(height: 8),
              ...highRisk.entries.map((entry) {
                final name = entry.key;
                final data = entry.value;
                final daysSinceLastSession = data['daysSinceLastSession'] as int;
                final maxGap = data['maxGapDays'] as int;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name),
                      Text('$daysSinceLastSession days since last session (max gap: $maxGap days)', 
                           style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],
            
            // Medium risk volunteers
            if (mediumRisk.isNotEmpty) ...[
              const Text('Medium Risk Volunteers:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
              const SizedBox(height: 8),
              ...mediumRisk.entries.take(3).map((entry) {
                final name = entry.key;
                final data = entry.value;
                final daysSinceLastSession = data['daysSinceLastSession'] as int;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name),
                      Text('$daysSinceLastSession days since last session', 
                           style: const TextStyle(color: Colors.orange)),
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

  Widget _buildAttendanceDropAnalysisCard() {
    final attendanceDropAnalysis = _analyticsData['attendanceDropAnalysis'] as Map<String, dynamic>? ?? {};

    if (attendanceDropAnalysis.isEmpty) {
      return _buildEmptyCard('No attendance drop analysis data available');
    }

    final dayWiseAttendance = attendanceDropAnalysis['dayWiseAttendance'] as Map<String, double>? ?? {};
    final volunteerPresenceImpact = attendanceDropAnalysis['volunteerPresenceImpact'] as Map<String, double>? ?? {};
    final insights = attendanceDropAnalysis['insights'] as List<String>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📉 Attendance Drop Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Day-wise attendance
            if (dayWiseAttendance.isNotEmpty) ...[
              const Text('Attendance by Day of Week:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...dayWiseAttendance.entries.map((entry) {
                final day = entry.key;
                final percentage = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(day),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${percentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
            
            // Volunteer presence impact
            if (volunteerPresenceImpact.isNotEmpty) ...[
              const Text('Volunteer Presence Impact:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...volunteerPresenceImpact.entries.map((entry) {
                final presence = entry.key;
                final percentage = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(presence),
                      Text('${percentage.toStringAsFixed(1)}%', 
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             color: percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                           )),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
            
            // Insights
            if (insights.isNotEmpty) ...[
              const Text('Key Insights:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...insights.map((insight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(insight)),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLearningOutcomeDiagnosisCard() {
    final learningOutcomeDiagnosis = _analyticsData['learningOutcomeDiagnosis'] as Map<String, dynamic>? ?? {};

    if (learningOutcomeDiagnosis.isEmpty) {
      return _buildEmptyCard('No learning outcome diagnosis data available');
    }

    final correlationCoefficient = learningOutcomeDiagnosis['performanceAttendanceCorrelation'] as double? ?? 0.0;
    final subjectDifficulty = learningOutcomeDiagnosis['subjectDifficulty'] as Map<String, Map<String, dynamic>>? ?? {};
    final insights = learningOutcomeDiagnosis['insights'] as List<String>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Learning Outcome Diagnosis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Correlation coefficient
            Center(
              child: Column(
                children: [
                  Text(
                    '${(correlationCoefficient * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: correlationCoefficient > 0.5 ? Colors.green : 
                             correlationCoefficient > 0.3 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const Text('Attendance-Performance Correlation'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Subject difficulty
            if (subjectDifficulty.isNotEmpty) ...[
              const Text('Subject Difficulty Analysis:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...subjectDifficulty.entries.map((entry) {
                final subject = entry.key;
                final data = entry.value;
                final averageScore = data['averageScore'] as double;
                final difficultyLevel = data['difficultyLevel'] as String;
                final passRate = data['passRate'] as double;
                
                Color difficultyColor = Colors.green;
                if (difficultyLevel == 'Very Hard') difficultyColor = Colors.red;
                else if (difficultyLevel == 'Hard') difficultyColor = Colors.orange;
                else if (difficultyLevel == 'Medium') difficultyColor = Colors.yellow[700]!;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(subject),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: difficultyColor),
                          ),
                          child: Text(
                            difficultyLevel,
                            style: TextStyle(color: difficultyColor, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${averageScore.toStringAsFixed(1)}% avg'),
                      const SizedBox(width: 8),
                      Text('${passRate.toStringAsFixed(1)}% pass'),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
            
            // Insights
            if (insights.isNotEmpty) ...[
              const Text('Key Insights:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...insights.map((insight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(insight)),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationAnalysisCard() {
    final learningOutcomeDiagnosis = _analyticsData['learningOutcomeDiagnosis'] as Map<String, dynamic>? ?? {};
    final studentCorrelations = learningOutcomeDiagnosis['studentCorrelations'] as List<Map<String, dynamic>>? ?? [];

    if (studentCorrelations.isEmpty) {
      return _buildEmptyCard('No correlation data available');
    }

    // Group students by attendance ranges
    final lowAttendance = studentCorrelations.where((s) => (s['attendanceRate'] as double) < 60).toList();
    final mediumAttendance = studentCorrelations.where((s) => 
        (s['attendanceRate'] as double) >= 60 && (s['attendanceRate'] as double) < 80).toList();
    final highAttendance = studentCorrelations.where((s) => (s['attendanceRate'] as double) >= 80).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔗 Attendance vs Performance Correlation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Scatter plot would go here - for now showing key insights
            const Text('Key Findings:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            
            // Show findings based on attendance ranges
            if (lowAttendance.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final avgScore = lowAttendance.map((s) => s['averageScore'] as double).reduce((a, b) => a + b) / lowAttendance.length;
                  return Text('• Students with <60% attendance: ${avgScore.toStringAsFixed(1)}% average score (${lowAttendance.length} students)');
                },
              ),
            ],
            
            if (mediumAttendance.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final avgScore = mediumAttendance.map((s) => s['averageScore'] as double).reduce((a, b) => a + b) / mediumAttendance.length;
                  return Text('• Students with 60-80% attendance: ${avgScore.toStringAsFixed(1)}% average score (${mediumAttendance.length} students)');
                },
              ),
            ],
            
            if (highAttendance.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final avgScore = highAttendance.map((s) => s['averageScore'] as double).reduce((a, b) => a + b) / highAttendance.length;
                  return Text('• Students with >80% attendance: ${avgScore.toStringAsFixed(1)}% average score (${highAttendance.length} students)');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
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