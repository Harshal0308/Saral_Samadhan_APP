import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

// ============================================================================
// FFI Bindings for Native Face Alignment
// ============================================================================

typedef AlignFaceNative = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<ffi.Uint8> src,
  ffi.Int32 width,
  ffi.Int32 height,
  ffi.Pointer<ffi.Float> landmarks,
);

typedef AlignFaceDart = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<ffi.Uint8> src,
  int width,
  int height,
  ffi.Pointer<ffi.Float> landmarks,
);

typedef FreeAlignedFaceNative = ffi.Void Function(ffi.Pointer<ffi.Uint8> aligned);
typedef FreeAlignedFaceDart = void Function(ffi.Pointer<ffi.Uint8> aligned);

typedef GetAlignedFaceSizeNative = ffi.Int32 Function();
typedef GetAlignedFaceSizeDart = int Function();

class FaceAlignBindings {
  static FaceAlignBindings? _instance;
  late final ffi.DynamicLibrary _dylib;
  
  late final AlignFaceDart _alignFace;
  late final FreeAlignedFaceDart _freeAlignedFace;
  late final GetAlignedFaceSizeDart _getAlignedFaceSize;

  FaceAlignBindings._() {
    _dylib = _loadLibrary();
    _alignFace = _dylib
        .lookup<ffi.NativeFunction<AlignFaceNative>>('align_face')
        .asFunction();
    _freeAlignedFace = _dylib
        .lookup<ffi.NativeFunction<FreeAlignedFaceNative>>('free_aligned_face')
        .asFunction();
    _getAlignedFaceSize = _dylib
        .lookup<ffi.NativeFunction<GetAlignedFaceSizeNative>>('get_aligned_face_size')
        .asFunction();
  }

  static FaceAlignBindings get instance {
    _instance ??= FaceAlignBindings._();
    return _instance!;
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libface_align.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// Align face using 5-point landmarks
  /// Returns RGB bytes (112x112x3) or null if alignment fails
  Uint8List? alignFace({
    required Uint8List imageBytes,
    required int width,
    required int height,
    required List<double> landmarks,
  }) {
    if (landmarks.length != 10) {
      print('❌ Landmarks must contain exactly 10 values (5 points), got ${landmarks.length}');
      return null;
    }

    final srcPtr = malloc.allocate<ffi.Uint8>(imageBytes.length);
    final landmarksPtr = malloc.allocate<ffi.Float>(landmarks.length * ffi.sizeOf<ffi.Float>());

    try {
      // Copy data to native memory
      final srcList = srcPtr.asTypedList(imageBytes.length);
      srcList.setAll(0, imageBytes);

      final landmarksList = landmarksPtr.asTypedList(landmarks.length);
      for (int i = 0; i < landmarks.length; i++) {
        landmarksList[i] = landmarks[i];
      }

      // Call native function
      final resultPtr = _alignFace(srcPtr, width, height, landmarksPtr);

      if (resultPtr == ffi.nullptr) {
        print('❌ Native face alignment returned null');
        return null;
      }

      // Get output size (112x112x3 = 37,632 bytes)
      final size = 112 * 112 * 3;
      final result = Uint8List.fromList(resultPtr.asTypedList(size));

      // Free native memory
      _freeAlignedFace(resultPtr);

      return result;
    } catch (e) {
      print('❌ Error in native alignFace: $e');
      return null;
    } finally {
      malloc.free(srcPtr);
      malloc.free(landmarksPtr);
    }
  }

  int getAlignedFaceSize() => _getAlignedFaceSize();
}

// ============================================================================
// Updated DetectedFace class with 5 landmarks
// ============================================================================

class DetectedFace {
  final Rect boundingBox;
  final List<Point<double>> landmarks; // Now stores 5 landmarks

  DetectedFace(this.boundingBox, this.landmarks);
}

// ============================================================================
// Face Recognition Service with Native FFI Alignment
// ============================================================================

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() {
    return _instance;
  }
  FaceRecognitionService._internal();

  static const String _embedderModelFile = "assets/ml/model.tflite";
  static const int _embeddingInputSize = 112;
  static const int _embeddingOutputSize = 512;

  tfl.Interpreter? _embedder;
  FaceDetector? _detector;
  final FaceAlignBindings _faceAlign = FaceAlignBindings.instance;

  bool _isEmbedderInputFloat32 = true;
  bool _isEmbedderOutputFloat32 = true;

  Future<void> loadModel() async {
    try {
      // Load the embedder model
      _embedder = await tfl.Interpreter.fromAsset(
        _embedderModelFile,
        options: tfl.InterpreterOptions()..threads = 4,
      );
      print('✅ Embedder model loaded successfully');
      print('ℹ️ Embedder input type: float32, output type: float32');

      // Initialize ML Kit face detector
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        minFaceSize: 0.05,
      );
      _detector = FaceDetector(options: options);
      print('✅ ML Kit Face Detector initialized');

      // Verify native library
      final alignSize = _faceAlign.getAlignedFaceSize();
      print('✅ Native face alignment library loaded (output: ${alignSize}x$alignSize)');

    } catch (e, stack) {
      print('❌ Failed to load models: $e\n$stack');
    }
  }

  // ============================================================================
  // UPDATED: Face detection with 5 landmarks extraction
  // ============================================================================
  
  Future<List<DetectedFace>> detectFaces(img.Image image) async {
    if (_detector == null) {
      print('❌ Face Detector not initialized');
      return [];
    }

    try {
      final inputImage = await _convertImageToInputImage(image);
      if (inputImage == null) return [];

      final faces = await _detector!.processImage(inputImage);

      final List<DetectedFace> detectedFaces = [];
      for (final face in faces) {
        // Extract all 5 landmarks needed for native alignment
        final leftEye = face.landmarks[FaceLandmarkType.leftEye];
        final rightEye = face.landmarks[FaceLandmarkType.rightEye];
        final noseBase = face.landmarks[FaceLandmarkType.noseBase];
        final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
        final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

        // Only add face if all 5 landmarks are detected
        if (leftEye != null && rightEye != null && noseBase != null && 
            leftMouth != null && rightMouth != null) {
          final landmarks = [
            Point<double>(leftEye.position.x.toDouble(), leftEye.position.y.toDouble()),
            Point<double>(rightEye.position.x.toDouble(), rightEye.position.y.toDouble()),
            Point<double>(noseBase.position.x.toDouble(), noseBase.position.y.toDouble()),
            Point<double>(leftMouth.position.x.toDouble(), leftMouth.position.y.toDouble()),
            Point<double>(rightMouth.position.x.toDouble(), rightMouth.position.y.toDouble()),
          ];
          detectedFaces.add(DetectedFace(face.boundingBox, landmarks));
        } else {
          print('⚠️ Skipping face - missing required landmarks');
        }
      }
      
      print('✅ Detected ${detectedFaces.length} faces with complete landmarks');
      return detectedFaces;
    } catch (e, stack) {
      print('❌ Error detecting faces: $e\n$stack');
      return [];
    }
  }

  Future<InputImage?> _convertImageToInputImage(img.Image image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(img.encodeJpg(image));

      final inputImage = InputImage.fromFilePath(tempFile.path);
      return inputImage;
    } catch (e, stack) {
      print("❌ Error converting image to InputImage: $e\n$stack");
      return null;
    }
  }

  // ============================================================================
  // UPDATED: Face alignment with native FFI (replaces Dart-based alignment)
  // ============================================================================

  List<double>? getEmbeddingWithAlignment(img.Image image, DetectedFace face) {
    if (_embedder == null) {
      print('❌ Embedder model not loaded');
      return null;
    }

    // Use native FFI alignment instead of Dart alignment
    final alignedFace = _alignFaceNative(image, face);
    if (alignedFace == null) {
      print('❌ Native face alignment failed');
      return null;
    }

    return _generateEmbedding(alignedFace);
  }

  /// Native face alignment using FFI
  img.Image? _alignFaceNative(img.Image image, DetectedFace face) {
    try {
      // Validate: must have 5 landmarks
      if (face.landmarks.length != 5) {
        print('❌ Expected 5 landmarks, got ${face.landmarks.length}');
        return null;
      }

      // Convert img.Image to RGB bytes
      final rgbBytes = _imgImageToRGB(image);

      // Prepare landmarks as flat list [x1, y1, x2, y2, ..., x5, y5]
      final landmarksList = <double>[];
      for (final point in face.landmarks) {
        landmarksList.add(point.x);
        landmarksList.add(point.y);
      }

      // Call native alignment
      final alignedBytes = _faceAlign.alignFace(
        imageBytes: rgbBytes,
        width: image.width,
        height: image.height,
        landmarks: landmarksList,
      );

      if (alignedBytes == null) {
        return null;
      }

      // Convert aligned RGB bytes back to img.Image (112x112)
      return _rgbToImgImage(alignedBytes, 112, 112);
      
    } catch (e, stack) {
      print('❌ Error in _alignFaceNative: $e\n$stack');
      return null;
    }
  }

  /// Convert img.Image to RGB bytes
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

  /// Convert RGB bytes to img.Image
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

  // ============================================================================
  // Direct embedding generation (for pre-cropped images)
  // ============================================================================

  Future<List<double>?> getEmbeddingFromImage(img.Image image) async {
    if (_embedder == null) {
      print('❌ Embedder model not loaded');
      return null;
    }

    try {
      // Resize to model input size
      final resizedImage = img.copyResize(
        image,
        width: _embeddingInputSize,
        height: _embeddingInputSize,
        interpolation: img.Interpolation.linear
      );

      return _generateEmbedding(resizedImage);
    } catch (e, stack) {
      print('❌ Error generating embedding from image: $e\n$stack');
      return null;
    }
  }

  Future<List<double>?> getEmbeddingForCroppedImage(File croppedImageFile) async {
    if (_embedder == null) {
      print('❌ Embedder model not loaded');
      return null;
    }

    try {
      final imageBytes = await croppedImageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      return getEmbeddingFromImage(image);
    } catch (e, stack) {
      print('❌ Error processing cropped image file: $e\n$stack');
      return null;
    }
  }

  // ============================================================================
  // UPDATED: Generate embedding (no extra preprocessing needed)
  // ============================================================================

  List<double>? _generateEmbedding(img.Image resizedImage) {
    // Native alignment already gives us 112x112, so just preprocess
    var inputBuffer = _preProcessInput(resizedImage);

    // Reshape input to [1, 112, 112, 3]
    var reshapedInput = List.generate(
      1,
      (_) => List.generate(
        _embeddingInputSize,
        (i) => List.generate(
          _embeddingInputSize,
          (j) => List.generate(
            3,
            (k) => inputBuffer[i * _embeddingInputSize * 3 + j * 3 + k],
          ),
        ),
      ),
    );

    // Create output buffer
    final output = _isEmbedderOutputFloat32
        ? List.generate(1, (index) => List.filled(_embeddingOutputSize, 0.0))
        : List.generate(1, (index) => List.filled(_embeddingOutputSize, 0));

    // Run inference
    _embedder!.run(reshapedInput, output);

    // Convert output to List<double> and normalize
    final List<double> embedding;
    if (_isEmbedderOutputFloat32) {
      embedding = (output[0] as List<double>);
    } else {
      embedding = (output[0] as List<int>).map((e) => e.toDouble()).toList();
    }

    // Normalize
    final double norm = sqrt(embedding.map((e) => e * e).reduce((a, b) => a + b));
    if (norm == 0.0) {
      print('⚠️ Embedding norm is zero');
      return null;
    }

    return embedding.map((e) => e / norm).toList();
  }

  // ============================================================================
  // Preprocessing (simplified - native alignment handles rotation/cropping)
  // ============================================================================

  List<double> _preProcessInput(img.Image image) {
    final int inputSize = _embeddingInputSize;

    // Validate size
    if (image.width != inputSize || image.height != inputSize) {
      throw ArgumentError(
          'Input image must be ${inputSize}x$inputSize. Received ${image.width}x${image.height}');
    }

    // Convert to normalized float32 [0.0-1.0]
    var input = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(input.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input.toList();
  }

  // ============================================================================
  // Utility functions (unchanged)
  // ============================================================================

  Student? findBestMatch(List<double> emb, List<Student> students, double threshold) {
    Student? bestStudent;
    double bestOverallSim = -1.0;
    double secondBestOverallSim = -1.0;

    for (var student in students) {
      if (student.embeddings != null && student.embeddings!.isNotEmpty) {
        double bestSimForStudent = -1.0;

        for (var storedEmb in student.embeddings!) {
          if (storedEmb.isNotEmpty && storedEmb.length == emb.length) {
            double sim = cosineSimilarity(emb, storedEmb);
            if (sim > bestSimForStudent) {
              bestSimForStudent = sim;
            }
          }
        }

        if (bestSimForStudent > bestOverallSim) {
          secondBestOverallSim = bestOverallSim;
          bestOverallSim = bestSimForStudent;
          bestStudent = student;
        } else if (bestSimForStudent > secondBestOverallSim) {
          secondBestOverallSim = bestSimForStudent;
        }
      }
    }

    const margin = 0.01;

    if (bestOverallSim > threshold && (bestOverallSim - secondBestOverallSim > margin)) {
      return bestStudent;
    }

    return null;
  }

  double cosineSimilarity(List<double> emb1, List<double> emb2) {
    if (emb1.isEmpty || emb2.isEmpty) return 0.0;
    if (emb1.length != emb2.length) {
      print('⚠️ Embedding lengths do not match! (${emb1.length} vs ${emb2.length})');
      return 0.0;
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
      norm1 += emb1[i] * emb1[i];
      norm2 += emb2[i] * emb2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  void dispose() {
    _detector?.close();
    _embedder?.close();
  }
}