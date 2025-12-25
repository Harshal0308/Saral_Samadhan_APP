import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class EventPhotoViewerPage extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  final String eventTitle;

  const EventPhotoViewerPage({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
    required this.eventTitle,
  });

  @override
  State<EventPhotoViewerPage> createState() => _EventPhotoViewerPageState();
}

class _EventPhotoViewerPageState extends State<EventPhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isLocalPath(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.eventTitle,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.photoUrls.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final photoPath = widget.photoUrls[index];
          final isLocal = _isLocalPath(photoPath);
          
          return PhotoViewGalleryPageOptions(
            imageProvider: isLocal
                ? FileImage(File(photoPath)) as ImageProvider
                : CachedNetworkImageProvider(photoPath),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: photoPath),
          );
        },
        itemCount: widget.photoUrls.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
