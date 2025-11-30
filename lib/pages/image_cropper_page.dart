import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ImageCropperPage extends StatefulWidget {
  final File imageFile;

  const ImageCropperPage({super.key, required this.imageFile});

  @override
  State<ImageCropperPage> createState() => _ImageCropperPageState();
}

class _ImageCropperPageState extends State<ImageCropperPage> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final double _cropBoxSize = 300.0;

  void _setZoom(double scale) {
    final newMatrix = Matrix4.identity()..scale(scale);
    _transformationController.value = newMatrix;
  }

  void _onConfirm() async {
    try {
      // 1. Capture the entire RepaintBoundary as an image (what user actually sees)
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image capturedImage = await boundary.toImage(pixelRatio: 1.0);
      
      // 2. Convert to ByteData
      ByteData? byteData = await capturedImage.toByteData(
          format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      Uint8List capturedBytes = byteData.buffer.asUint8List();
      
      // 3. Decode the captured screenshot
      img.Image? screenshot = img.decodeImage(capturedBytes);
      if (screenshot == null) return;
      
      // 4. Get crop box position in screen coordinates
      final screenSize = MediaQuery.of(context).size;
      final cropBoxLeft = (screenSize.width - _cropBoxSize) / 2;
      final cropBoxTop = (screenSize.height - _cropBoxSize) / 2;
      
      // 5. Get the RepaintBoundary's position on screen
      RenderBox boundaryBox = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderBox;
      Offset boundaryOffset = boundaryBox.localToGlobal(Offset.zero);
      
      // 6. Calculate crop box position relative to the captured image
      final cropX = (cropBoxLeft - boundaryOffset.dx).round();
      final cropY = (cropBoxTop - boundaryOffset.dy).round();
      final cropWidth = _cropBoxSize.round();
      final cropHeight = _cropBoxSize.round();
      
      // 7. Ensure crop is within bounds
      final x = cropX.clamp(0, screenshot.width - 1);
      final y = cropY.clamp(0, screenshot.height - 1);
      final w = cropWidth.clamp(1, screenshot.width - x);
      final h = cropHeight.clamp(1, screenshot.height - y);
      
      // 8. Crop the screenshot to get exactly what's in the crop box
      final croppedImage = img.copyCrop(
        screenshot,
        x: x,
        y: y,
        width: w,
        height: h,
      );
      
      // 9. Return the cropped image
      Navigator.of(context).pop(croppedImage);
      
    } catch (e) {
      print('Error cropping image: $e');
      // Handle error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Crop Your Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _onConfirm,
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  widget.imageFile,
                  key: _imageKey,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Crop box overlay
          Center(
            child: Container(
              width: _cropBoxSize,
              height: _cropBoxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () => _setZoom(1.0),
                    child: const Text('1×', style: TextStyle(color: Colors.white))),
                TextButton(
                    onPressed: () => _setZoom(1.5),
                    child: const Text('1.5×', style: TextStyle(color: Colors.white))),
                TextButton(
                    onPressed: () => _setZoom(2.0),
                    child: const Text('2×', style: TextStyle(color: Colors.white))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _onConfirm,
                child: const Text(
                  "DONE",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}