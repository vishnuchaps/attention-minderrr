import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Converts preview-stream frames to JPEG without triggering iOS still-photo
/// capture. The returned file remains compatible with ML Kit and MediaPipe.
class CameraFrameEncoder {
  CameraFrameEncoder._();

  static const _deviceOrientationDegrees = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Rotation required to turn a raw sensor frame into an upright image.
  ///
  /// iOS exposes the sensor rotation directly. Android additionally requires
  /// device-orientation compensation, with the sign depending on whether the
  /// selected lens is front- or rear-facing.
  static int rotationForCamera({
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required bool isIOS,
  }) {
    if (isIOS) return camera.sensorOrientation % 360;

    final compensation = _deviceOrientationDegrees[deviceOrientation] ?? 0;
    return camera.lensDirection == CameraLensDirection.front
        ? (camera.sensorOrientation + compensation) % 360
        : (camera.sensorOrientation - compensation + 360) % 360;
  }

  static Future<XFile> encode(
    CameraImage frame, {
    int rotationDegrees = 0,
  }) async {
    var image = switch (frame.format.group) {
      ImageFormatGroup.bgra8888 => _decodeBgra(frame),
      ImageFormatGroup.nv21 => _decodeNv21(frame),
      ImageFormatGroup.yuv420 => _decodeYuv420(frame),
      _ => throw UnsupportedError(
        'Unsupported camera image format: ${frame.format.group}',
      ),
    };

    // Image-stream buffers do not carry the EXIF orientation that takePicture
    // adds to JPEGs. Rotate the decoded pixels into display orientation before
    // handing the file to ML Kit, MediaPipe, or the backend.
    final normalizedRotation = rotationDegrees % 360;
    if (normalizedRotation != 0) {
      image = img.copyRotate(image, angle: normalizedRotation);
    }

    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 82));
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/attention-frame-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(bytes, flush: false);
    return XFile(path, mimeType: 'image/jpeg', length: bytes.length);
  }

  static img.Image _decodeBgra(CameraImage frame) {
    return img.Image.fromBytes(
      width: frame.width,
      height: frame.height,
      bytes: frame.planes.first.bytes.buffer,
      bytesOffset: frame.planes.first.bytes.offsetInBytes,
      rowStride: frame.planes.first.bytesPerRow,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _decodeNv21(CameraImage frame) {
    final bytes = frame.planes.first.bytes;
    return _decodeYuv(
      width: frame.width,
      height: frame.height,
      yAt: (x, y) => bytes[y * frame.width + x],
      uAt: (x, y) {
        final offset = frame.width * frame.height + (y ~/ 2) * frame.width;
        return bytes[offset + (x ~/ 2) * 2 + 1];
      },
      vAt: (x, y) {
        final offset = frame.width * frame.height + (y ~/ 2) * frame.width;
        return bytes[offset + (x ~/ 2) * 2];
      },
    );
  }

  static img.Image _decodeYuv420(CameraImage frame) {
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    return _decodeYuv(
      width: frame.width,
      height: frame.height,
      yAt: (x, y) => yPlane.bytes[y * yPlane.bytesPerRow + x],
      uAt: (x, y) =>
          uPlane.bytes[(y ~/ 2) * uPlane.bytesPerRow +
              (x ~/ 2) * uvPixelStride],
      vAt: (x, y) =>
          vPlane.bytes[(y ~/ 2) * vPlane.bytesPerRow +
              (x ~/ 2) * uvPixelStride],
    );
  }

  static img.Image _decodeYuv({
    required int width,
    required int height,
    required int Function(int x, int y) yAt,
    required int Function(int x, int y) uAt,
    required int Function(int x, int y) vAt,
  }) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final luma = yAt(x, y).toDouble();
        final u = uAt(x, y) - 128.0;
        final v = vAt(x, y) - 128.0;
        image.setPixelRgb(
          x,
          y,
          (luma + 1.402 * v).round().clamp(0, 255),
          (luma - 0.344136 * u - 0.714136 * v).round().clamp(0, 255),
          (luma + 1.772 * u).round().clamp(0, 255),
        );
      }
    }
    return image;
  }
}
