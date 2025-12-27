import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import '../models/media_item.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/photo_sync_service.dart';
import 'package:samadhan_app/services/media_storage_service.dart';

class MediaGalleryProvider with ChangeNotifier {
  final _mediaStore = intMapStoreFactory.store('media_gallery');
  final DatabaseService _dbService = DatabaseService();
  final PhotoSyncService _syncService = PhotoSyncService();
  final MediaStorageService _storageService = MediaStorageService();

  List<MediaItem> _items = [];
  bool _isSyncing = false;
  String? _syncError;

  List<MediaItem> get items => _items;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get unsyncedCount => _items.where((i) => !i.isSynced).length;

  Future<void> loadItems() async {
    final db = await _dbService.database;
    final snapshots = await _mediaStore.find(db);
    _items = snapshots
        .map((s) => MediaItem.fromMap(s.value, s.key))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addPhoto({
    required File photoFile,
    required String centerName,
    String? title,
    String? description,
    String? uploadedBy,
  }) async {
    final db = await _dbService.database;
    
    final item = MediaItem(
      id: 0,
      title: title,
      description: description,
      photoUrl: photoFile.path,
      localPath: photoFile.path,
      centerName: centerName,
      uploadedBy: uploadedBy,
      isSynced: false,
      createdAt: DateTime.now(),
    );

    await _mediaStore.add(db, item.toMap());
    await loadItems();
  }

  Future<void> syncPhotos(String centerName) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final unsyncedItems = _items.where((i) => !i.isSynced).toList();

      for (var item in unsyncedItems) {
        if (item.localPath != null) {
          final file = File(item.localPath!);
          if (await file.exists()) {
            final url = await _storageService.uploadPhoto(file, centerName);
            if (url != null) {
              final updatedItem = item.copyWith(photoUrl: url, isSynced: true);
              await _mediaStore.update(
                db,
                updatedItem.toMap(),
                finder: Finder(filter: Filter.byKey(item.id)),
              );
            }
          }
        }
      }

      // Download from cloud
      final cloudItems = await _syncService.downloadMediaGallery(centerName);
      for (var cloudItem in cloudItems) {
        final exists = _items.any((i) => i.photoUrl == cloudItem.photoUrl);
        if (!exists) {
          await _mediaStore.add(db, cloudItem.toMap());
        }
      }

      await loadItems();
    } catch (e) {
      _syncError = e.toString();
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(int id) async {
    final db = await _dbService.database;
    await _mediaStore.delete(db, finder: Finder(filter: Filter.byKey(id)));
    await loadItems();
  }
}
