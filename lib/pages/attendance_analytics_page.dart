import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/services/analytics_service.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedClass;
  String _sortBy = 'lowest'; // 'lowest' or 'highest'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.fetchAttendanceRecords();
    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2C3E50)),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Color(0xFF2C3E50)),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeCard(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _buildAttendanceTrendChart(),
                    const SizedBox(height: 16),
                    _buildDayWisePatterns(),
                    const SizedBox(height: 16),
                    _buildClassComparison(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                    const SizedBox(height: 16),
                    _buildStudentWiseAttendance(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    
    // Get unique classes
    final classes = centerStudents.map((s) => s.classBatch).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Classes')),
                    ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedClass = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lowest', child: Text('Lowest First')),
                    DropdownMenuItem(value: 'highest', child: Text('Highest First')),
                  ],
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrendChart() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    var centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    if (_selectedClass != null) {
      centerStudents = centerStudents.where((s) => s.classBatch == _selectedClass).toList();
    }

    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return _buildEmptyCard('No attendance data for selected period');
    }

    final trendData = AnalyticsService.getAttendanceTrend(
      attendanceRecords,
      centerStudents.length,
    );

    final sortedDates = trendData.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), trendData[entry.value]!);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
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
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWisePatterns() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    var centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    if (_selectedClass != null) {
      centerStudents = centerStudents.where((s) => s.classBatch == _selectedClass).toList();
    }

    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final dayPattern = AnalyticsService.getDayWiseAttendancePattern(
      attendanceRecords,
      centerStudents.length,
    );

    final bestWorst = AnalyticsService.getBestWorstDays(
      attendanceRecords,
      centerStudents.length,
    );

    if (dayPattern.isEmpty) {
      return const SizedBox.shrink();
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 1; i <= 7; i++) {
      if (dayPattern.containsKey(i)) {
        barGroups.add(
          BarChartGroupData(
            x: i - 1,
            barRods: [
              BarChartRodData(
                toY: dayPattern[i]!,
                color: dayPattern[i]! >= 75
                    ? Colors.green
                    : dayPattern[i]! >= 50
                        ? Colors.orange
                        : Colors.red,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Day-wise Attendance Patterns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 10),
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
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
              ),
            ),
          ),
          if (bestWorst['best'] != null && bestWorst['worst'] != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green.shade700),
                        const SizedBox(height: 4),
                        Text(
                          'Best Day',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          bestWorst['best']['day'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          '${bestWorst['best']['percentage'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.trending_down, color: Colors.red.shade700),
                        const SizedBox(height: 4),
                        Text(
                          'Worst Day',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          bestWorst['worst']['day'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        Text(
                          '${bestWorst['worst']['percentage'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassComparison() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final classWiseData = AnalyticsService.getClassWiseAttendance(
      centerStudents,
      attendanceRecords,
    );

    if (classWiseData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create bar chart data
    final sortedClasses = classWiseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final barGroups = sortedClasses.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: entry.value.value >= 75
                ? Colors.green
                : entry.value.value >= 50
                    ? Colors.orange
                    : Colors.red,
            width: 30,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class-wise Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedClasses.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedClasses[value.toInt()].key,
                              style: const TextStyle(fontSize: 10),
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
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    var centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    if (_selectedClass != null) {
      centerStudents = centerStudents.where((s) => s.classBatch == _selectedClass).toList();
    }

    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final insights = <String>[];
    
    // At-risk students
    final atRiskStudents = AnalyticsService.getAtRiskStudents(centerStudents, attendanceRecords);
    if (atRiskStudents.isNotEmpty) {
      insights.add('${atRiskStudents.length} student${atRiskStudents.length > 1 ? 's have' : ' has'} <50% attendance (needs intervention)');
    }

    // Day-wise patterns
    final dayPattern = AnalyticsService.getDayWiseAttendancePattern(attendanceRecords, centerStudents.length);
    if (dayPattern.isNotEmpty) {
      final bestWorst = AnalyticsService.getBestWorstDays(attendanceRecords, centerStudents.length);
      if (bestWorst['best'] != null && bestWorst['worst'] != null) {
        final bestDay = bestWorst['best']['day'];
        final worstDay = bestWorst['worst']['day'];
        final bestPct = bestWorst['best']['percentage'];
        final worstPct = bestWorst['worst']['percentage'];
        final diff = bestPct - worstPct;
        
        if (diff > 10) {
          insights.add('${worstDay}s have ${diff.toStringAsFixed(0)}% lower attendance than other days');
        }
        insights.add('Best attendance day: $bestDay (${bestPct.toStringAsFixed(0)}%)');
      }
    }

    // Class improvement
    final classWiseData = AnalyticsService.getClassWiseAttendance(centerStudents, attendanceRecords);
    if (classWiseData.isNotEmpty) {
      final topClass = classWiseData.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topClass.value >= 80) {
        insights.add('${topClass.key} has excellent attendance (${topClass.value.toStringAsFixed(0)}%)');
      }
      
      final needsAttention = classWiseData.entries.where((e) => e.value < 60).toList();
      if (needsAttention.isNotEmpty) {
        insights.add('${needsAttention.map((e) => e.key).join(', ')} need${needsAttention.length == 1 ? 's' : ''} attention');
      }
    }

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                '🎯 Key Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.blue.shade700)),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStudentWiseAttendance() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    var centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    if (_selectedClass != null) {
      centerStudents = centerStudents.where((s) => s.classBatch == _selectedClass).toList();
    }

    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty || centerStudents.isEmpty) {
      return const SizedBox.shrink();
    }

    final percentages = AnalyticsService.getStudentAttendancePercentages(
      centerStudents,
      attendanceRecords,
    );

    // Sort students
    var sortedStudents = percentages.entries.toList();
    if (_sortBy == 'lowest') {
      sortedStudents.sort((a, b) => a.value.compareTo(b.value));
    } else {
      sortedStudents.sort((a, b) => b.value.compareTo(a.value));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student-wise Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${sortedStudents.length} students',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedStudents.map((entry) {
            final student = entry.key;
            final percentage = entry.value;
            final color = percentage >= 75
                ? Colors.green
                : percentage >= 50
                    ? Colors.orange
                    : Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    radius: 20,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Roll: ${student.rollNo} | Class: ${student.classBatch}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        percentage >= 75
                            ? 'Good'
                            : percentage >= 50
                                ? 'Average'
                                : 'At Risk',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
