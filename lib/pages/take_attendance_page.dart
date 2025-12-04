import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/services/face_recognition_service.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:dotted_border/dotted_border.dart';

class TakeAttendancePage extends StatefulWidget {
  const TakeAttendancePage({super.key});

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final ImagePicker _picker = ImagePicker();
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  File? _pickedImage;
  bool _isLoading = false;
  String? _errorMessage;

  List<Student> _attendanceList = [];
  int _autoMarkedPresentCount = 0;
  List<String> _recognizedStudentNames = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // NEW: Get only students from selected center
    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    
    _attendanceList = centerStudents
        .map((s) => Student(
            id: s.id,
            name: s.name,
            rollNo: s.rollNo,
            classBatch: s.classBatch,
            centerName: s.centerName, // NEW: Include center
            isPresent: false))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> _getFilteredStudents() {
    if (_searchController.text.isEmpty) {
      return _attendanceList;
    }
    final query = _searchController.text.toLowerCase();
    return _attendanceList.where((student) {
      final nameMatches = student.name.toLowerCase().contains(query);
      final rollNoMatches = student.rollNo.toLowerCase().contains(query);
      return nameMatches || rollNoMatches;
    }).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? imageFile =
        await _picker.pickImage(source: source, imageQuality: 80);

    if (imageFile == null) return;

    setState(() {
      _pickedImage = File(imageFile.path);
      _isLoading = true;
      _errorMessage = null;
      _recognizedStudentNames.clear();
      _autoMarkedPresentCount = 0;
      for (var s in _attendanceList) s.isPresent = false;
    });

    try {
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      final studentsWithEmbeddings = studentProvider.students
          .where((s) => s.embeddings != null && s.embeddings!.isNotEmpty)
          .toList();

      final imageBytes = await _pickedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Could not decode image');

      final detectedFaces = await _faceRecognitionService.detectFaces(image);
      if (detectedFaces.isEmpty) {
        setState(() => _errorMessage = 'No faces detected in the image.');
      } else {
        final List<String> recognizedThisImage = [];
        for (var face in detectedFaces) {
          final embedding =
              _faceRecognitionService.getEmbeddingWithAlignment(image, face);
          if (embedding != null) {
            final bestMatch = _faceRecognitionService.findBestMatch(
                embedding, studentsWithEmbeddings, 0.7);
            if (bestMatch != null && !recognizedThisImage.contains(bestMatch.name)) {
              recognizedThisImage.add(bestMatch.name);
              final studentInList =
                  _attendanceList.firstWhere((s) => s.id == bestMatch.id);
              studentInList.isPresent = true;
            }
          }
        }
        setState(() {
          _recognizedStudentNames = recognizedThisImage;
          _autoMarkedPresentCount = recognizedThisImage.length;
          if (recognizedThisImage.isEmpty) {
            _errorMessage = 'No known students were recognized.';
          }
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during recognition: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      final Map<int, bool> attendanceMap = {
        for (var s in _attendanceList) s.id: s.isPresent
      };
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
      
      // NEW: Include center when saving attendance
      await attendanceProvider.saveAttendance(attendanceMap, selectedCenter);

      await notificationProvider.addNotification(
        title: 'Attendance Saved',
        message:
            'Attendance for ${DateTime.now().toLocal().toString().split(' ').first} saved successfully.',
        type: 'success',
      );

      // Sync to cloud if online
      final offlineProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
      if (offlineProvider.isOnline) {
        final cloudSync = CloudSyncService();
        final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByDateRange(
          DateTime.now(),
          DateTime.now(),
        );
        if (attendanceRecords.isNotEmpty) {
          await cloudSync.uploadAttendanceRecord(attendanceRecords.first);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance saved successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save attendance: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAttendanceToExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export feature coming soon. Please use the Export button in the dashboard.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Widget _buildRecognitionSection() {
    Widget photoWidget;
    if (_pickedImage != null) {
      photoWidget = GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      _recognizedStudentNames.clear();
                      _autoMarkedPresentCount = 0;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_pickedImage!,
              width: double.infinity, height: 180, fit: BoxFit.cover),
        ),
      );
    } else {
      photoWidget = GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [6, 4],
          color: Colors.green.shade400,
          child: Container(
            width: double.infinity,
            height: 140,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt,
                    color: Colors.green.shade700, size: 36),
                const SizedBox(height: 6),
                Text('Add Group Photo',
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Click to capture or upload',
                    style:
                        TextStyle(color: Colors.green.shade700, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: SaralColors.inputBackground,
        borderRadius: BorderRadius.circular(SaralRadius.radius2xl),
        border: Border.all(color: SaralColors.border),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Recognition', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16)),
                child: Text('$_autoMarkedPresentCount Detected',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          photoWidget,
          const SizedBox(height: 10),
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 6),
          Column(
            children: _recognizedStudentNames.map((name) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading:
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                  title: Text(name),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('Auto',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAttendance,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Attendance'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _exportAttendanceToExcel,
                child: const Text('Export Excel'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Recognition section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildRecognitionSection(),
                  ),
                ),
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Students',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(SaralRadius.radius)),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
                // Student list
                _buildStudentListSliver(),
              ],
            ),
          ),
          // Fixed bottom buttons
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStudentListSliver() {
    final filteredStudents = _getFilteredStudents();

    if (_attendanceList.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('No students found. Please add students first.'),
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No matching students found.')),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final student = filteredStudents[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
                color: SaralColors.inputBackground,
                borderRadius: BorderRadius.circular(SaralRadius.radius)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: SaralColors.accent,
                child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(student.name),
              subtitle: Text('Roll No: ${student.rollNo}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => student.isPresent = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: student.isPresent
                              ? Colors.green.shade200
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('P',
                          style: TextStyle(
                              color:
                                  student.isPresent ? Colors.white : Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => student.isPresent = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: !student.isPresent
                              ? Colors.red.shade200
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('A',
                          style: TextStyle(
                              color: !student.isPresent
                                  ? Colors.white
                                  : Colors.grey)),
                    ),
                  ),
                ],
              ),
              onTap: () => setState(() => student.isPresent = !student.isPresent),
            ),
          );
        },
        childCount: filteredStudents.length,
      ),
    );
  }
}