import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/services/face_recognition_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/pages/image_cropper_page.dart';
import 'package:image/image.dart' as img;
import 'package:samadhan_app/theme/saral_theme.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  String? _selectedClass;
  final List<String> _classes = List.generate(12, (index) => (index + 1).toString());

  final List<File?> _photoFiles = List.filled(5, null);
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(int index) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      final img.Image? croppedImage = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageCropperPage(
            imageFile: File(pickedFile.path),
          ),
        ),
      );

      if (croppedImage != null) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final croppedFile = await File(path).writeAsBytes(img.encodeJpg(croppedImage));

        setState(() {
          _photoFiles[index] = croppedFile;
        });
      }
    }
  }

  Future<void> _addStudentAndTrain() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final faceService = FaceRecognitionService();

      List<List<double>> collectedEmbeddings = [];
      String photoProcessingErrors = '';

      // PROCESS IMAGES (OPTIONAL)
      for (int i = 0; i < _photoFiles.length; i++) {
        final croppedPhotoFile = _photoFiles[i];
        if (croppedPhotoFile != null) {
          try {
            final imageBytes = await croppedPhotoFile.readAsBytes();
            final img.Image? imageData = img.decodeImage(imageBytes);

            if (imageData == null) {
              photoProcessingErrors += 'Photo ${i + 1}: Failed to decode.\n';
              continue;
            }

            final detectedFaces = await faceService.detectFaces(imageData);
            if (detectedFaces.isNotEmpty) {
              final face = detectedFaces[0];
              final currentEmbedding =
                  faceService.getEmbeddingWithAlignment(imageData, face);

              if (currentEmbedding != null) {
                collectedEmbeddings.add(currentEmbedding);
              } else {
                photoProcessingErrors += 'Photo ${i + 1}: Failed to create embedding.\n';
              }
            } else {
              photoProcessingErrors += 'Photo ${i + 1}: No face detected.\n';
            }
          } catch (e) {
            photoProcessingErrors += 'Photo ${i + 1}: Error $e\n';
          }
        }
      }

      // IF NO VALID EMBEDDINGS → ASSIGN PLACEHOLDER VECTOR
      if (collectedEmbeddings.isEmpty) {
        print("⚠️ No embeddings generated — assigning placeholder embedding.");
        collectedEmbeddings = [List.filled(192, 0.0)];
      }

      if (photoProcessingErrors.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Some photos had issues. Using available embeddings.\n$photoProcessingErrors'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';

        final newStudent = await studentProvider.addStudent(
          name: _nameController.text,
          rollNo: _rollNoController.text,
          classBatch: _selectedClass!,
          centerName: selectedCenter,
          embeddings: collectedEmbeddings,
        );

        if (newStudent == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('This roll number is already assigned in this class.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        notificationProvider.addNotification(
          title: 'Student Added',
          message: 'Student ${newStudent.name} added successfully.',
          type: 'success',
        );

        // CLOUD SYNC
        try {
          final cloudSyncV2 = CloudSyncServiceV2();
          await cloudSyncV2.queueStudentUpload(newStudent);

          final result = await cloudSyncV2.processSyncQueue();

          if (result['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student synced to cloud'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved offline — will sync later'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          print("Cloud sync error: $e");
        }

        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
        backgroundColor: SaralColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add Student',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),

                      /// NAME FIELD
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Student Name'),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                        ],
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Please enter student name';
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
                            return 'Only letters and spaces allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// CLASS FIELD
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Class'),
                        value: _selectedClass,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedClass = newValue;
                          });
                        },
                        items: _classes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select a class' : null,
                      ),
                      const SizedBox(height: 16),

                      /// ROLL NUMBER FIELD
                      TextFormField(
                        controller: _rollNoController,
                        decoration:
                            const InputDecoration(labelText: 'Roll Number'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter roll number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      /// PHOTO SECTION
                      const Text(
                        'Student Photos (optional)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload up to 5 photos for better recognition. Without photos, student must be marked manually.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(5, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 12.0),
                              child: GestureDetector(
                                onTap: () => _pickImage(index),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _photoFiles[index] == null
                                        ? Colors.transparent
                                        : SaralColors.inputBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade400),
                                  ),
                                  child: _photoFiles[index] == null
                                      ? Center(
                                          child: Icon(
                                            index == 0
                                                ? Icons.upload
                                                : Icons.add,
                                            size: 28,
                                            color: Colors.blueAccent,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            _photoFiles[index]!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _addStudentAndTrain,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    SaralRadius.radius2xl)),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            child: Text('ADD STUDENT',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
