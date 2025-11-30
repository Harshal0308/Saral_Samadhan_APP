import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

/// FFI bindings for the face alignment native library
class FaceAlignBindings {
  late final ffi.DynamicLibrary _dylib;
  late final _AlignFaceNative _alignFace;
  late final _FreeAlignedFaceNative _freeAlignedFace;
  late final _GetAlignedFaceSizeNative _getAlignedFaceSize;
  late final _GetAlignedFaceBytesNative _getAlignedFaceBytes;

  FaceAlignBindings() {
    _dylib = _loadLibrary();
    _alignFace = _dylib.lookupFunction<_AlignFaceC, _AlignFaceNative>(
      'align_face',
    );
    _freeAlignedFace = _dylib.lookupFunction<_FreeAlignedFaceC, _FreeAlignedFaceNative>(
      'free_aligned_face',
    );
    _getAlignedFaceSize = _dylib.lookupFunction<_GetAlignedFaceSizeC, _GetAlignedFaceSizeNative>(
      'get_aligned_face_size',
    );
    _getAlignedFaceBytes = _dylib.lookupFunction<_GetAlignedFaceBytesC, _GetAlignedFaceBytesNative>(
      'get_aligned_face_bytes',
    );
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libface_align.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }
  }

  /// Align a face using 5 landmarks
  /// 
  /// [src] - RGB image data (width * height * 3 bytes)
  /// [width] - Image width
  /// [height] - Image height  
  /// [landmarks] - 10 floats [leftEye_x, leftEye_y, rightEye_x, rightEye_y, ...]
  /// 
  /// Returns aligned 112x112 RGB image or null on error
  ffi.Pointer<ffi.Uint8>? alignFace(
    ffi.Pointer<ffi.Uint8> src,
    int width,
    int height,
    ffi.Pointer<ffi.Float> landmarks,
  ) {
    final result = _alignFace(src, width, height, landmarks);
    return result.address == 0 ? null : result;
  }

  /// Free memory allocated by alignFace
  void freeAlignedFace(ffi.Pointer<ffi.Uint8> aligned) {
    if (aligned.address != 0) {
      _freeAlignedFace(aligned);
    }
  }

  /// Get output size (112 for ArcFace)
  int getAlignedFaceSize() => _getAlignedFaceSize();

  /// Get output size in bytes (112 * 112 * 3)
  int getAlignedFaceBytes() => _getAlignedFaceBytes();
}

// C function signatures
typedef _AlignFaceC = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<ffi.Uint8> src,
  ffi.Int32 width,
  ffi.Int32 height,
  ffi.Pointer<ffi.Float> landmarks,
);

typedef _AlignFaceNative = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<ffi.Uint8> src,
  int width,
  int height,
  ffi.Pointer<ffi.Float> landmarks,
);

typedef _FreeAlignedFaceC = ffi.Void Function(ffi.Pointer<ffi.Uint8> aligned);
typedef _FreeAlignedFaceNative = void Function(ffi.Pointer<ffi.Uint8> aligned);

typedef _GetAlignedFaceSizeC = ffi.Int32 Function();
typedef _GetAlignedFaceSizeNative = int Function();

typedef _GetAlignedFaceBytesC = ffi.Size Function();
typedef _GetAlignedFaceBytesNative = int Function();