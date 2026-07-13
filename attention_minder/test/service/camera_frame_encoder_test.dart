import 'package:attention_minder/service/camera_frame_encoder.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frontCamera = CameraDescription(
    name: 'front',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 90,
  );
  const rearCamera = CameraDescription(
    name: 'rear',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  group('CameraFrameEncoder rotation', () {
    test('uses sensor orientation on iOS', () {
      expect(
        CameraFrameEncoder.rotationForCamera(
          camera: frontCamera,
          deviceOrientation: DeviceOrientation.landscapeRight,
          isIOS: true,
        ),
        90,
      );
    });

    test('adds device compensation for an Android front camera', () {
      expect(
        CameraFrameEncoder.rotationForCamera(
          camera: frontCamera,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          isIOS: false,
        ),
        180,
      );
    });

    test('subtracts device compensation for an Android rear camera', () {
      expect(
        CameraFrameEncoder.rotationForCamera(
          camera: rearCamera,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          isIOS: false,
        ),
        0,
      );
    });
  });
}
