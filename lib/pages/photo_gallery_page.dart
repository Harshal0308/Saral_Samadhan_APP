import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/media_gallery_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/pages/events_activities_page.dart';
import 'package:samadhan_app/pages/photo_viewer_page.dart';

class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MediaGalleryProvider>(context, listen: false).loadItems();
    });
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaGalleryProvider>(context, listen: false);
      
      await mediaProvider.addPhoto(
        photoFile: File(photo.path),
        centerName: userProvider.userSettings.selectedCenter ?? '',
        uploadedBy: userProvider.userSettings.name,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added! Tap Sync to upload.')),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 70);
    if (photos.isNotEmpty && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaGalleryProvider>(context, listen: false);
      
      for (var photo in photos) {
        await mediaProvider.addPhoto(
          photoFile: File(photo.path),
          centerName: userProvider.userSettings.selectedCenter ?? '',
          uploadedBy: userProvider.userSettings.name,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${photos.length} photos added! Tap Sync to upload.')),
      );
    }
  }

  Future<void> _syncPhotos() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final mediaProvider = Provider.of<MediaGalleryProvider>(context, listen: false);
    final centerName = userProvider.userSettings.selectedCenter ?? '';
    
    if (centerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a center first')),
      );
      return;
    }

    await mediaProvider.syncPhotos(centerName);
    
    if (mounted) {
      if (mediaProvider.syncError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: ${mediaProvider.syncError}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos synced successfully!')),
        );
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
          'Media Gallery',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<MediaGalleryProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: provider.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, color: Color(0xFF8B5CF6)),
                    onPressed: provider.isSyncing ? null : _syncPhotos,
                  ),
                  if (provider.unsyncedCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${provider.unsyncedCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<MediaGalleryProvider, EventProvider>(
        builder: (context, mediaProvider, eventProvider, child) {
          final mediaItems = mediaProvider.items;
          final eventPhotos = eventProvider.events
              .expand((e) => e.photoPaths.map((p) => {'path': p, 'event': e}))
              .toList();
          final totalPhotos = mediaItems.length + eventPhotos.length;

          return Column(
            children: [
              // Action Buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadPhoto,
                        icon: const Icon(Icons.upload, size: 20),
                        label: const Text('Upload'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFFDDD6FE)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalPhotos photos',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (mediaProvider.unsyncedCount > 0)
                      Text(
                        '${mediaProvider.unsyncedCount} pending sync',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Gallery Grid
              Expanded(
                child: totalPhotos == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No photos yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: mediaItems.length,
                        itemBuilder: (context, index) {
                          final item = mediaItems[index];
                          final isLocal = item.localPath != null && 
                              !item.photoUrl.startsWith('http');
                          
                          return GestureDetector(
                            onTap: () {
                              final path = item.localPath ?? item.photoUrl;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewerPage(
                                    imagePath: path,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isLocal
                                      ? Image.file(
                                          File(item.localPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          item.photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                ),
                                if (!item.isSynced)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
