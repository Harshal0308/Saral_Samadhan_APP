import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Service to upload and manage event photos in Supabase Storage
class EventStorageService {
  static final EventStorageService _instance = EventStorageService._internal();
  factory EventStorageService() => _instance;
  EventStorageService._internal();

  final _supabase = Supabase.instance.client;
  static const String bucketName = 'event-photos';

  /// Upload a single photo and return its public URL
  Future<String?> uploadPhoto(File photoFile, String eventId) async {
    try {
      final fileName = '${eventId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(photoFile.path)}';
      final filePath = '$eventId/$fileName';

      print('📤 Uploading photo: $filePath');

      await _supabase.storage
          .from(bucketName)
          .upload(filePath, photoFile);

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('✅ Photo uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      return null;
    }
  }

  /// Upload multiple photos and return their public URLs
  Future<List<String>> uploadPhotos(List<File> photoFiles, String eventId) async {
    final List<String> uploadedUrls = [];

    for (final photo in photoFiles) {
      final url = await uploadPhoto(photo, eventId);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    print('✅ Uploaded ${uploadedUrls.length}/${photoFiles.length} photos');
    return uploadedUrls;
  }

  /// Delete a photo from storage
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final filePath = uri.pathSegments.skip(4).join('/'); // Skip /storage/v1/object/public/bucket-name/

      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);

      print('✅ Photo deleted: $filePath');
      return true;
    } catch (e) {
      print('❌ Error deleting photo: $e');
      return false;
    }
  }

  /// Delete all photos for an event
  Future<void> deleteEventPhotos(String eventId) async {
    try {
      final files = await _supabase.storage
          .from(bucketName)
          .list(path: eventId);

      final filePaths = files.map((file) => '$eventId/${file.name}').toList();

      if (filePaths.isNotEmpty) {
        await _supabase.storage
            .from(bucketName)
            .remove(filePaths);

        print('✅ Deleted ${filePaths.length} photos for event $eventId');
      }
    } catch (e) {
      print('❌ Error deleting event photos: $e');
    }
  }
}
