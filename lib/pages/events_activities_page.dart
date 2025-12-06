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

  String _selectedFilter = 'All Events';

  @override
  Widget build(BuildContext context) {
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
          'Events & Activities',
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
              onPressed: _showAddEventDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Events'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Upcoming'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Events List
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                final events = eventProvider.events;
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No events scheduled yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final attendanceCount = _parseAttendanceCount(event.attendanceSummary);
                    final photoCount = event.photoPaths.length;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  event.date.toLocal().toString().split(' ')[0],
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  event.time.format(context),
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  event.description,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people, size: 18, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            attendanceCount,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                          Text(
                                            'Attended',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE7F3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.photo_library, size: 18, color: Color(0xFFDB2777)),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$photoCount',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDB2777),
                                            ),
                                          ),
                                          Text(
                                            'Photos',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // View photos logic
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6B7280),
                                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('View Photos'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // View report logic
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEDE9FE),
                                      foregroundColor: const Color(0xFF8B5CF6),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('View Report'),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _parseAttendanceCount(String summary) {
    // Extract number from attendance summary (e.g., "100 students" -> "100")
    final match = RegExp(r'\d+').firstMatch(summary);
    return match?.group(0) ?? '0';
  }
}
