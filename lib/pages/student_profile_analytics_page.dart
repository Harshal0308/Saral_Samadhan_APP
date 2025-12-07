import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class StudentProfileAnalyticsPage extends StatefulWidget {
  final Student student;

  const StudentProfileAnalyticsPage({super.key, required this.student});

  @override
  State<StudentProfileAnalyticsPage> createState() => _StudentProfileAnalyticsPageState();
}

class _StudentProfileAnalyticsPageState extends State<StudentProfileAnalyticsPage> {
  String _selectedSubject = 'All Subjects';
  List<String> _availableSubjects = ['All Subjects'];
  Map<String, List<TestScore>> _testScoresBySubject = {};
  List<AttendanceData> _attendanceData = [];
  Map<String, dynamic> _attendanceStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    // Load attendance data for last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
      widget.student.centerName,
      threeMonthsAgo,
      now,
    );
    
    // Process attendance data
    final compositeKey = '${widget.student.rollNo}_${widget.student.classBatch}';
    List<AttendanceData> attendanceList = [];
    int totalPresent = 0;
    int totalAbsent = 0;
    
    for (var record in attendanceRecords) {
      if (record.attendance.containsKey(compositeKey)) {
        final isPresent = record.attendance[compositeKey] == true;
        attendanceList.add(AttendanceData(
          date: record.date,
          isPresent: isPresent,
        ));
        if (isPresent) {
          totalPresent++;
        } else {
          totalAbsent++;
        }
      }
    }
    
    // Sort by date
    attendanceList.sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate attendance percentage
    final totalDays = totalPresent + totalAbsent;
    final attendancePercentage = totalDays > 0 ? (totalPresent / totalDays * 100) : 0.0;
    
    // Extract test scores by subject from test results
    Map<String, List<TestScore>> scoresBySubject = {};
    Set<String> subjects = {};
    
    // Parse test results (format: "Subject: Topic" -> "marks")
    widget.student.testResults.forEach((testTopic, marks) {
      String subject = 'General';
      String topic = testTopic;
      
      // Try to extract subject from "Subject: Topic" format
      if (testTopic.contains(':')) {
        final parts = testTopic.split(':');
        subject = parts[0].trim();
        topic = parts.length > 1 ? parts[1].trim() : testTopic;
      }
      
      subjects.add(subject);
      
      // Parse marks (could be numeric or grade)
      double? score;
      if (marks.contains('/')) {
        // Format: "8/10" or "15/20"
        final parts = marks.split('/');
        if (parts.length == 2) {
          final obtained = double.tryParse(parts[0].trim());
          final total = double.tryParse(parts[1].trim());
          if (obtained != null && total != null && total > 0) {
            score = (obtained / total) * 100; // Convert to percentage
          }
        }
      } else {
        // Try direct numeric parse
        score = double.tryParse(marks);
      }
      
      if (score != null) {
        if (!scoresBySubject.containsKey(subject)) {
          scoresBySubject[subject] = [];
        }
        scoresBySubject[subject]!.add(TestScore(
          topic: topic,
          score: score,
          date: DateTime.now(), // We don't have exact date, use current
        ));
      }
    });
    
    setState(() {
      _attendanceData = attendanceList;
      _attendanceStats = {
        'totalDays': totalDays,
        'present': totalPresent,
        'absent': totalAbsent,
        'percentage': attendancePercentage,
      };
      _testScoresBySubject = scoresBySubject;
      _availableSubjects = ['All Subjects', ...subjects.toList()..sort()];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Analytics'),
        backgroundColor: SaralColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card
            _buildStudentInfoCard(),
            const SizedBox(height: 16),
            
            // Attendance Analytics
            _buildAttendanceAnalyticsCard(),
            const SizedBox(height: 16),
            
            // Test Performance Analytics
            _buildTestPerformanceCard(),
            const SizedBox(height: 16),
            
            // Lessons Learned
            _buildLessonsLearnedCard(),
            const SizedBox(height: 16),
            
            // Subject-wise Performance
            _buildSubjectWisePerformanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: SaralColors.accent,
              child: Text(
                widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Roll No: ${widget.student.rollNo}'),
                  Text('Class: ${widget.student.classBatch}'),
                  Text('Center: ${widget.student.centerName}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceAnalyticsCard() {
    if (_attendanceData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No attendance data available'),
          ),
        ),
      );
    }

    final stats = _attendanceStats;
    final percentage = stats['percentage'] as double;
    final totalDays = stats['totalDays'] as int;
    final present = stats['present'] as int;
    final absent = stats['absent'] as int;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Attendance Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Days', totalDays.toString(), Colors.blue),
                _buildStatBox('Present', present.toString(), Colors.green),
                _buildStatBox('Absent', absent.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            
            // Attendance Percentage
            Center(
              child: Column(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const Text('Attendance Rate'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 20,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance Trend Chart (Last 30 days)
            const Text(
              'Attendance Trend (Last 30 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildAttendanceTrendChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendChart() {
    // Get last 30 days of attendance
    final last30Days = _attendanceData.length > 30 
        ? _attendanceData.sublist(_attendanceData.length - 30)
        : _attendanceData;

    if (last30Days.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('Absent');
                if (value == 1) return const Text('Present');
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < last30Days.length) {
                  final date = last30Days[value.toInt()].date;
                  return Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10));
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
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: last30Days.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.isPresent ? 1.0 : 0.0);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestPerformanceCard() {
    if (_testScoresBySubject.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No test results available'),
          ),
        ),
      );
    }

    // Calculate overall average
    double totalScore = 0;
    int totalTests = 0;
    _testScoresBySubject.forEach((subject, scores) {
      for (var score in scores) {
        totalScore += score.score;
        totalTests++;
      }
    });
    final averageScore = totalTests > 0 ? totalScore / totalTests : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Overall Average
            Center(
              child: Column(
                children: [
                  Text(
                    '${averageScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: averageScore >= 75 ? Colors.green : averageScore >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const Text('Overall Average'),
                  Text('$totalTests tests taken'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Subject Selector
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _availableSubjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Test Scores Chart
            const Text(
              'Score Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: _buildTestScoresChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestScoresChart() {
    List<TestScore> scores = [];
    
    if (_selectedSubject == 'All Subjects') {
      // Combine all scores
      _testScoresBySubject.forEach((subject, subjectScores) {
        scores.addAll(subjectScores);
      });
    } else {
      scores = _testScoresBySubject[_selectedSubject] ?? [];
    }

    if (scores.isEmpty) {
      return const Center(child: Text('No test data for selected subject'));
    }

    // Sort by date
    scores.sort((a, b) => a.date.compareTo(b.date));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
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
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < scores.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      scores[value.toInt()].topic.length > 10
                          ? '${scores[value.toInt()].topic.substring(0, 10)}...'
                          : scores[value.toInt()].topic,
                      style: const TextStyle(fontSize: 9),
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
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: scores.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.score);
            }).toList(),
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
    );
  }

  Widget _buildLessonsLearnedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lessons Learned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.student.lessonsLearned.isEmpty)
              const Center(child: Text('No lessons recorded yet'))
            else
              ...widget.student.lessonsLearned.map((lesson) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(lesson),
                dense: true,
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectWisePerformanceCard() {
    if (_testScoresBySubject.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate average per subject
    Map<String, double> subjectAverages = {};
    _testScoresBySubject.forEach((subject, scores) {
      double total = 0;
      for (var score in scores) {
        total += score.score;
      }
      subjectAverages[subject] = scores.isNotEmpty ? total / scores.length : 0;
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
              'Subject-wise Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
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
                          final subjects = subjectAverages.keys.toList();
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
                  barGroups: subjectAverages.entries.toList().asMap().entries.map((entry) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class AttendanceData {
  final DateTime date;
  final bool isPresent;

  AttendanceData({required this.date, required this.isPresent});
}

class TestScore {
  final String topic;
  final double score;
  final DateTime date;

  TestScore({required this.topic, required this.score, required this.date});
}
