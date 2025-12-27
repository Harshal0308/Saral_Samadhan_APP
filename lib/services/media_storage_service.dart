import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class MediaStorageService {
  static final MediaStorageService _instance = MediaStorageService._internal();
  factory MediaStorageService() => _instance;
  MediaStorageService._internal();

  final _supabase = Supabase.instance.client;
  static const String bucketName = 'media-gallery';

  Future<String?> uploadPhoto(File photoFile, String centerName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(photoFile.path);
      final fileName = '${centerName}_$timestamp$ext';
      final filePath = '$centerName/$fileName';

      print('Uploading media photo: $filePath');

      await _supabase.storage.from(bucketName).upload(filePath, photoFile);

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);

      print('Media photo uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading media photo: $e');
      return null;
    }
  }

  Future<List<String>> uploadPhotos(List<File> photoFiles, String centerName) async {
    final List<String> uploadedUrls = [];
    for (final photo in photoFiles) {
      final url = await uploadPhoto(photo, centerName);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    print('Uploaded ${uploadedUrls.length}/${photoFiles.length} media photos');
    return uploadedUrls;
  }

  Future<bool> deletePhoto(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucketName);
      if (bucketIndex == -1) return false;
      final filePath = segments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(bucketName).remove([filePath]);
      print('Media photo deleted: $filePath');
      return true;
    } catch (e) {
      print('Error deleting media photo: $e');
      return false;
    }
  }
}
