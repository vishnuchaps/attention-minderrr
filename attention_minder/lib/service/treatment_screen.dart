// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'dart:async';
// import 'dart:typed_data';
//
// class VideoTherapyScreen extends StatefulWidget {
//   const VideoTherapyScreen({Key? key}) : super(key: key);
//
//   @override
//   State<VideoTherapyScreen> createState() => _VideoTherapyScreenState();
// }
//
// class _VideoTherapyScreenState extends State<VideoTherapyScreen> {
//   // Camera variables
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;
//
//   // Video player variables
//   VideoPlayerController? _videoPlayerController;
//   ChewieController? _chewieController;
//
//   // Face detection variables
//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableContours: true,
//       enableLandmarks: true,
//       enableClassification: true,
//       enableTracking: true,
//       minFaceSize: 0.1,
//       performanceMode: FaceDetectorMode.fast,
//     ),
//   );
//
//   bool _isFaceDetected = true;
//   Timer? _faceDetectionTimer;
//   Timer? _noFaceTimer;
//   bool _showFocusAlert = false;
//   DateTime? _lastFaceDetectedTime;
//
//   // Therapy session variables
//   int _sessionDuration = 0;
//   int _focusScore = 100;
//   int _alertCount = 0;
//   Timer? _sessionTimer;
//
//   // Sample video URLs (replace with your therapy video URLs)
//   final List<String> _therapyVideos = [
//     'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
//     'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
//     // Add your actual therapy video URLs here
//   ];
//
//   int _currentVideoIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _initializeVideoPlayer();
//     _startSession();
//   }
//
//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     if (_cameras!.isNotEmpty) {
//       // Use front camera for face detection
//       final frontCamera = _cameras!.firstWhere(
//             (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => _cameras!.first,
//       );
//
//       _cameraController = CameraController(
//         frontCamera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );
//
//       await _cameraController!.initialize();
//
//       setState(() {
//         _isCameraInitialized = true;
//       });
//
//       _startFaceDetection();
//     }
//   }
//
//   Future<void> _initializeVideoPlayer() async {
//     _videoPlayerController = VideoPlayerController.networkUrl(
//       Uri.parse(_therapyVideos[_currentVideoIndex]),
//     );
//
//     await _videoPlayerController!.initialize();
//
//     _chewieController = ChewieController(
//       videoPlayerController: _videoPlayerController!,
//       autoPlay: true,
//       looping: false,
//       showControls: true,
//       allowFullScreen: false,
//       allowMuting: false,
//       aspectRatio: 16 / 9,
//     );
//
//     // Listen for video completion
//     _videoPlayerController!.addListener(() {
//       if (_videoPlayerController!.value.position >=
//           _videoPlayerController!.value.duration) {
//         _onVideoCompleted();
//       }
//     });
//
//     setState(() {});
//   }
//
//   void _startSession() {
//     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _sessionDuration++;
//       });
//     });
//   }
//
//   void _startFaceDetection() {
//     _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
//       if (_cameraController != null && _cameraController!.value.isInitialized) {
//         _detectFaces();
//       }
//     });
//   }
//
//   Future<void> _detectFaces() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }
//
//     try {
//       final image = await _cameraController!.takePicture();
//       final inputImage = InputImage.fromFilePath(image.path);
//       final faces = await _faceDetector.processImage(inputImage);
//
//       final bool faceDetected = faces.isNotEmpty;
//
//       if (faceDetected) {
//         _lastFaceDetectedTime = DateTime.now();
//         if (!_isFaceDetected) {
//           setState(() {
//             _isFaceDetected = true;
//             _showFocusAlert = false;
//           });
//           _resumeVideo();
//         }
//         _noFaceTimer?.cancel();
//       } else {
//         if (_isFaceDetected) {
//           _noFaceTimer = Timer(const Duration(seconds: 2), () {
//             setState(() {
//               _isFaceDetected = false;
//               _showFocusAlert = true;
//               _focusScore = (_focusScore - 5).clamp(0, 100);
//               _alertCount++;
//             });
//             _pauseVideo();
//           });
//         }
//       }
//     } catch (e) {
//       print('Face detection error: $e');
//     }
//   }
//
//   void _pauseVideo() {
//     _videoPlayerController?.pause();
//   }
//
//   void _resumeVideo() {
//     _videoPlayerController?.play();
//   }
//
//   void _onVideoCompleted() {
//     if (_currentVideoIndex < _therapyVideos.length - 1) {
//       _loadNextVideo();
//     } else {
//       _showSessionComplete();
//     }
//   }
//
//   Future<void> _loadNextVideo() async {
//     _currentVideoIndex++;
//     await _videoPlayerController?.dispose();
//     // await _chewieController?.dispose();
//
//     await _initializeVideoPlayer();
//   }
//
//   void _showSessionComplete() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Session Complete!'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Duration: ${_formatDuration(_sessionDuration)}'),
//             Text('Focus Score: $_focusScore%'),
//             Text('Attention Alerts: $_alertCount'),
//             const SizedBox(height: 10),
//             Text(
//               _focusScore >= 80
//                   ? 'Excellent focus! Keep up the good work!'
//                   : _focusScore >= 60
//                   ? 'Good effort! Try to maintain focus longer.'
//                   : 'Practice makes perfect! Keep trying.',
//               style: TextStyle(
//                 color: _focusScore >= 80
//                     ? Colors.green
//                     : _focusScore >= 60
//                     ? Colors.orange
//                     : Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).pop();
//             },
//             child: const Text('Finish'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(int seconds) {
//     int minutes = seconds ~/ 60;
//     int remainingSeconds = seconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }
//
//   @override
//   void dispose() {
//     _faceDetectionTimer?.cancel();
//     _noFaceTimer?.cancel();
//     _sessionTimer?.cancel();
//     _cameraController?.dispose();
//     _videoPlayerController?.dispose();
//     _chewieController?.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Therapy Session'),
//         backgroundColor: Colors.blue.shade100,
//         actions: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             margin: const EdgeInsets.only(right: 8),
//             decoration: BoxDecoration(
//               color: _isFaceDetected ? Colors.green : Colors.red,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   _isFaceDetected ? Icons.visibility : Icons.visibility_off,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   _isFaceDetected ? 'Focused' : 'Not Focused',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // Session info bar
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 color: Colors.blue.shade50,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildInfoItem('Time', _formatDuration(_sessionDuration)),
//                     _buildInfoItem('Focus', '$_focusScore%'),
//                     _buildInfoItem('Alerts', '$_alertCount'),
//                   ],
//                 ),
//               ),
//
//               // Video player
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   color: Colors.black,
//                   child: _chewieController != null
//                       ? Chewie(controller: _chewieController!)
//                       : const Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 ),
//               ),
//
//               // Camera preview (small)
//               Expanded(
//                 flex: 1,
//                 child: Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: _isFaceDetected ? Colors.green : Colors.red,
//                       width: 3,
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: _isCameraInitialized
//                         ? CameraPreview(_cameraController!)
//                         : const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // Focus alert overlay
//           if (_showFocusAlert)
//             Container(
//               color: Colors.black54,
//               child: Center(
//                 child: Container(
//                   margin: const EdgeInsets.all(20),
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.warning,
//                         color: Colors.orange,
//                         size: 50,
//                       ),
//                       const SizedBox(height: 15),
//                       const Text(
//                         'Please Focus on the Screen',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.orange,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 10),
//                       const Text(
//                         'Look at the camera to continue your therapy session',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() {
//                             _showFocusAlert = false;
//                           });
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                         ),
//                         child: const Text('I\'m Ready'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoItem(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }
// }