import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';

class EventsActivitiesPage extends StatefulWidget {
  const EventsActivitiesPage({super.key});

  @override
  State<EventsActivitiesPage> createState() => _EventsActivitiesPageState();
}

class _EventsActivitiesPageState extends State<EventsActivitiesPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    Provider.of<EventProvider>(context, listen: false).loadEvents();
  }

  Future<void> _pickImages(StateSetter setStateInDialog) async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 50);
    if (images.isNotEmpty) {
      setStateInDialog(() {
        _pickedImages = images.map((xfile) => File(xfile.path)).toList();
      });
    }
  }

  Future<void> _showAddEventDialog() async {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _description;
    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;
    String? _attendanceSummary;

    // Reset picked images for a new dialog instance
    _pickedImages = []; 

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog UI
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Add New Event'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Event Title'),
                        onSaved: (value) => _title = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a title';
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Description'),
                        onSaved: (value) => _description = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a description';
                          return null;
                        },
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
                        decoration: const InputDecoration(labelText: 'Attendance Summary (e.g., 100 students, 5 volunteers)'),
                        onSaved: (value) => _attendanceSummary = value,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _pickImages(setStateInDialog),
                        icon: const Icon(Icons.image),
                        label: Text('Select Photos (${_pickedImages.length})'),
                      ),
                      if (_pickedImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Image.file(_pickedImages[index], fit: BoxFit.cover);
                          },
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
                  child: const Text('Add Event'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
                      _formKey.currentState!.save();
                      final eventProvider = Provider.of<EventProvider>(context, listen: false);
                      final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
                      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                      await eventProvider.addEvent(
                        title: _title!,
                        description: _description!,
                        date: _selectedDate!,
                        time: _selectedTime!,
                        attendanceSummary: _attendanceSummary ?? 'N/A',
                        photoPaths: _pickedImages.map((f) => f.path).toList(), // Pass photo paths
                      );
                      offlineSyncProvider.addPendingChange();
                      notificationProvider.addNotification(
                        title: 'New Event Added',
                        message: 'Event "$_title" on ${_selectedDate!.toLocal().toString().split(' ')[0]} has been added.',
                        type: 'info',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event added successfully!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                final events = eventProvider.events;
                if (events.isEmpty) {
                  return const Center(child: Text('No events scheduled yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(event.description),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text('${event.date.toLocal().toString().split(' ')[0]} - ${event.time.format(context)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people, size: 16),
                                const SizedBox(width: 4),
                                Text('Attendance: ${event.attendanceSummary}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Display actual photos
                            if (event.photoPaths.isNotEmpty)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: event.photoPaths.length,
                                itemBuilder: (context, index) {
                                  return Image.file(File(event.photoPaths[index]), fit: BoxFit.cover);
                                },
                              ),
                            if (event.photoPaths.isEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.photo, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${event.photoPaths.length} Photos'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Event', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
