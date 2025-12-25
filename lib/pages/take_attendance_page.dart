import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/export_provider.dart';
import 'package:samadhan_app/services/face_recognition_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:samadhan_app/widgets/loading_button.dart';
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
  List<File> _pickedImages = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isExporting = false;
  String? _errorMessage;

  List<Student> _attendanceList = [];
  int _autoMarkedPresentCount = 0;
  List<String> _recognizedStudentNames = [];
  final TextEditingController _searchController = TextEditingController();
  int _totalPhotosProcessed = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStudentsWithExistingAttendance();
  }

  Future<void> _loadStudentsWithExistingAttendance() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
    
    // Get only students from selected center
    final centerStudents = studentProvider.getStudentsByCenter(selectedCenter);
    
    // Check if attendance already exists for today
    final today = DateTime.now();
    final todayAttendance = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
      selectedCenter,
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
    
    // Create attendance list with existing attendance data
    setState(() {
      _attendanceList = centerStudents.map((s) {
        // Check if this student already has attendance marked today
        // ✅ FIX: Try both new format (composite key) and old format (just roll number)
        bool isAlreadyPresent = false;
        if (todayAttendance.isNotEmpty) {
          final compositeKey = '${s.rollNo}_${s.classBatch}'; // New format
          final rollNoKey = s.rollNo; // Old format
          
          // Try new format first, fallback to old format
          isAlreadyPresent = todayAttendance.first.attendance[compositeKey] ?? 
                            todayAttendance.first.attendance[rollNoKey] ?? 
                            false;
          
          if (isAlreadyPresent) {
            print('✓ Student ${s.name} (${s.rollNo}) found in existing attendance');
          }
        }
        
        return Student(
          id: s.id,
          name: s.name,
          rollNo: s.rollNo,
          classBatch: s.classBatch,
          centerName: s.centerName,
          isPresent: isAlreadyPresent, // ✅ Load existing attendance
        );
      }).toList();
      
      // Count how many are already present
      final alreadyPresentCount = _attendanceList.where((s) => s.isPresent).length;
      if (alreadyPresentCount > 0) {
        print('✅ Loaded existing attendance: $alreadyPresentCount students already marked present');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildExistingAttendanceInfo() {
    final alreadyPresentCount = _attendanceList.where((s) => s.isPresent).length;
    
    if (alreadyPresentCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$alreadyPresentCount student(s) already marked present today. Face recognition will only mark additional students.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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

    await _processImages([File(imageFile.path)]);
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile> imageFiles = await _picker.pickMultiImage(imageQuality: 80);

    if (imageFiles.isEmpty) return;

    await _processImages(imageFiles.map((xf) => File(xf.path)).toList());
  }

  Future<void> _processImages(List<File> imageFiles) async {
    setState(() {
      _pickedImages.addAll(imageFiles);
      _isLoading = true;
      _errorMessage = null;
      _recognizedStudentNames.clear();
      _autoMarkedPresentCount = 0;
      _totalPhotosProcessed = 0;
    });

    try {
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
      
      final attendanceListIds = _attendanceList.map((s) => s.id).toSet();
      final studentsWithEmbeddings = studentProvider.students
          .where((s) => 
            s.centerName == selectedCenter &&
            attendanceListIds.contains(s.id) &&
            s.embeddings != null && 
            s.embeddings!.isNotEmpty
          )
          .toList();
      
      print('🔍 Face recognition will compare against ${studentsWithEmbeddings.length} students from $selectedCenter');

      final List<String> allRecognizedNames = [];
      int totalNewlyMarked = 0;
      int photosWithFaces = 0;
      int photosWithoutFaces = 0;

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        print('📷 Processing image ${i + 1}/${imageFiles.length}');
        
        try {
          final imageBytes = await imageFile.readAsBytes();
          final image = img.decodeImage(imageBytes);
          if (image == null) {
            print('⚠️ Could not decode image ${i + 1}');
            continue;
          }

          final detectedFaces = await _faceRecognitionService.detectFaces(image);
          if (detectedFaces.isEmpty) {
            photosWithoutFaces++;
            print('⚠️ No faces detected in image ${i + 1}');
            continue;
          }
          
          photosWithFaces++;
          print('✅ Found ${detectedFaces.length} face(s) in image ${i + 1}');

          for (var face in detectedFaces) {
            final embedding =
                _faceRecognitionService.getEmbeddingWithAlignment(image, face);
            if (embedding != null) {
              final bestMatch = _faceRecognitionService.findBestMatch(
                  embedding, studentsWithEmbeddings, 0.7);
              if (bestMatch != null && !allRecognizedNames.contains(bestMatch.name)) {
                allRecognizedNames.add(bestMatch.name);
                
                try {
                  final studentInList =
                      _attendanceList.firstWhere((s) => s.id == bestMatch.id);
                  
                  if (!studentInList.isPresent) {
                    studentInList.isPresent = true;
                    totalNewlyMarked++;
                    print('✅ Face recognized: ${studentInList.name} marked present (NEW)');
                  } else {
                    print('ℹ️ ${studentInList.name} already marked present');
                  }
                } catch (e) {
                  print('⚠️ Recognized student ${bestMatch.name} not found in attendance list');
                }
              }
            }
          }
        } catch (e) {
          print('❌ Error processing image ${i + 1}: $e');
        }
        
        setState(() {
          _totalPhotosProcessed = i + 1;
        });
      }

      setState(() {
        _recognizedStudentNames = allRecognizedNames;
        _autoMarkedPresentCount = totalNewlyMarked;
        
        if (photosWithFaces == 0) {
          _errorMessage = 'No faces detected in any of the ${imageFiles.length} photo(s).';
        } else if (allRecognizedNames.isEmpty) {
          _errorMessage = 'No known students were recognized from ${imageFiles.length} photo(s).';
        } else if (totalNewlyMarked == 0) {
          _errorMessage = 'All recognized students were already marked present.';
        } else {
          _errorMessage = null;
        }
      });
      
      print('📊 Summary: Processed ${imageFiles.length} photos, $photosWithFaces had faces, recognized ${allRecognizedNames.length} students, $totalNewlyMarked newly marked');
      
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during recognition: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      // ✅ FIXED: Use roll number + class as composite key (unique identifier)
      final Map<String, bool> attendanceMap = {
        for (var s in _attendanceList) '${s.rollNo}_${s.classBatch}': s.isPresent
      };
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
      
      print('\n═══════════════════════════════════════════════════════');
      print('💾 SAVING ATTENDANCE FROM UI');
      print('═══════════════════════════════════════════════════════');
      print('   Total students: ${attendanceMap.length}');
      print('   Center: "$selectedCenter"');
      print('   Date: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      
      // Count present/absent
      final presentCount = attendanceMap.values.where((v) => v == true).length;
      final absentCount = attendanceMap.values.where((v) => v == false).length;
      print('   ✅ Present: $presentCount, ❌ Absent: $absentCount');
      print('   Sample keys: ${attendanceMap.keys.take(3).join(", ")}${attendanceMap.length > 3 ? "..." : ""}');
      
      // Save attendance with sync (will handle online/offline automatically)
      await attendanceProvider.saveAttendanceQueued(attendanceMap, selectedCenter);
      
      print('✅ Attendance save completed');
      print('═══════════════════════════════════════════════════════\n');

      await notificationProvider.addNotification(
        title: 'Attendance Saved',
        message:
            'Attendance for ${DateTime.now().toLocal().toString().split(' ').first} saved successfully.',
        type: 'success',
      );

      if (mounted) {
        // Check if it was synced to cloud or queued
        final cloudSyncV2 = CloudSyncServiceV2();
        final isOnline = await cloudSyncV2.isOnline();
        
        final message = isOnline 
            ? 'Attendance saved and synced to cloud ✓'
            : 'Attendance saved locally. Will sync when online.';
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isOnline ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ));
      }
    } catch (e) {
      print('❌ Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save attendance: $e'),
              backgroundColor: Colors.red,
            ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportAttendanceToExcel() async {
    setState(() => _isExporting = true);
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
      
      // Get today's date
      final today = DateTime.now();
      
      // Download latest attendance from cloud to ensure we have all data
      try {
        final cloudSyncV2 = CloudSyncServiceV2();
        final cloudAttendance = await cloudSyncV2.downloadAttendanceForCenter(selectedCenter);
        for (var cloudRecord in cloudAttendance) {
          await attendanceProvider.saveAttendance(
            cloudRecord.attendance,
            selectedCenter,
            date: cloudRecord.date,
          );
        }
        print('✅ Downloaded and merged latest attendance data for center: $selectedCenter');
      } catch (e) {
        print('⚠️ Failed to download latest attendance before export: $e');
        // Continue with local data
      }
      
      // ✅ FIX: Fetch attendance records for today only
      final attendanceRecords = await attendanceProvider.fetchAttendanceRecordsByCenterAndDateRange(
        selectedCenter,
        DateTime(today.year, today.month, today.day),
        DateTime(today.year, today.month, today.day, 23, 59, 59),
      );
      
      if (attendanceRecords.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance records found for today. Please save attendance first.')),
          );
        }
        return;
      }
      
      // ✅ FIX: Use export provider with center filter
      final exportProvider = ExportProvider(studentProvider);
      final path = await exportProvider.exportAttendanceToExcel(
        attendanceRecords,
        startDate: today,
        endDate: today,
        centerName: selectedCenter,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Attendance exported successfully!'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFile.open(path);
                if (result.type != ResultType.done) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open file: ${result.message}')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildRecognitionSection() {
    Widget photoWidget;
    if (_pickedImages.isNotEmpty) {
      photoWidget = Column(
        children: [
          // Show thumbnails of uploaded photos
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length + 1, // +1 for add more button
              itemBuilder: (context, index) {
                if (index == _pickedImages.length) {
                  // Add more photos button
                  return GestureDetector(
                    onTap: () => _showPhotoPickerBottomSheet(),
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Icon(Icons.add_photo_alternate, color: Colors.green.shade700),
                    ),
                  );
                }
                return Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedImages[index], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _pickedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Clear all button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _pickedImages.clear();
                _recognizedStudentNames.clear();
                _autoMarkedPresentCount = 0;
              });
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: Text('Clear all ${_pickedImages.length} photo(s)'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      );
    } else {
      photoWidget = GestureDetector(
        onTap: () => _showPhotoPickerBottomSheet(),
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
                Text('Add Group Photo(s)',
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tap to capture or select multiple photos',
                    style:
                        TextStyle(color: Colors.green.shade700, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate total present count
    final totalPresentCount = _attendanceList.where((s) => s.isPresent).length;
    
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
              // Show newly detected count
              if (_autoMarkedPresentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Text('+$_autoMarkedPresentCount New',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              // Show total present count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16)),
                child: Text('$totalPresentCount Present',
                    style: TextStyle(
                        color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Info message about multi-photo support
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select multiple photos at once from gallery. Each student will only be marked present once.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Loading indicator with progress
          if (_isLoading && _pickedImages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing photo $_totalPhotosProcessed of ${_pickedImages.length}...',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
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

  void _showPhotoPickerBottomSheet() {
    showModalBottomSheet(
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
              subtitle: const Text('Capture one photo with camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select Multiple Photos'),
              subtitle: const Text('Choose multiple photos from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Select Single Photo'),
              subtitle: const Text('Choose one photo from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sync status indicator
            FutureBuilder<bool>(
              future: CloudSyncServiceV2().isOnline(),
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? false;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOnline ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline 
                            ? 'Online - Will sync immediately' 
                            : 'Offline - Will sync when online',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green.shade900 : Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    onPressed: _saveAttendance,
                    isLoading: _isSaving,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Save Attendance'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LoadingButton(
                    onPressed: _exportAttendanceToExcel,
                    isLoading: _isExporting,
                    isElevated: false,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Export Excel'),
                  ),
                ),
              ],
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
                // Existing attendance info banner
                SliverToBoxAdapter(
                  child: _buildExistingAttendanceInfo(),
                ),
                // Recognition section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildRecognitionSection(),
                  ),
                ),
                // Search bar with Reset button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Reset button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Reset Attendance'),
                                  content: const Text(
                                    'This will mark all students as ABSENT. Are you sure?'
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true) {
                              setState(() {
                                for (var student in _attendanceList) {
                                  student.isPresent = false;
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All students marked as absent'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Search bar
                        Expanded(
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
                      ],
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