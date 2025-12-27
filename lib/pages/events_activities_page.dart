import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/monthly_activity_provider.dart';
import 'package:samadhan_app/services/photo_sync_service.dart';
import 'package:samadhan_app/pages/event_photo_viewer_page.dart';
import 'package:samadhan_app/pages/event_report_page.dart';

class EventsActivitiesPage extends StatefulWidget {
  const EventsActivitiesPage({super.key});

  @override
  State<EventsActivitiesPage> createState() => _EventsActivitiesPageState();
}

class _EventsActivitiesPageState extends State<EventsActivitiesPage> {
  final ImagePicker _picker = ImagePicker();
  final PhotoSyncService _photoSyncService = PhotoSyncService();
  List<File> _pickedImages = [];
  Map<int, bool> _syncingPhotos = {};
  bool _isSyncingEvents = false;

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
    String? _selectedActivity;
    String? _customActivity;
    DateTime? _selectedDate;
    String? _purpose;
    final _customActivityController = TextEditingController();
    final _purposeController = TextEditingController();

    // Reset picked images for a new dialog instance
    _pickedImages = [];

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<MonthlyActivityProvider>(context, listen: false);
    final centerName = userProvider.userSettings.selectedCenter ?? '';
    
    // Load activities for dropdown
    await activityProvider.loadActivities();
    final activityNames = activityProvider.getActivityNames(centerName);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Add New Activity'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity Dropdown with option to add new
                      const Text('Activity Title', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedActivity,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Select activity'),
                        items: [
                          ...activityNames.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          )),
                          const DropdownMenuItem(
                            value: '__custom__',
                            child: Text('+ Add new activity', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                        onChanged: (value) {
                          setStateInDialog(() {
                            _selectedActivity = value;
                            if (value != '__custom__') {
                              _customActivity = null;
                              _customActivityController.clear();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an activity';
                          }
                          if (value == '__custom__' && (_customActivity == null || _customActivity!.isEmpty)) {
                            return 'Please enter custom activity name';
                          }
                          return null;
                        },
                      ),
                      
                      // Custom activity text field (shown when "Add new" is selected)
                      if (_selectedActivity == '__custom__') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customActivityController,
                          decoration: const InputDecoration(
                            labelText: 'New Activity Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _customActivity = value;
                          },
                          validator: (value) {
                            if (_selectedActivity == '__custom__' && (value == null || value.isEmpty)) {
                              return 'Please enter activity name';
                            }
                            return null;
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Date picker
                      const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null 
                                    ? 'Select date' 
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey[600] : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Purpose field
                      const Text('Purpose', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _purposeController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter purpose of the activity',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _purpose = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter purpose';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Photo picker
                      ElevatedButton.icon(
                        onPressed: () => _pickImages(setStateInDialog),
                        icon: const Icon(Icons.image),
                        label: Text('Select Photos (${_pickedImages.length})'),
                      ),
                      if (_pickedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GridView.builder(
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
                  child: const Text('Add Activity'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                      _formKey.currentState!.save();
                      
                      final activityName = _selectedActivity == '__custom__' 
                          ? _customActivity! 
                          : _selectedActivity!;
                      
                      final eventProvider = Provider.of<EventProvider>(context, listen: false);
                      final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
                      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                      final activityProvider = Provider.of<MonthlyActivityProvider>(context, listen: false);

                      // Add to monthly activities
                      await activityProvider.addActivity(
                        name: activityName,
                        date: DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        purpose: _purpose,
                        centerName: centerName,
                      );

                      // Add as event
                      await eventProvider.addEvent(
                        title: activityName,
                        description: _purpose ?? '',
                        date: _selectedDate!,
                        time: TimeOfDay.now(),
                        attendanceSummary: 'N/A',
                        photoPaths: _pickedImages.map((f) => f.path).toList(),
                        centerName: centerName,
                      );
                      
                      offlineSyncProvider.addPendingChange();
                      notificationProvider.addNotification(
                        title: 'New Activity Added',
                        message: 'Activity "$activityName" on ${DateFormat('dd/MM/yyyy').format(_selectedDate!)} has been added.',
                        type: 'info',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activity added successfully!')),
                        );
                        Navigator.of(dialogContext).pop();
                      }
                    } else if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a date')),
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

  Future<void> _syncEventPhotos(Event event) async {
    if (_syncingPhotos[event.id] == true) return;
    
    setState(() {
      _syncingPhotos[event.id] = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final centerName = userProvider.userSettings.selectedCenter ?? event.centerName;
      
      final result = await _photoSyncService.syncEventPhotos(
        event.id,
        centerName,
        event.photoPaths,
      );

      if (result['success'] == true && mounted) {
        final photoUrls = result['photoUrls'] as List<String>;
        if (photoUrls.isNotEmpty) {
          // Update event with synced photo URLs
          final eventProvider = Provider.of<EventProvider>(context, listen: false);
          await eventProvider.updateEvent(event.copyWith(photoPaths: photoUrls));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced ${result['uploaded']} photos')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Sync failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncingPhotos[event.id] = false;
        });
      }
    }
  }

  bool _hasUnsyncedPhotos(Event event) {
    return event.photoPaths.any((p) => !p.startsWith('http'));
  }

  Future<void> _syncAllEvents() async {
    if (_isSyncingEvents) return;
    
    setState(() {
      _isSyncingEvents = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final centerName = userProvider.userSettings.selectedCenter ?? '';
      
      if (centerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a center first')),
        );
        return;
      }

      // Sync events from cloud for this center
      await eventProvider.syncEventsFromCloud(centerName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Events synced successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingEvents = false;
        });
      }
    }
  }

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
          // Sync Events Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _isSyncingEvents
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B5CF6),
                      ),
                    )
                  : const Icon(Icons.sync, color: Color(0xFF8B5CF6)),
              onPressed: _isSyncingEvents ? null : _syncAllEvents,
              tooltip: 'Sync Events',
            ),
          ),
          // Add Event Button
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
            child: Consumer2<EventProvider, UserProvider>(
              builder: (context, eventProvider, userProvider, child) {
                final centerName = userProvider.userSettings.selectedCenter ?? '';
                final events = eventProvider.getEventsForCenter(centerName);
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
                                      if (event.photoPaths.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No photos available')),
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventPhotoViewerPage(
                                            photoUrls: event.photoPaths,
                                            initialIndex: 0,
                                            eventTitle: event.title,
                                          ),
                                        ),
                                      );
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
                                const SizedBox(width: 8),
                                // Sync Photos Button
                                if (_hasUnsyncedPhotos(event))
                                  SizedBox(
                                    width: 48,
                                    child: OutlinedButton(
                                      onPressed: _syncingPhotos[event.id] == true
                                          ? null
                                          : () => _syncEventPhotos(event),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF8B5CF6),
                                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: _syncingPhotos[event.id] == true
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.cloud_upload, size: 18),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventReportPage(event: event),
                                        ),
                                      );
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
