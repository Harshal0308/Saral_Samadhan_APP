import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/services/analytics_service.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    await Future.wait([
      attendanceProvider.fetchAttendanceRecords(),
      volunteerProvider.fetchReports(),
    ]);
    
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
          'Analytics Dashboard',
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
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildDayWiseAttendanceChart(),
                    const SizedBox(height: 16),
                    _buildClassWiseAttendanceChart(),
                    const SizedBox(height: 16),
                    _buildAtRiskStudentsCount(),
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

  Widget _buildSummaryCards() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    // Filter data by center and date range, sorted by name first (A-Z)
    final centerStudents = studentProvider.getStudentsByCenterSortedByName(selectedCenter);
    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    final attendancePercentage = AnalyticsService.calculateAttendancePercentage(
      attendanceRecords,
      centerStudents.length,
    );

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '📈 Attendance',
            '${attendancePercentage.toStringAsFixed(1)}%',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '👥 Total Students',
            '${centerStudents.length}',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWiseAttendanceChart() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final centerStudents = studentProvider.getStudentsByCenterSortedByName(selectedCenter);
    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return _buildEmptyCard('No attendance data for selected period');
    }

    // Group attendance by date
    final dateWiseData = <DateTime, Map<String, int>>{};
    for (final record in attendanceRecords) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      dateWiseData[date] ??= {'present': 0, 'absent': 0};

      // Count present and absent from the attendance map
      record.attendance.forEach((studentId, isPresent) {
        if (isPresent) {
          dateWiseData[date]!['present'] = (dateWiseData[date]!['present'] ?? 0) + 1;
        } else {
          dateWiseData[date]!['absent'] = (dateWiseData[date]!['absent'] ?? 0) + 1;
        }
      });
    }

    final sortedDates = dateWiseData.keys.toList()..sort();
    final barGroups = sortedDates.asMap().entries.map((entry) {
      final date = entry.key;
      final data = dateWiseData[sortedDates[date]]!;
      final present = data['present'] ?? 0;
      final absent = data['absent'] ?? 0;

      return BarChartGroupData(
        x: date,
        barRods: [
          BarChartRodData(
            toY: present.toDouble(),
            color: Colors.green,
            width: 16,
          ),
          BarChartRodData(
            toY: absent.toDouble(),
            color: Colors.red,
            width: 16,
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
            'Day-wise Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              const Text('Present', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              const Text('Absent', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: sortedDates.length * 60.0, // Dynamic width based on number of dates
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: centerStudents.length.toDouble(),
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            interval: sortedDates.length > 10 ? (sortedDates.length / 5).ceil().toDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                                final date = sortedDates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskStudentsCount() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final centerStudents = studentProvider.getStudentsByCenterSortedByName(selectedCenter);
    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    final atRiskStudentsDetailed = AnalyticsService.getAtRiskStudentsDetailed(
      centerStudents,
      attendanceRecords,
    );

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
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Students Needing Attention',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${atRiskStudentsDetailed.length} students with attendance below 75%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${atRiskStudentsDetailed.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (atRiskStudentsDetailed.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: atRiskStudentsDetailed.length > 10 
                  ? 10 
                  : atRiskStudentsDetailed.length,
              itemBuilder: (context, index) {
                final data = atRiskStudentsDetailed[index];
                final student = data['student'] as Student;
                final percentage = data['attendancePercentage'] as double;
                final reason = data['reason'] as String;
                
                Color percentageColor;
                if (percentage < 50) {
                  percentageColor = Colors.red;
                } else if (percentage < 65) {
                  percentageColor = Colors.orange;
                } else {
                  percentageColor = Colors.amber.shade700;
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: percentageColor.withOpacity(0.2),
                        child: Text(
                          student.name.isNotEmpty 
                              ? student.name[0].toUpperCase() 
                              : '?',
                          style: TextStyle(
                            color: percentageColor,
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
                            const SizedBox(height: 2),
                            Text(
                              'Class ${student.classBatch} • Roll: ${student.rollNo}',
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: percentageColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: percentageColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Attendance',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            if (atRiskStudentsDetailed.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+ ${atRiskStudentsDetailed.length - 10} more students',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassWiseAttendanceChart() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final centerStudents = studentProvider.getStudentsByCenterSortedByName(selectedCenter);
    final attendanceRecords = attendanceProvider.attendanceRecords.where((record) {
      return record.centerName == selectedCenter &&
          !record.date.isBefore(_startDate) &&
          !record.date.isAfter(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group students by class and calculate attendance
    final classWiseData = <String, Map<String, int>>{};
    for (final student in centerStudents) {
      final className = student.classBatch;
      classWiseData[className] ??= {'present': 0, 'absent': 0, 'total': 0};
      classWiseData[className]!['total'] = (classWiseData[className]!['total'] ?? 0) + 1;
    }

    // Calculate attendance for each class
    for (final record in attendanceRecords) {
      // Iterate through each student in the attendance record
      record.attendance.forEach((studentIdStr, isPresent) {
        final studentId = int.tryParse(studentIdStr);
        if (studentId == null) return;

        final student = centerStudents.firstWhere(
          (s) => s.id == studentId,
          orElse: () => Student(id: -1, name: '', rollNo: '', classBatch: '', centerName: ''),
        );
        if (student.id != -1 && classWiseData.containsKey(student.classBatch)) {
          if (isPresent) {
            classWiseData[student.classBatch]!['present'] =
                (classWiseData[student.classBatch]!['present'] ?? 0) + 1;
          } else {
            classWiseData[student.classBatch]!['absent'] =
                (classWiseData[student.classBatch]!['absent'] ?? 0) + 1;
          }
        }
      });
    }

    if (classWiseData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedClasses = classWiseData.keys.toList()..sort();
    final barGroups = sortedClasses.asMap().entries.map((entry) {
      final className = entry.key;
      final data = classWiseData[sortedClasses[className]]!;
      final present = data['present'] ?? 0;
      final absent = data['absent'] ?? 0;

      return BarChartGroupData(
        x: className,
        barRods: [
          BarChartRodData(
            toY: present.toDouble(),
            color: Colors.green,
            width: 16,
          ),
          BarChartRodData(
            toY: absent.toDouble(),
            color: Colors.red,
            width: 16,
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
            'Class-wise Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              const Text('Present', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              const Text('Absent', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: sortedClasses.length * 60.0, // Dynamic width based on number of classes
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: centerStudents.length.toDouble(),
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            interval: sortedClasses.length > 8 ? (sortedClasses.length / 4).ceil().toDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < sortedClasses.length) {
                                final className = sortedClasses[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    className.length > 8 ? '${className.substring(0, 8)}...' : className,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
