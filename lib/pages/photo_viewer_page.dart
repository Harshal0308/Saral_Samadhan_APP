import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewerPage extends StatelessWidget {
  final String imagePath;

  const PhotoViewerPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain, // Ensure the entire image is visible
        ),
      ),
    );
  }
}
