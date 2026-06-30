// /// Example usage of FaceDetectionService with WebSocket
// ///
// /// This file demonstrates how to integrate the face detection service
// /// with camera streaming and WebSocket communication.
//
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'face_detection_service.dart';
//
// class FaceDetectionExample extends StatefulWidget {
//   const FaceDetectionExample({Key? key}) : super(key: key);
//
//   @override
//   State<FaceDetectionExample> createState() => _FaceDetectionExampleState();
// }
//
// class _FaceDetectionExampleState extends State<FaceDetectionExample> {
//   CameraController? _cameraController;
//   FaceDetectionService? _faceDetectionService;
//   bool _isProcessing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }
//
//   Future<void> _initializeServices() async {
//     // Initialize camera
//     final cameras = await availableCameras();
//     final frontCamera = cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.front,
//       orElse: () => cameras.first,
//     );
//
//     _cameraController = CameraController(
//       frontCamera,
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.nv21, // Important for Android
//     );
//
//     await _cameraController!.initialize();
//
//     // Initialize face detection service
//     _faceDetectionService = FaceDetectionService();
//     await _faceDetectionService!.connect();
//
//     // Listen to local detection stream
//     _faceDetectionService!.detectionStream.listen((result) {
//       print('Local detection: ${result['faces_detected']} faces');
//     });
//
//     // Listen to server validation stream
//     _faceDetectionService!.validationStream.listen((result) {
//       print('Server validation: $result');
//       // Handle validation response from server
//       // e.g., update UI, track attention score, etc.
//     });
//
//     // Start camera streaming
//     _cameraController!.startImageStream(_processCameraImage);
//
//     setState(() {});
//   }
//
//   void _processCameraImage(CameraImage image) async {
//     if (_isProcessing) return;
//     _isProcessing = true;
//
//     try {
//       // Process frame: detect faces locally and send to server
//       await _faceDetectionService?.processCameraFrame(
//         image: image,
//         isAssessment: true,
//         autoSendToServer: true,
//       );
//     } catch (e) {
//       print('Error processing frame: $e');
//     } finally {
//       _isProcessing = false;
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.stopImageStream();
//     _cameraController?.dispose();
//     _faceDetectionService?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Face Detection Example')),
//       body: CameraPreview(_cameraController!),
//     );
//   }
// }
//
// // ============================================================================
// // ALTERNATIVE USAGE: Manual control
// // ============================================================================
//
// class ManualFaceDetectionExample {
//   final FaceDetectionService service = FaceDetectionService();
//
//   Future<void> example() async {
//     // 1. Connect to WebSocket
//     await service.connect();
//
//     // 2. Listen to streams
//     service.detectionStream.listen((detection) {
//       print('Local: ${detection['faces_detected']} faces detected');
//     });
//
//     service.validationStream.listen((validation) {
//       print('Server validation result: $validation');
//     });
//
//     // 3. Process camera frames (called from camera stream)
//     // This is automatically handled when you call processCameraFrame
//
//     // 4. Disconnect when done
//     await service.disconnect();
//   }
// }
//
// // ============================================================================
// // WEBSOCKET COMMUNICATION FORMAT
// // ============================================================================
//
// /// SENT TO SERVER:
// /// {
// ///   "type": "validate_face",
// ///   "frame_base64": "<base64_encoded_image>",
// ///   "face": {
// ///     "x": 123,
// ///     "y": 100,
// ///     "width": 200,
// ///     "height": 280
// ///   },
// ///   "frame": {
// ///     "width": 640,
// ///     "height": 480
// ///   },
// ///   "is_assessment": true
// /// }
//
// /// RECEIVED FROM SERVER:
// /// {
// ///   "type": "validation_result",
// ///   "valid": true,
// ///   "attention_score": 95,
// ///   "message": "Face validated successfully",
// ///   ... additional fields
// /// }