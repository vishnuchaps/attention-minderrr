import 'dart:async';
import 'dart:convert';
import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/service/notification_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoTreatmentScreen extends StatefulWidget {
  final int day;
  final List<VideoFile> videos;
  final bool isAssessment;

  const VideoTreatmentScreen({
    super.key,
    required this.day,
    required this.videos,
    this.isAssessment = false,
  });

  @override
  State<VideoTreatmentScreen> createState() => _VideoTreatmentScreenState();
}

class _VideoTreatmentScreenState extends State<VideoTreatmentScreen> {
  VideoPlayerController? _videoController;
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  NotificationService? _notificationService;
  late FaceDetector _faceDetector;
  int _currentVideoIndex = 0;
  bool _isVideoInitialized = false;
  bool _isCameraInitialized = false;
  bool _isAIMonitoringActive = false;
  bool _attentionDetected = true;
  bool _isSendingFrame = false;
  Timer? _frameTimer;
  Timer? _sessionTimer;

  // Session tracking
  int _sessionDuration = 0;
  int _attentionScore = 100;
  int _pauseCount = 0;
  int _totalAlerts = 0;
  double _totalInattentionDuration = 0;
  List<int> _concentrationScores = [];
  String _lastFeedback = '';
  List<String> _lastRecommendations = [];
  bool _isShowingAlert = false;

  // Message history for session summary
  List<Map<String, dynamic>> _validationHistory = [];
  DateTime? _lastAlertTime;
  int _consecutiveGoodFrames = 0;
  int _consecutiveBadFrames = 0;
  static const int _badFrameThreshold = 5;
  bool _wasInAlert = false;

  // Latest validation state
  Map<String, dynamic>? _latestValidationResult;
  String? _latestSentFrameId;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );

    _initializeNotificationService();
    _initializeVideo();
    _initializeCamera();
    _startSessionTimer();
  }

  Future<void> _initializeNotificationService() async {
    _notificationService = NotificationService();
    await _notificationService!.initialize();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isAIMonitoringActive && !_isShowingAlert) {
        setState(() {
          _sessionDuration++;
        });
      }
    });
  }

  Future<void> _initializeVideo() async {
    if (widget.videos.isEmpty) return;

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videos[_currentVideoIndex].url),
      );

      await _videoController!.initialize();

      setState(() {
        _isVideoInitialized = true;
      });

      _videoController!.play();

      _videoController!.addListener(() {
        if (_videoController!.value.position ==
            _videoController!.value.duration) {
          _onVideoComplete();
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      _showError('Failed to load video');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) {
        await _cameraController?.dispose();
        return;
      }

      setState(() {
        _isCameraInitialized = true;
      });

      _startAIMonitoring();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startAIMonitoring() async {
    if (!_isCameraInitialized) {
      _showError('Camera not initialized');
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      String? accessToken = prefs.getString('accessToken');
      final uri = Uri.parse(
        wsFaceDetectionUrl,
      ).replace(queryParameters: {'token': accessToken});

      print("Vishnu Connecting to WebSocket...");
      _channel = WebSocketChannel.connect(uri);
      print("Vishnu WebSocket connected to $wsFaceDetectionUrl");

      _channel!.stream.listen(
        (message) {
          print("Vishnu Received from socket:");
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _showError('Connection lost. Retrying...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _isAIMonitoringActive) {
              _startAIMonitoring();
            }
          });
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );

      _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _sendCameraFrame();
      });

      setState(() {
        _isAIMonitoringActive = true;
      });

      _videoController?.play();
    } catch (e) {
      print('Error starting AI monitoring: $e');
      _showError('Failed to start AI monitoring');
    }
  }

  void printLongLog(String title, String text) {
    const int chunkSize = 800;
    print('========== $title START ==========');

    for (int i = 0; i < text.length; i += chunkSize) {
      print(
        text.substring(
          i,
          i + chunkSize > text.length ? text.length : i + chunkSize,
        ),
      );
    }

    print('========== $title END ==========');
  }

  Future<void> _sendCameraFrame() async {
    if (_isSendingFrame) return;

    _isSendingFrame = true;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      final image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final decodedImage = await decodeImageFromList(bytes);
      final frameWidth = decodedImage.width;
      final frameHeight = decodedImage.height;
      final frameId =
          'frame-${DateTime.now().millisecondsSinceEpoch}-${_validationHistory.length + 1}';
      final timestampSeconds =
          (_videoController?.value.position.inMilliseconds ?? 0) / 1000;
      _latestSentFrameId = frameId;

      if (faces.isEmpty) {
        final message = {
          'type': 'validate_face',
          'frame_base64': base64Image,
          'frame_id': frameId,
          'face': {
            'x': 0,
            'y': 0,
            'width': 0,
            'height': 0,
            'confidence': null,
            'timestamp_seconds': timestampSeconds,
            'frame_id': frameId,
          },
          'frame': {'width': frameWidth, 'height': frameHeight},
          'left_eye_open_probability': null,
          'right_eye_open_probability': null,
          'is_assessment': widget.isAssessment,
        };

        print('NO FACE REQUEST SENT');
        print(
          const JsonEncoder.withIndent('  ').convert({
            ...message,
            'frame_base64': 'base64 length: ${base64Image.length}',
          }),
        );

        _channel?.sink.add(jsonEncode(message));
        return;
      }
      final face = faces.first;
      final Rect box = face.boundingBox;
      final faceX = box.left.round();
      final faceY = box.top.round();
      final faceWidth = box.width.round();
      final faceHeight = box.height.round();

      final message = {
        'type': 'validate_face',
        'frame_base64': base64Image,
        'frame_id': frameId,
        'face': {
          'x': faceX,
          'y': faceY,
          'width': faceWidth,
          'height': faceHeight,
          'confidence': null,
          'timestamp_seconds': timestampSeconds,
          'frame_id': frameId,
        },
        'frame': {'width': frameWidth, 'height': frameHeight},
        'left_eye_open_probability': face.leftEyeOpenProbability,
        'right_eye_open_probability': face.rightEyeOpenProbability,
        'is_assessment': widget.isAssessment,
      };

      print('''
========== FRAME CONFIRMATION ==========
Captured image path     : ${image.path}

Frame size sent         : ${frameWidth} x $frameHeight
frame_id                : $frameId

ML Kit face box:
x                       : $faceX
y                       : $faceY
width                   : $faceWidth
height                  : $faceHeight

left_eye_open_probability  : ${face.leftEyeOpenProbability}
right_eye_open_probability : ${face.rightEyeOpenProbability}

is_assessment           : ${widget.isAssessment}

Same frame confirmation : YES
Reason                  : ML Kit face detection and base64 are both created from same image.path
========================================
''');

      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending frame: $e');
    } finally {
      _isSendingFrame = false;
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      print(
        "Vishnu Inside _handleWebSocketMessage ${encoder.convert(message)}",
      );

      final data = jsonDecode(message);

      printLongLog(
        'FULL BACKEND RESPONSE',
        const JsonEncoder.withIndent('  ').convert(data),
      );

      if (data['type'] == 'connection_established' || data['type'] == 'error') {
        print('WebSocket status: ${data['message']}');
        return;
      }

      if (data['type'] == 'validation_result' && data['result'] != null) {
        final result = data['result'] as Map<String, dynamic>;
        final engagement = result['engagement'] as Map<String, dynamic>?;
        final analysis = result['analysis'] as Map<String, dynamic>?;
        final metrics = result['metrics'] as Map<String, dynamic>?;
        final facePosition = result['face_position'];
        final responseFrameId =
            data['frame_id']?.toString() ?? result['frame_id']?.toString();
        final bool isSameFrameResponse =
            responseFrameId != null &&
            _latestSentFrameId != null &&
            responseFrameId == _latestSentFrameId;

        printLongLog(
          'RESULT ENGAGEMENT',
          const JsonEncoder.withIndent('  ').convert(engagement),
        );

        printLongLog(
          'RESULT ANALYSIS',
          const JsonEncoder.withIndent('  ').convert(analysis),
        );

        printLongLog(
          'RESULT METRICS',
          const JsonEncoder.withIndent('  ').convert(metrics),
        );

        printLongLog(
          'FACE POSITION',
          const JsonEncoder.withIndent('  ').convert(facePosition),
        );

        print('''
========== FRAME ID CHECK ==========
latest_sent_frame_id    : $_latestSentFrameId
backend_response_frame_id: $responseFrameId
same_frame_response     : ${isSameFrameResponse ? 'YES' : 'NO / NOT PROVIDED'}
====================================
''');

        final facePos = result['face_position'] as Map<String, dynamic>?;

        print('''
raw_concentration_score : ${metrics?['raw_concentration_score']}
concentration_score     : ${result['concentration_score']}
gaze_ratio              : ${metrics?['gaze_ratio']}
pitch                   : ${metrics?['pitch']}
yaw                     : ${metrics?['yaw']}
roll                    : ${metrics?['roll']}
drowsy_state            : ${!((result['analysis']?['not_drowsy']) ?? true)}
eyes_closed             : ${analysis?['eyes_closed']}
eye_decision_reason     : ${analysis?['eye_decision_reason'] ?? metrics?['eye_decision_reason'] ?? result['eye_decision_reason']}
left_eye_open_probability  : ${metrics?['left_eye_open_probability'] ?? analysis?['left_eye_open_probability'] ?? result['left_eye_open_probability']}
right_eye_open_probability : ${metrics?['right_eye_open_probability'] ?? analysis?['right_eye_open_probability'] ?? result['right_eye_open_probability']}
blink_ratio             : ${metrics?['blink_ratio']}
eye_aspect_ratio        : ${metrics?['eye_aspect_ratio'] ?? analysis?['eye_aspect_ratio'] ?? result['eye_aspect_ratio']}

faces_count             : ${metrics?['faces_count']}
face_area_ratio         : ${metrics?['face_area_ratio']}
center_deviation_x      : ${metrics?['center_deviation_x']}
center_deviation_y      : ${metrics?['center_deviation_y']}

frame_width             : ${facePos?['frame_width']}
frame_height            : ${facePos?['frame_height']}

face_x                  : ${facePos?['client_x']}
face_y                  : ${facePos?['client_y']}
face_width              : ${facePos?['client_width']}
face_height             : ${facePos?['client_height']}
''');

        print(
          "for testing purpose ${const JsonEncoder.withIndent('  ').convert(data)}",
        );

        _validationHistory.add({
          'timestamp': DateTime.now().toIso8601String(),
          'result': result,
        });

        _latestValidationResult = result;

        final bool faceDetected = result['face_detected'] == true;
        final bool validationPassed = result['validation_passed'] == true;
        final int concentrationScore = result['concentration_score'] ?? 0;
        final String message = result['message'] ?? '';
        final bool lowLight = analysis?['low_light'] == true;
        final bool notDrowsy = analysis?['not_drowsy'] != false;
        final bool yawning = analysis?['yawning'] == true;
        final bool eyesClosed = analysis?['eyes_closed'] == true;

        final bool videoAttentive = engagement?['video_attentive'] == true;
        final String engagementState = engagement?['state'] ?? '';
        final double inattentionDuration =
            (engagement?['inattention_duration'] ?? 0).toDouble();

        final feedback = result['feedback'] as Map<String, dynamic>?;
        final bool actionRequired = feedback?['action_required'] == true;
        final String alertLevel = feedback?['alert_level'] ?? 'low';

        final List<String> recommendations =
            (result['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        const lowLightRecommendation =
            'Lighting is too low. Move to a brighter area or turn on a light.';

        if (lowLight && !recommendations.contains(lowLightRecommendation)) {
          recommendations.add(lowLightRecommendation);
        }

        final bool isAttentionGood = widget.isAssessment
            ? faceDetected && !lowLight && notDrowsy && !yawning && !eyesClosed
            : faceDetected &&
                  validationPassed &&
                  videoAttentive &&
                  !actionRequired &&
                  !lowLight &&
                  notDrowsy &&
                  !yawning &&
                  !eyesClosed &&
                  concentrationScore >= 7 &&
                  engagementState == 'watching_video';

        if (isAttentionGood && !_isShowingAlert) {
          _consecutiveGoodFrames++;
          _consecutiveBadFrames = 0;

          if (_consecutiveGoodFrames >= 3 && _wasInAlert) {
            setState(() {
              _wasInAlert = false;
              _attentionDetected = true;
            });
          }
        } else {
          _consecutiveGoodFrames = 0;

          if (!_isShowingAlert) {
            _consecutiveBadFrames++;
          }
        }

        setState(() {
          _attentionDetected = isAttentionGood;
          _lastFeedback = message;
          _lastRecommendations = recommendations;

          if (concentrationScore >= 0) {
            _concentrationScores.add(concentrationScore);
            final avgScore =
                _concentrationScores.reduce((a, b) => a + b) /
                _concentrationScores.length;
            _attentionScore = (avgScore * 10).round().clamp(0, 100);
          }

          if (inattentionDuration > 0) {
            _totalInattentionDuration = inattentionDuration;
          }
        });

        if (_isShowingAlert) return;
        if (isAttentionGood) return;

        if (_consecutiveBadFrames < _badFrameThreshold) {
          print(
            'Bad frame ignored. Count: $_consecutiveBadFrames / $_badFrameThreshold',
          );
          return;
        }

        final now = DateTime.now();

        if (_lastAlertTime != null &&
            now.difference(_lastAlertTime!).inSeconds < 5) {
          return;
        }

        bool shouldPause = false;
        String alertMessage = '';
        List<String> alertRecommendations = recommendations;

        if (lowLight) {
          shouldPause = true;
          alertMessage = lowLightRecommendation;
          if (widget.isAssessment) {
            alertRecommendations = [lowLightRecommendation];
          }
        } else if (!faceDetected) {
          shouldPause = true;
          alertMessage =
              'Face not detected! Please position your face in front of the camera.';
          if (widget.isAssessment) {
            alertRecommendations = [
              'Position your face clearly in front of the camera.',
            ];
          }
        } else if (eyesClosed) {
          shouldPause = true;
          alertMessage =
              'Eyes closed detected. Please open your eyes and focus on the video.';
        } else if (yawning) {
          shouldPause = true;
          alertMessage =
              'Yawning detected. Please take a short break and refocus.';
        } else if (!notDrowsy) {
          shouldPause = true;
          alertMessage =
              'You appear drowsy. Please take a short break and refocus.';
        } else if (!widget.isAssessment && !validationPassed) {
          shouldPause = true;
          alertMessage =
              'Please adjust your position. ${recommendations.isNotEmpty ? recommendations.first : ''}';
        } else if (!widget.isAssessment && !videoAttentive) {
          shouldPause = true;
          alertMessage = 'You seem distracted. Please focus on the video.';
        } else if (!widget.isAssessment && actionRequired) {
          shouldPause = true;
          alertMessage = message.isNotEmpty
              ? message
              : 'Please refocus on the treatment.';
        } else if (!widget.isAssessment && concentrationScore < 7) {
          shouldPause = true;
          alertMessage =
              'Low concentration detected. Take a moment to refocus.';
        } else if (!widget.isAssessment &&
            (engagementState.contains('distracted') ||
                engagementState == 'idle_distracted')) {
          shouldPause = true;
          alertMessage = 'Please pay attention to the video treatment.';
        }

        if (shouldPause && _videoController?.value.isPlaying == true) {
          _videoController?.pause();
          _pauseCount++;
          _totalAlerts++;
          _lastAlertTime = now;
          _wasInAlert = true;
          _showAttentionAlert(alertMessage, alertRecommendations);
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
      print('Message content: $message');
    }
  }

  bool _verifyUserReady() {
    if (_latestValidationResult == null) return false;

    final result = _latestValidationResult!;
    final bool faceDetected = result['face_detected'] == true;
    final bool validationPassed = result['validation_passed'] == true;
    final int concentrationScore = result['concentration_score'] ?? 0;
    final analysis = result['analysis'] as Map<String, dynamic>?;
    final bool lowLight = analysis?['low_light'] == true;
    final bool notDrowsy = analysis?['not_drowsy'] != false;
    final bool yawning = analysis?['yawning'] == true;
    final bool eyesClosed = analysis?['eyes_closed'] == true;

    if (widget.isAssessment) {
      return faceDetected && !lowLight && notDrowsy && !yawning && !eyesClosed;
    }

    final engagement = result['engagement'] as Map<String, dynamic>?;
    final bool videoAttentive = engagement?['video_attentive'] == true;
    final String engagementState = engagement?['state'] ?? '';

    final bool isReady =
        faceDetected &&
        validationPassed &&
        !lowLight &&
        notDrowsy &&
        !yawning &&
        !eyesClosed &&
        concentrationScore >= 7 &&
        videoAttentive &&
        engagementState == 'watching_video';

    return isReady;
  }

  void _showAttentionAlert(String message, List<String> recommendations) async {
    if (_isShowingAlert) return;

    setState(() {
      _isShowingAlert = true;
    });

    await _notificationService?.playAttentionAlert(
      customMessage: message,
      playSound: true,
      speakMessage: true,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _isShowingAlert) {
              setDialogState(() {});
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.grey.shade900,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF5350),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Attention Alert',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Current Focus Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_attentionScore%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _attentionScore > 70
                                ? const Color(0xFF66BB6A)
                                : _attentionScore > 40
                                ? const Color(0xFFFFA726)
                                : const Color(0xFFEF5350),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF7C14A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Color(0xFFF7C14A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade300,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _verifyUserReady()
                          ? const Color(0xFF66BB6A).withOpacity(0.1)
                          : const Color(0xFFEF5350).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _verifyUserReady()
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFEF5350),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _verifyUserReady() ? Icons.check_circle : Icons.error,
                          color: _verifyUserReady()
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFFEF5350),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _verifyUserReady()
                                ? 'Ready to resume - Face detected and focused!'
                                : 'Not ready yet - Please adjust your position',
                            style: TextStyle(
                              fontSize: 13,
                              color: _verifyUserReady()
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFFEF5350),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Alerts', _totalAlerts.toString()),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade700,
                        ),
                        _buildStatItem('Pauses', _pauseCount.toString()),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade700,
                        ),
                        _buildStatItem(
                          'Time',
                          _formatDuration(_sessionDuration),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_verifyUserReady()) {
                      setState(() {
                        _isShowingAlert = false;
                        _consecutiveGoodFrames = 0;
                        _consecutiveBadFrames = 0;
                      });
                      Navigator.pop(context);
                      _videoController?.play();
                    } else {
                      final latestResult = _latestValidationResult;
                      String feedbackMessage = 'Please ensure:';
                      List<String> issues = [];

                      if (latestResult != null) {
                        if (!(latestResult['face_detected'] ?? false)) {
                          issues.add('✗ Your face is visible in the camera');
                        }

                        final analysis =
                            latestResult['analysis'] as Map<String, dynamic>?;

                        if (analysis?['low_light'] == true) {
                          issues.add(
                            '✗ Lighting is bright enough for clear face detection',
                          );
                        }

                        if (analysis?['not_drowsy'] == false) {
                          issues.add('✗ You are not drowsy');
                        }

                        if (analysis?['yawning'] == true) {
                          issues.add('✗ You are not yawning');
                        }

                        if (analysis?['eyes_closed'] == true) {
                          issues.add('✗ Your eyes are open');
                        }

                        if (!widget.isAssessment) {
                          if (!(latestResult['validation_passed'] ?? false)) {
                            issues.add('✗ You are properly positioned');
                          }

                          final concentrationScore =
                              latestResult['concentration_score'] ?? 0;

                          if (concentrationScore < 7) {
                            issues.add(
                              '✗ Your concentration level is adequate (currently: $concentrationScore/10)',
                            );
                          }

                          final engagement =
                              latestResult['engagement']
                                  as Map<String, dynamic>?;

                          if (engagement != null &&
                              !(engagement['video_attentive'] ?? false)) {
                            issues.add('✗ You are looking at the screen');
                          }
                        }
                      }

                      if (issues.isEmpty) {
                        issues.add('Please wait a moment and try again');
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feedbackMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...issues.map(
                                (issue) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    issue,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFFEF5350),
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      await _notificationService?.playAttentionAlert(
                        customMessage:
                            'Not ready yet. ${issues.first.replaceAll('✗ ', '')}',
                        playSound: false,
                        speakMessage: true,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I\'m Ready - Resume Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF7C14A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onVideoComplete() {
    if (_currentVideoIndex < widget.videos.length - 1) {
      setState(() {
        _currentVideoIndex++;
      });
      _videoController?.dispose();
      _initializeVideo();
    } else {
      _showCompletionDialog();
    }
  }

  Map<String, dynamic> _analyzeSessionHistory() {
    if (_validationHistory.isEmpty) {
      return {
        'totalFrames': 0,
        'faceDetectedCount': 0,
        'faceDetectedPercentage': 0.0,
        'avgConcentration': 0.0,
        'totalInattentionTime': 0.0,
        'attentionPercentage': 0.0,
        'mostCommonIssues': <String>[],
        'drowsyFrames': 0,
        'distractedFrames': 0,
      };
    }

    int totalFrames = _validationHistory.length;
    int faceDetectedCount = 0;
    int validationPassedCount = 0;
    int videoAttentiveCount = 0;
    int drowsyFrames = 0;
    int distractedFrames = 0;
    double totalConcentration = 0;
    double maxInattention = 0;
    Map<String, int> issueCounter = {};

    for (var entry in _validationHistory) {
      final result = entry['result'] as Map<String, dynamic>;

      if (result['face_detected'] == true) faceDetectedCount++;
      if (result['validation_passed'] == true) validationPassedCount++;

      final concentration = result['concentration_score'] ?? 0;
      totalConcentration += concentration;

      final engagement = result['engagement'] as Map<String, dynamic>?;
      if (engagement != null) {
        if (engagement['video_attentive'] == true) videoAttentiveCount++;
        final state = engagement['state'] ?? '';
        if (state.contains('distracted')) distractedFrames++;

        final inattention = (engagement['inattention_duration'] ?? 0)
            .toDouble();
        if (inattention > maxInattention) maxInattention = inattention;
      }

      final analysis = result['analysis'] as Map<String, dynamic>?;
      if (analysis != null && analysis['not_drowsy'] == false) {
        drowsyFrames++;
      }

      final recommendations = result['recommendations'] as List<dynamic>?;
      if (recommendations != null) {
        for (var rec in recommendations) {
          final recStr = rec.toString();
          issueCounter[recStr] = (issueCounter[recStr] ?? 0) + 1;
        }
      }
    }

    final sortedIssues = issueCounter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostCommonIssues = sortedIssues.take(3).map((e) => e.key).toList();

    return {
      'totalFrames': totalFrames,
      'faceDetectedCount': faceDetectedCount,
      'faceDetectedPercentage': (faceDetectedCount / totalFrames) * 100,
      'validationPassedPercentage': (validationPassedCount / totalFrames) * 100,
      'avgConcentration': totalConcentration / totalFrames,
      'totalInattentionTime': maxInattention,
      'attentionPercentage': (videoAttentiveCount / totalFrames) * 100,
      'mostCommonIssues': mostCommonIssues,
      'drowsyFrames': drowsyFrames,
      'distractedFrames': distractedFrames,
      'drowsyPercentage': (drowsyFrames / totalFrames) * 100,
      'distractedPercentage': (distractedFrames / totalFrames) * 100,
    };
  }

  void _showCompletionDialog() async {
    final sessionAnalysis = _analyzeSessionHistory();

    await _notificationService?.playSessionComplete();
    await _notificationService?.playEncouragement(_attentionScore);

    if (widget.isAssessment) {
      if (!mounted) return;
      _showAssessmentCompletionDialog();
      return;
    }

    final double attentionPercentage =
        sessionAnalysis['attentionPercentage'] ?? 0.0;
    final double avgConcentration = sessionAnalysis['avgConcentration'] ?? 0.0;
    final double faceDetectedPercentage =
        sessionAnalysis['faceDetectedPercentage'] ?? 0.0;

    final int finalScore =
        ((attentionPercentage +
                    (avgConcentration * 10) +
                    faceDetectedPercentage) /
                3)
            .round();

    final int displayScore = finalScore > 0 ? finalScore : _attentionScore;

    final int pointsEarned = 200 + (displayScore ~/ 10) * 10;

    final String performanceLevel = displayScore >= 90
        ? 'Excellent'
        : displayScore >= 70
        ? 'Good'
        : displayScore >= 50
        ? 'Fair'
        : 'Needs Improvement';

    final Color performanceColor = displayScore >= 90
        ? const Color(0xFF66BB6A)
        : displayScore >= 70
        ? const Color(0xFF42A5F5)
        : displayScore >= 50
        ? const Color(0xFFFFA726)
        : const Color(0xFFEF5350);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFF7C14A),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF66BB6A).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Great job completing Day ${widget.day} treatment session!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      performanceLevel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: performanceColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: displayScore / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              performanceColor,
                            ),
                          ),
                          Text(
                            '$displayScore%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSessionStat(
                      'Videos Watched',
                      '${widget.videos.length}',
                      Icons.play_circle_outline,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Session Duration',
                      _formatDuration(_sessionDuration),
                      Icons.timer_outlined,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Focus Alerts',
                      '$_totalAlerts',
                      Icons.warning_amber_outlined,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Pause Count',
                      '$_pauseCount',
                      Icons.pause_circle_outlined,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Avg Concentration',
                      '${avgConcentration.toStringAsFixed(1)}/10',
                      Icons.psychology_outlined,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Face Detection',
                      '${faceDetectedPercentage.toStringAsFixed(0)}%',
                      Icons.face_outlined,
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    _buildSessionStat(
                      'Attention Rate',
                      '${attentionPercentage.toStringAsFixed(0)}%',
                      Icons.visibility_outlined,
                    ),
                    if (sessionAnalysis['totalInattentionTime'] > 0) ...[
                      const Divider(height: 20, color: Colors.grey),
                      _buildSessionStat(
                        'Max Inattention',
                        '${sessionAnalysis['totalInattentionTime'].toStringAsFixed(1)}s',
                        Icons.timer_off_outlined,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if ((sessionAnalysis['mostCommonIssues'] as List).isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFFFA726),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Areas for Improvement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(sessionAnalysis['mostCommonIssues'] as List).map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_right,
                                color: Color(0xFFFFA726),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  issue.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade300,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7C14A), Color(0xFFFFD54F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars, color: Colors.black, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Points Earned',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pointsEarned',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssessmentCompletionDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _AssessmentCompletionView(
          onDone: () {
            final navigator = Navigator.of(dialogContext);
            navigator.pop();
            navigator.pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  Widget _buildSessionStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF7C14A), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    _videoController?.dispose();
    _cameraController?.dispose();
    _frameTimer?.cancel();
    _sessionTimer?.cancel();
    _channel?.sink.close();
    _notificationService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _isVideoInitialized && _videoController != null
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            if (_isCameraInitialized)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _attentionDetected
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            if (_isAIMonitoringActive)
              Positioned(
                top: 24,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _attentionDetected
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFEF5350),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isVideoInitialized)
                      VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF42A5F5),
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: _currentVideoIndex > 0
                              ? () {
                                  setState(() {
                                    _currentVideoIndex--;
                                  });
                                  _videoController?.dispose();
                                  _initializeVideo();
                                }
                              : null,
                          icon: const Icon(Icons.skip_previous),
                          color: Colors.white,
                          iconSize: 32,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            _videoController?.value.isPlaying ?? false
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                          ),
                          color: Colors.white,
                          iconSize: 48,
                        ),
                        IconButton(
                          onPressed:
                              _currentVideoIndex < widget.videos.length - 1
                              ? () {
                                  setState(() {
                                    _currentVideoIndex++;
                                  });
                                  _videoController?.dispose();
                                  _initializeVideo();
                                }
                              : null,
                          icon: const Icon(Icons.skip_next),
                          color: Colors.white,
                          iconSize: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video ${_currentVideoIndex + 1} of ${widget.videos.length} - Day ${widget.day}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentCompletionView extends StatelessWidget {
  final VoidCallback onDone;

  const _AssessmentCompletionView({required this.onDone});

  static const _green = Color(0xFF76D978);
  static const _dark = Color(0xFF070B10);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    final scale = (shortest / 390).clamp(.86, 1.08).toDouble();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CompletionBgPainter()),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.18),
                    radius: 1.05,
                    colors: [
                      const Color(0xFF18232C).withValues(alpha: .72),
                      _dark,
                      Colors.black,
                    ],
                    stops: const [0, .58, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _AssessmentConfettiPainter()),
            ),
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, -38 * scale),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SuccessMark(size: 138 * scale),
                      SizedBox(height: 74 * scale),
                      Text(
                        'Assessment Completed',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (33 * scale).clamp(29, 36),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          height: 1.05,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: .65),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                      Text(
                        "Great job! You've completed\ntoday's assessment.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .68),
                          fontSize: (21 * scale).clamp(18, 23),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 36 * scale,
              right: 36 * scale,
              bottom: (78 * scale) + bottomInset,
              child: SizedBox(
                height: (65 * scale).clamp(58, 68),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF72D572), Color(0xFF7BE17A)],
                    ),
                    borderRadius: BorderRadius.circular(17 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: .28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17 * scale),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (22 * scale).clamp(20, 24),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: size.width * .5 - 67,
              bottom: 13 + bottomInset * .15,
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  final double size;

  const _SuccessMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6BD36D).withValues(alpha: .11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF71D873).withValues(alpha: .18),
                  blurRadius: size * .33,
                  spreadRadius: size * .06,
                ),
              ],
            ),
          ),
          Container(
            width: size * .76,
            height: size * .76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF70D573).withValues(alpha: .25),
            ),
          ),
          Container(
            width: size * .58,
            height: size * .58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8AE585), Color(0xFF68CE68)],
              ),
            ),
          ),
          Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: size * .38,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: .24),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final firstWave = Path()
      ..moveTo(0, size.height * .66)
      ..cubicTo(
        size.width * .23,
        size.height * .58,
        size.width * .37,
        size.height * .72,
        size.width * .58,
        size.height * .68,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .65,
        size.width * .9,
        size.height * .56,
        size.width,
        size.height * .45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final secondWave = Path()
      ..moveTo(0, size.height * .76)
      ..cubicTo(
        size.width * .24,
        size.height * .67,
        size.width * .5,
        size.height * .78,
        size.width * .68,
        size.height * .74,
      )
      ..cubicTo(
        size.width * .84,
        size.height * .71,
        size.width * .93,
        size.height * .68,
        size.width,
        size.height * .65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF173C24).withValues(alpha: .58),
          const Color(0xFF11261A).withValues(alpha: .24),
        ],
      ).createShader(Offset.zero & size);

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF1C4428).withValues(alpha: .42),
          const Color(0xFF1D4228).withValues(alpha: .2),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(firstWave, paint1);
    canvas.drawPath(secondWave, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AssessmentConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final items = <_ConfettiItem>[
      _ConfettiItem(.22, .31, 8, const Color(0xFF2F6B3D), .78),
      _ConfettiItem(.3, .22, 7, Colors.white, .74),
      _ConfettiItem(.35, .48, 8, const Color(0xFF3B9447), .78),
      _ConfettiItem(.68, .48, 6, const Color(0xFF2D7A3F), .78),
      _ConfettiItem(.75, .22, 16, const Color(0xFF49A94B), .72),
      _ConfettiItem(.8, .39, 9, const Color(0xFF3E5E83), .78),
      _ConfettiItem(.95, .02, 10, const Color(0xFF44DE83), 1),
    ];

    for (final item in items) {
      final paint = Paint()
        ..color = item.color.withValues(alpha: item.opacity)
        ..style = PaintingStyle.fill;
      final center = Offset(size.width * item.x, size.height * item.y);

      if (item.size > 12) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-.78);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: item.size * .32,
              height: item.size,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(.78);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: item.size,
            height: item.size,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfettiItem {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double opacity;

  const _ConfettiItem(this.x, this.y, this.size, this.color, this.opacity);
}
