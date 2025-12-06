import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/schedule_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';

class ClassSchedulerPage extends StatefulWidget {
  const ClassSchedulerPage({super.key});

  @override
  State<ClassSchedulerPage> createState() => _ClassSchedulerPageState();
}

class _ClassSchedulerPageState extends State<ClassSchedulerPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<ScheduleProvider>(context, listen: false).loadSchedules();
  }

  Future<void> _showScheduleDialog({ScheduleEntry? schedule}) async {
    final _formKey = GlobalKey<FormState>();
    bool isEditing = schedule != null;
    
    String? _selectedClassBatch = schedule?.classBatch;
    DateTime? _selectedDate = schedule?.date;
    TimeOfDay? _selectedTime = schedule?.time;
    String? _topic = schedule?.topic;

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final List<String> availableClassBatches = studentProvider.students.map((s) => s.classBatch).toSet().toList();
    if (!availableClassBatches.contains('General')) {
      availableClassBatches.add('General');
    }
    availableClassBatches.sort();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Schedule Entry' : 'Add New Schedule Entry'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Class / Batch'),
                        value: _selectedClassBatch,
                        onChanged: (String? newValue) {
                          setStateInDialog(() {
                            _selectedClassBatch = newValue;
                          });
                        },
                        items: availableClassBatches.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        validator: (value) => value == null || value.isEmpty ? 'Please select a class/batch' : null,
                      ),
                      ListTile(
                        title: Text(_selectedDate == null ? 'Select Date' : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateInDialog(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text(_selectedTime == null ? 'Select Time' : 'Time: ${_selectedTime!.format(dialogContext)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setStateInDialog(() {
                              _selectedTime = picked;
                            });
                          }
                        },
                      ),
                      TextFormField(
                        initialValue: _topic,
                        decoration: const InputDecoration(labelText: 'Topic'),
                        onSaved: (value) => _topic = value,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a topic' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? 'Update Schedule' : 'Add Schedule'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
                      _formKey.currentState!.save();
                      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
                      final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
                      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                      if (isEditing) {
                        final updatedSchedule = schedule!.copyWith(
                          classBatch: _selectedClassBatch,
                          date: _selectedDate,
                          time: _selectedTime,
                          topic: _topic,
                        );
                        await scheduleProvider.updateSchedule(updatedSchedule);
                        notificationProvider.addNotification(
                          title: 'Schedule Updated',
                          message: 'Class for $_selectedClassBatch on ${_selectedDate!.toLocal().toString().split(' ')[0]} was updated.',
                          type: 'info',
                        );
                      } else {
                        await scheduleProvider.addSchedule(
                          classBatch: _selectedClassBatch!,
                          date: _selectedDate!,
                          time: _selectedTime!,
                          topic: _topic!,
                        );
                        notificationProvider.addNotification(
                          title: 'New Class Schedule Added',
                          message: 'Class $_selectedClassBatch scheduled for ${_selectedDate!.toLocal().toString().split(' ')[0]} on topic "$_topic".',
                          type: 'info',
                        );
                      }
                      
                      offlineSyncProvider.addPendingChange();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Schedule ${isEditing ? 'updated' : 'added'} successfully!')),
                        );
                        Navigator.of(dialogContext).pop();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(int id) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: const Text('Are you sure you want to delete this schedule entry?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      await scheduleProvider.deleteSchedule(id);
      offlineSyncProvider.addPendingChange();
      notificationProvider.addNotification(
        title: 'Schedule Deleted',
        message: 'A schedule entry has been deleted.',
        type: 'warning',
      );
    }
  }

  DateTime _selectedDate = DateTime.now();

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(_selectedDate);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Class Scheduler',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showScheduleDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                      },
                    ),
                    Column(
                      children: [
                        Text(
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Week ${_getWeekNumber(_selectedDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Week Days
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekDays.map((date) {
                      final isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getDayName(date.weekday),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Today's Schedule
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (context, scheduleProvider, child) {
                final todaySchedules = scheduleProvider.schedules.where((s) {
                  return s.date.year == _selectedDate.year &&
                      s.date.month == _selectedDate.month &&
                      s.date.day == _selectedDate.day;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Schedule",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '${todaySchedules.length} classes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: todaySchedules.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes scheduled for this day.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: todaySchedules.length,
                              itemBuilder: (context, index) {
                                final schedule = todaySchedules[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.access_time,
                                                color: Color(0xFF8B5CF6),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${schedule.topic} - Class ${schedule.classBatch}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${schedule.time.format(context)} • 2 hours',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Volunteer Name',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showScheduleDialog(schedule: schedule),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF6B7280),
                                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Edit'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Mark complete logic
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  elevation: 0,
                                                ),
                                                child: const Text('Mark Complete'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}
