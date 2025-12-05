import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';

class ViewAttendancePage extends StatefulWidget {
  final DateTime initialDate;

  const ViewAttendancePage({super.key, required this.initialDate});

  @override
  State<ViewAttendancePage> createState() => _ViewAttendancePageState();
}

class _ViewAttendancePageState extends State<ViewAttendancePage> {
  late DateTime _selectedDate;
  Future<List<AttendanceRecord>>? _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always fetch fresh data when page is displayed
    // This ensures data is updated after saving attendance
    _fetchAttendanceForDate(_selectedDate);
  }

  // Refresh data manually
  void _refreshAttendance() {
    print('🔄 Manually refreshing attendance data...');
    _fetchAttendanceForDate(_selectedDate);
  }

  void _fetchAttendanceForDate(DateTime date) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    setState(() {
      // Filter by center and date range
      _attendanceFuture = attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
        selectedCenter,
        DateTime(date.year, date.month, date.day), // Start of the day
        DateTime(date.year, date.month, date.day, 23, 59, 59), // End of the day
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      _fetchAttendanceForDate(picked);
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    // Get only students from selected center
    final allStudents = studentProvider.getStudentsByCenter(selectedCenter);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for ${_selectedDate.toLocal().toString().split(' ')[0]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAttendance,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAttendance();
          // Wait a bit for the refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: FutureBuilder<List<AttendanceRecord>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance records found for this date.'));
          }

          final attendanceRecord = snapshot.data!.first;
          
          print('📊 Viewing attendance for ${attendanceRecord.date.toLocal().toString().split(' ')[0]}');
          print('   Center: ${attendanceRecord.centerName}');
          print('   Students in attendance: ${attendanceRecord.attendance.keys.join(", ")}');
          print('   DETAILED VIEW DATA:');
          attendanceRecord.attendance.forEach((rollNo, isPresent) {
            print('      $rollNo: ${isPresent ? "PRESENT ✅" : "ABSENT ❌"}');
          });
          
          // Count present/absent
          final presentCount = attendanceRecord.attendance.values.where((v) => v == true).length;
          final absentCount = attendanceRecord.attendance.values.where((v) => v == false).length;
          print('   Summary: $presentCount present, $absentCount absent');
          print('   Total students in list: ${allStudents.length}');
          
          return ListView.builder(
            itemCount: allStudents.length,
            itemBuilder: (context, index) {
              final student = allStudents[index];
              // Use composite key: rollNo_class to handle duplicate roll numbers across classes
              final compositeKey = '${student.rollNo}_${student.classBatch}';
              final isPresent = attendanceRecord.attendance[compositeKey] ?? false;
              return Card(
                color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(student.name),
                  subtitle: Text('Roll No: ${student.rollNo}'),
                  trailing: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}
