import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'face_recognition_service.dart';

/// Service for generating augmented face embeddings during enrollment.
/// 
/// This improves face recognition accuracy under varying lighting conditions
/// by storing multiple embeddings per student:
/// - Original aligned face
/// - Brightness increased by ~8%
/// - Brightness decreased by ~8%  
/// - Contrast increased by ~8%
///
/// At attendance time, only one embedding is generated per detected face,
/// and it's compared against all stored embeddings using max similarity.
class EmbeddingAugmentationService {
  static final EmbeddingAugmentationService _instance = 
      EmbeddingAugmentationService._internal();
  
  factory EmbeddingAugmentationService() => _instance;
  
  EmbeddingAugmentationService._internal();

  final FaceRecognitionService _faceService = FaceRecognitionService();

  /// Augmentation parameters (8% adjustments)
  static const double _brightnessIncrease = 1.08;
  static const double _brightnessDecrease = 0.92;
  static const double _contrastIncrease = 1.08;

  /// Confidence threshold for auto-marking attendance
  static const double confidenceThreshold = 0.65;

  /// Generate augmented embeddings for enrollment.
  /// Returns a list of 4 embeddings: [original, bright+, bright-, contrast+]
  /// Returns null if face detection or alignment fails.
  Future<List<List<double>>?> generateAugmentedEmbeddings(
    img.Image image,
    DetectedFace face,
  ) async {
    final List<List<double>> embeddings = [];

    // 1. Original aligned face embedding
    final originalEmbedding = _faceService.getEmbeddingWithAlignment(image, face);
    if (originalEmbedding == null) {
      print('❌ Failed to generate original embedding');
      return null;
    }
    embeddings.add(originalEmbedding);
    print('✅ Generated original embedding');

    // Get the aligned face image for augmentation
    final alignedFace = _getAlignedFaceImage(image, face);
    if (alignedFace == null) {
      print('⚠️ Could not get aligned face for augmentation, using original only');
      return embeddings;
    }

    // 2. Brightness increased by ~8%
    final brightImage = _adjustBrightness(alignedFace, _brightnessIncrease);
    final brightEmbedding = await _faceService.getEmbeddingFromImage(brightImage);
    if (brightEmbedding != null) {
      embeddings.add(brightEmbedding);
      print('✅ Generated brightness+ embedding');
    }

    // 3. Brightness decreased by ~8%
    final darkImage = _adjustBrightness(alignedFace, _brightnessDecrease);
    final darkEmbedding = await _faceService.getEmbeddingFromImage(darkImage);
    if (darkEmbedding != null) {
      embeddings.add(darkEmbedding);
      print('✅ Generated brightness- embedding');
    }

    // 4. Contrast increased by ~8%
    final contrastImage = _adjustContrast(alignedFace, _contrastIncrease);
    final contrastEmbedding = await _faceService.getEmbeddingFromImage(contrastImage);
    if (contrastEmbedding != null) {
      embeddings.add(contrastEmbedding);
      print('✅ Generated contrast+ embedding');
    }

    print('📊 Generated ${embeddings.length} augmented embeddings');
    return embeddings;
  }

  /// Generate augmented embeddings from a pre-cropped/aligned face image.
  /// Used when the image is already cropped to face region.
  Future<List<List<double>>?> generateAugmentedEmbeddingsFromCropped(
    img.Image croppedFaceImage,
  ) async {
    final List<List<double>> embeddings = [];

    // Resize to model input size (112x112)
    final resizedImage = img.copyResize(
      croppedFaceImage,
      width: 112,
      height: 112,
      interpolation: img.Interpolation.linear,
    );

    // 1. Original embedding
    final originalEmbedding = await _faceService.getEmbeddingFromImage(resizedImage);
    if (originalEmbedding == null) {
      print('❌ Failed to generate original embedding from cropped image');
      return null;
    }
    embeddings.add(originalEmbedding);
    print('✅ Generated original embedding from cropped');

    // 2. Brightness increased
    final brightImage = _adjustBrightness(resizedImage, _brightnessIncrease);
    final brightEmbedding = await _faceService.getEmbeddingFromImage(brightImage);
    if (brightEmbedding != null) {
      embeddings.add(brightEmbedding);
      print('✅ Generated brightness+ embedding');
    }

    // 3. Brightness decreased
    final darkImage = _adjustBrightness(resizedImage, _brightnessDecrease);
    final darkEmbedding = await _faceService.getEmbeddingFromImage(darkImage);
    if (darkEmbedding != null) {
      embeddings.add(darkEmbedding);
      print('✅ Generated brightness- embedding');
    }

    // 4. Contrast increased
    final contrastImage = _adjustContrast(resizedImage, _contrastIncrease);
    final contrastEmbedding = await _faceService.getEmbeddingFromImage(contrastImage);
    if (contrastEmbedding != null) {
      embeddings.add(contrastEmbedding);
      print('✅ Generated contrast+ embedding');
    }

    print('📊 Generated ${embeddings.length} augmented embeddings from cropped');
    return embeddings;
  }

  /// Adjust image brightness by a factor.
  /// factor > 1.0 increases brightness, < 1.0 decreases.
  img.Image _adjustBrightness(img.Image source, double factor) {
    final result = img.Image(width: source.width, height: source.height);
    
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        
        // Apply brightness factor and clamp to valid range
        final r = (pixel.r * factor).clamp(0, 255).toInt();
        final g = (pixel.g * factor).clamp(0, 255).toInt();
        final b = (pixel.b * factor).clamp(0, 255).toInt();
        
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return result;
  }

  /// Adjust image contrast by a factor.
  /// factor > 1.0 increases contrast, < 1.0 decreases.
  img.Image _adjustContrast(img.Image source, double factor) {
    final result = img.Image(width: source.width, height: source.height);
    const double midpoint = 128.0;
    
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        
        // Apply contrast adjustment around midpoint
        final r = ((pixel.r - midpoint) * factor + midpoint).clamp(0, 255).toInt();
        final g = ((pixel.g - midpoint) * factor + midpoint).clamp(0, 255).toInt();
        final b = ((pixel.b - midpoint) * factor + midpoint).clamp(0, 255).toInt();
        
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return result;
  }

  /// Get aligned face image using native FFI alignment.
  /// Returns 112x112 RGB image or null if alignment fails.
  img.Image? _getAlignedFaceImage(img.Image image, DetectedFace face) {
    try {
      // Validate landmarks
      if (face.landmarks.length != 5) {
        print('❌ Expected 5 landmarks, got ${face.landmarks.length}');
        return null;
      }

      // Convert to RGB bytes
      final rgbBytes = _imgImageToRGB(image);

      // Prepare landmarks
      final landmarksList = <double>[];
      for (final point in face.landmarks) {
        landmarksList.add(point.x);
        landmarksList.add(point.y);
      }

      // Call native alignment
      final alignedBytes = FaceAlignBindings.instance.alignFace(
        imageBytes: rgbBytes,
        width: image.width,
        height: image.height,
        landmarks: landmarksList,
      );

      if (alignedBytes == null) {
        return null;
      }

      // Convert back to img.Image
      return _rgbToImgImage(alignedBytes, 112, 112);
    } catch (e) {
      print('❌ Error getting aligned face: $e');
      return null;
    }
  }

  Uint8List _imgImageToRGB(img.Image image) {
    final rgb = Uint8List(image.width * image.height * 3);
    int index = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rgb[index++] = pixel.r.toInt();
        rgb[index++] = pixel.g.toInt();
        rgb[index++] = pixel.b.toInt();
      }
    }

    return rgb;
  }

  img.Image _rgbToImgImage(Uint8List rgb, int width, int height) {
    final image = img.Image(width: width, height: height);
    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = rgb[index++];
        final g = rgb[index++];
        final b = rgb[index++];
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }
}
