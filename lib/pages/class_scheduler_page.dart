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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Scheduler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, child) {
          final schedules = scheduleProvider.schedules;
          if (schedules.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No class schedules found yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Class/Batch: ${schedule.classBatch}', style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Topic: ${schedule.topic}'),
                      const SizedBox(height: 4),
                      Text('Date: ${schedule.date.toLocal().toString().split(' ')[0]} - ${schedule.time.format(context)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showScheduleDialog(schedule: schedule),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSchedule(schedule.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(),
        label: const Text('Add Schedule'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
