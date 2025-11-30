import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';

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
    _fetchAttendanceForDate(_selectedDate);
  }

  void _fetchAttendanceForDate(DateTime date) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    setState(() {
      _attendanceFuture = attendanceProvider.fetchAttendanceRecordsByDateRange(
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
    final allStudents = studentProvider.students;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for ${_selectedDate.toLocal().toString().split(' ')[0]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
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
          
          return ListView.builder(
            itemCount: allStudents.length,
            itemBuilder: (context, index) {
              final student = allStudents[index];
              final isPresent = attendanceRecord.attendance[student.id] ?? false;
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
    );
  }
}
