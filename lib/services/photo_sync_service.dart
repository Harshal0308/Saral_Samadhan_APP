import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/media_item.dart';
import 'package:samadhan_app/services/media_storage_service.dart';
import 'package:samadhan_app/services/event_storage_service.dart';

class PhotoSyncService {
  static final PhotoSyncService _instance = PhotoSyncService._internal();
  factory PhotoSyncService() => _instance;
  PhotoSyncService._internal();

  final _supabase = Supabase.instance.client;
  final _mediaStorage = MediaStorageService();
  final _eventStorage = EventStorageService();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  // MEDIA GALLERY SYNC
  Future<Map<String, dynamic>> syncMediaGallery(String centerName, List<MediaItem> localItems) async {
    if (_isSyncing) return {'success': false, 'message': 'Sync in progress'};
    if (!await isOnline()) return {'success': false, 'message': 'Offline'};

    _isSyncing = true;
    int uploaded = 0;
    int downloaded = 0;

    try {
      // Upload unsynced local items
      for (var item in localItems.where((i) => !i.isSynced && i.localPath != null)) {
        final file = File(item.localPath!);
        if (await file.exists()) {
          final url = await _mediaStorage.uploadPhoto(file, centerName);
          if (url != null) {
            await _supabase.from('media_gallery').insert({
              'title': item.title,
              'description': item.description,
              'photo_url': url,
              'local_path': item.localPath,
              'center_name': centerName,
              'uploaded_by': item.uploadedBy,
              'is_synced': true,
            });
            uploaded++;
          }
        }
      }

      // Download from cloud
      final cloudItems = await _supabase
          .from('media_gallery')
          .select()
          .eq('center_name', centerName)
          .order('created_at', ascending: false);

      downloaded = (cloudItems as List).length;

      return {
        'success': true,
        'uploaded': uploaded,
        'downloaded': downloaded,
        'cloudItems': cloudItems,
      };
    } catch (e) {
      print('Media sync error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isSyncing = false;
    }
  }

  // EVENT PHOTOS SYNC - Lazy load on demand
  Future<Map<String, dynamic>> syncEventPhotos(int eventId, String centerName, List<String> localPaths) async {
    if (_isSyncing) return {'success': false, 'message': 'Sync in progress'};
    if (!await isOnline()) return {'success': false, 'message': 'Offline'};

    _isSyncing = true;
    int uploaded = 0;
    List<String> photoUrls = [];

    try {
      // Upload local photos that aren't URLs yet
      for (var path in localPaths) {
        if (!path.startsWith('http')) {
          final file = File(path);
          if (await file.exists()) {
            final url = await _eventStorage.uploadPhoto(file, eventId.toString());
            if (url != null) {
              photoUrls.add(url);
              await _supabase.from('event_photos').insert({
                'event_id': eventId,
                'photo_url': url,
                'local_path': path,
                'center_name': centerName,
                'is_synced': true,
              });
              uploaded++;
            }
          }
        } else {
          photoUrls.add(path);
        }
      }

      // Download any cloud photos for this event
      final cloudPhotos = await _supabase
          .from('event_photos')
          .select('photo_url')
          .eq('event_id', eventId);

      for (var photo in (cloudPhotos as List)) {
        final url = photo['photo_url'] as String;
        if (!photoUrls.contains(url)) {
          photoUrls.add(url);
        }
      }

      return {
        'success': true,
        'uploaded': uploaded,
        'photoUrls': photoUrls,
      };
    } catch (e) {
      print('Event photos sync error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isSyncing = false;
    }
  }

  // Download event photos from cloud only
  Future<List<String>> downloadEventPhotos(int eventId) async {
    try {
      final response = await _supabase
          .from('event_photos')
          .select('photo_url')
          .eq('event_id', eventId);

      return (response as List).map((e) => e['photo_url'] as String).toList();
    } catch (e) {
      print('Error downloading event photos: $e');
      return [];
    }
  }

  // Download media gallery from cloud
  Future<List<MediaItem>> downloadMediaGallery(String centerName) async {
    try {
      final response = await _supabase
          .from('media_gallery')
          .select()
          .eq('center_name', centerName)
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        return MediaItem(
          id: data['id'] as int,
          title: data['title'] as String?,
          description: data['description'] as String?,
          photoUrl: data['photo_url'] as String,
          localPath: data['local_path'] as String?,
          centerName: data['center_name'] as String,
          uploadedBy: data['uploaded_by'] as String?,
          isSynced: true,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error downloading media gallery: $e');
      return [];
    }
  }
}
