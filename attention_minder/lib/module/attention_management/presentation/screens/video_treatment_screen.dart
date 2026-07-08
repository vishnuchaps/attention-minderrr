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
  bool _isHandlingVideoComplete = false;
  bool _isWaitingForEndcallResult = false;
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
  int _sameWarningReasonCount = 0;
  String? _lastWarningReason;
  bool _wasInAlert = false;

  // Latest validation state
  Map<String, dynamic>? _latestValidationResult;
  Map<String, dynamic>? _latestEndcallProcessedResult;
  String? _latestSentFrameId;
  int? _latestProcessedFrameOrder;

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
        final value = _videoController!.value;
        if (value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration &&
            !_isHandlingVideoComplete) {
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

  int? _frameOrderFromId(String? frameId) {
    if (frameId == null || frameId.isEmpty) return null;

    final match = RegExp(r'^frame-(\d+)-(\d+)$').firstMatch(frameId);
    if (match == null) return null;

    final timestamp = int.tryParse(match.group(1)!);
    final sequence = int.tryParse(match.group(2)!);

    if (timestamp == null || sequence == null) return null;

    return timestamp * 1000 + sequence;
  }

  int _warningThresholdForReason(String reason) {
    switch (reason.toLowerCase().trim()) {
      case 'eyes_closed':
      case 'left_eye_closed':
      case 'right_eye_closed':
      case 'face_missing':
      case 'face_not_detected':
      case 'no_face':
      case 'low_light':
      case 'yawning':
      case 'drowsy':
        return 2;

      case 'looking_left':
      case 'looking_right':
      case 'looking_up':
      case 'looking_down':
      case 'looking_away':
      case 'gaze_away':
      case 'head_moved':
        return 3;

      case 'low_concentration':
      case 'not_video_attentive':
      case 'distracted':
      case 'idle_distracted':
        return 5;

      case 'face_not_centered':
      case 'face_distance':
      case 'face_on_edge':
        return 3;

      default:
        return _badFrameThreshold;
    }
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

      final decodedMessage = jsonDecode(message);
      if (decodedMessage is! Map<String, dynamic>) {
        print('Ignoring unexpected WebSocket message: $message');
        return;
      }

      final data = decodedMessage;

      printLongLog(
        'FULL BACKEND RESPONSE This',
        const JsonEncoder.withIndent('  ').convert(data),
      );

      if (data['type'] == 'connection_established' || data['type'] == 'error') {
        print('WebSocket status: ${data['message']}');
        return;
      }

      if (data['type'] == 'endcall_processed') {
        _handleEndcallProcessed(data);
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
        final responseFrameOrder = _frameOrderFromId(responseFrameId);
        final bool isStaleResponse =
            responseFrameOrder != null &&
            _latestProcessedFrameOrder != null &&
            responseFrameOrder < _latestProcessedFrameOrder!;
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
stale_response          : ${isStaleResponse ? 'YES - IGNORED' : 'NO'}
====================================
''');

        if (isStaleResponse) {
          print(
            'Ignoring stale backend response for frame_id: $responseFrameId',
          );
          return;
        }

        if (responseFrameOrder != null) {
          _latestProcessedFrameOrder = responseFrameOrder;
        }

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

        final uiFlags = result['ui_flags'] as Map<String, dynamic>?;
        final bool shouldShowAlert = uiFlags?['should_show_alert'] == true;
        final uiMessage = result['ui_message'] as Map<String, dynamic>?;
        final String uiMessageSeverity =
            uiMessage?['severity']?.toString().toLowerCase().trim() ?? '';
        final String uiAlertMessage =
            uiMessage?['message']?.toString().trim() ?? '';
        final String uiWarningReason =
            uiMessage?['reason']?.toString().toLowerCase().trim() ?? '';
        final bool hasUiWarning = uiMessageSeverity == 'warning';
        final bool backendAlertCandidate = shouldShowAlert && hasUiWarning;
        final String warningReason = uiWarningReason.isNotEmpty
            ? uiWarningReason
            : backendAlertCandidate
            ? 'generic_warning'
            : '';
        final int warningThreshold = _warningThresholdForReason(warningReason);

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
                  !lowLight &&
                  notDrowsy &&
                  !yawning &&
                  !eyesClosed &&
                  concentrationScore >= 7 &&
                  engagementState == 'watching_video' &&
                  !shouldShowAlert &&
                  !hasUiWarning;

        if (isAttentionGood && !_isShowingAlert) {
          _consecutiveGoodFrames++;
          _consecutiveBadFrames = 0;
          _sameWarningReasonCount = 0;
          _lastWarningReason = null;

          if (_consecutiveGoodFrames >= 3 && _wasInAlert) {
            setState(() {
              _wasInAlert = false;
              _attentionDetected = true;
            });
          }
        } else {
          _consecutiveGoodFrames = 0;

          if (!_isShowingAlert) {
            if (widget.isAssessment) {
              _consecutiveBadFrames++;
            } else if (backendAlertCandidate) {
              if (_lastWarningReason == warningReason) {
                _sameWarningReasonCount++;
              } else {
                _lastWarningReason = warningReason;
                _sameWarningReasonCount = 1;
              }
            } else {
              _sameWarningReasonCount = 0;
              _lastWarningReason = null;
            }
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

        if (widget.isAssessment && _consecutiveBadFrames < _badFrameThreshold) {
          print(
            'Bad frame ignored. Count: $_consecutiveBadFrames / $_badFrameThreshold',
          );
          return;
        }

        if (!widget.isAssessment) {
          if (!backendAlertCandidate) return;

          if (_sameWarningReasonCount < warningThreshold) {
            print(
              'Warning ignored. Reason: $warningReason Count: $_sameWarningReasonCount / $warningThreshold',
            );
            return;
          }
        }
        final now = DateTime.now();
        if (_lastAlertTime != null &&
            now.difference(_lastAlertTime!).inSeconds < 5) {
          return;
        }
        bool shouldPause = false;
        String alertMessage = '';
        List<String> alertRecommendations = recommendations;

        if (widget.isAssessment) {
          if (lowLight) {
            shouldPause = true;
            alertMessage = lowLightRecommendation;
            alertRecommendations = [lowLightRecommendation];
          } else if (!faceDetected) {
            shouldPause = true;
            alertMessage =
                'Face not detected! Please position your face in front of the camera.';
            alertRecommendations = [
              'Position your face clearly in front of the camera.',
            ];
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
          }
        } else {
          if (backendAlertCandidate) {
            shouldPause = true;
            alertMessage = uiAlertMessage.isNotEmpty
                ? uiAlertMessage
                : message.isNotEmpty
                ? message
                : 'Please refocus on the treatment.';
          }

          /*
          Previous non-assessment alert logic:

          if (lowLight) {
            shouldPause = true;
            alertMessage = lowLightRecommendation;
          } else if (!faceDetected) {
            shouldPause = true;
            alertMessage =
                'Face not detected! Please position your face in front of the camera.';
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
          } else if (!validationPassed) {
            shouldPause = true;
            alertMessage =
                'Please adjust your position. ${recommendations.isNotEmpty ? recommendations.first : ''}';
          } else if (!videoAttentive) {
            shouldPause = true;
            alertMessage = 'You seem distracted. Please focus on the video.';
          } else if (actionRequired) {
            shouldPause = true;
            alertMessage = message.isNotEmpty
                ? message
                : 'Please refocus on the treatment.';
          } else if (concentrationScore < 7) {
            shouldPause = true;
            alertMessage =
                'Low concentration detected. Take a moment to refocus.';
          } else if (engagementState.contains('distracted') ||
              engagementState == 'idle_distracted') {
            shouldPause = true;
            alertMessage = 'Please pay attention to the video treatment.';
          }
          */
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
    final uiFlags = result['ui_flags'] as Map<String, dynamic>?;
    final bool shouldShowAlert = uiFlags?['should_show_alert'] == true;
    final uiMessage = result['ui_message'] as Map<String, dynamic>?;
    final String uiMessageSeverity =
        uiMessage?['severity']?.toString().toLowerCase().trim() ?? '';

    final bool isReady =
        faceDetected &&
        validationPassed &&
        !lowLight &&
        notDrowsy &&
        !yawning &&
        !eyesClosed &&
        concentrationScore >= 7 &&
        videoAttentive &&
        engagementState == 'watching_video' &&
        !shouldShowAlert &&
        uiMessageSeverity != 'warning';

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

          return PopScope(
            canPop: false,
            child: AlertDialog(
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
                            _verifyUserReady()
                                ? Icons.check_circle
                                : Icons.error,
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
                          _sameWarningReasonCount = 0;
                          _lastWarningReason = null;
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
            ),
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

  Map<String, dynamic> _currentEndcallPayload() {
    final currentVideo = widget.videos[_currentVideoIndex];

    return {
      'type': 'endcall',
      'filetype': 'video',
      'day_completed': currentVideo.day > 0 ? currentVideo.day : widget.day,
      'order_number': currentVideo.orderNumber,
    };
  }

  void _sendEndcallForCurrentVideo({required bool waitForResult}) {
    if (widget.videos.isEmpty || widget.isAssessment) return;

    final payload = _currentEndcallPayload();
    print(
      'Sending video endcall: ${const JsonEncoder.withIndent('  ').convert(payload)}',
    );

    _isWaitingForEndcallResult = waitForResult;
    _channel?.sink.add(jsonEncode(payload));
  }

  void _handleEndcallProcessed(Map<String, dynamic> data) {
    printLongLog(
      'ENDCALL PROCESSED',
      const JsonEncoder.withIndent('  ').convert(data),
    );

    _latestEndcallProcessedResult = data;

    if (!_isWaitingForEndcallResult) return;

    _isWaitingForEndcallResult = false;

    if (!mounted) return;
    _showCompletionDialog(data);
  }

  void _onVideoComplete() {
    if (_isHandlingVideoComplete) return;
    _isHandlingVideoComplete = true;
    _videoController?.pause();

    if (_currentVideoIndex < widget.videos.length - 1) {
      _sendEndcallForCurrentVideo(waitForResult: false);
      setState(() {
        _currentVideoIndex++;
      });
      _videoController?.dispose();
      _initializeVideo();
      _isHandlingVideoComplete = false;
    } else {
      if (widget.isAssessment) {
        _showCompletionDialog();
        return;
      }

      _frameTimer?.cancel();
      _sendEndcallForCurrentVideo(waitForResult: true);

      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted || !_isWaitingForEndcallResult) return;
        _isWaitingForEndcallResult = false;
        _showCompletionDialog(_latestEndcallProcessedResult);
      });
    }
  }

  // ignore: unused_element
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

  double _readDouble(Map<String, dynamic>? source, String key) {
    final value = source?[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _readInt(Map<String, dynamic>? source, String key) {
    final value = source?[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showCompletionDialog([Map<String, dynamic>? backendResult]) async {
    final backendSummary =
        backendResult?['session_summary'] as Map<String, dynamic>?;

    await _notificationService?.playSessionComplete();

    if (widget.isAssessment) {
      if (!mounted) return;
      _showAssessmentCompletionDialog();
      return;
    }

    /*
    Previous frontend calculation kept for reference. The backend now sends the
    final result in the endcall_processed socket payload, and the dialog reads
    those values from session_summary instead.

    final sessionAnalysis = _analyzeSessionHistory();
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
    */

    final double avgConcentration = _readDouble(
      backendSummary,
      'avg_concentration_score',
    );
    final double faceDetectedPercentage = _readDouble(
      backendSummary,
      'face_detection_rate',
    );
    final double attentionPercentage = _readDouble(
      backendSummary,
      'attention_engagement_rate',
    );
    final double maxInattention = _readDouble(
      backendSummary,
      'max_inattention_duration',
    );
    final int displayScore = _readDouble(
      backendSummary,
      'final_attention_score_percent',
    ).round();
    final int safeDisplayScore = displayScore > 0
        ? displayScore.clamp(0, 100)
        : _attentionScore;
    final int totalFrames = _readInt(backendSummary, 'total_frames');
    final int metricsCount = _readInt(backendResult, 'metrics_count') > 0
        ? _readInt(backendResult, 'metrics_count')
        : _readInt(backendSummary, 'stored_metric_samples');
    final bool progressUpdated = backendResult?['progress_updated'] == true;
    final String completionMessage =
        backendResult?['message']?.toString() ?? 'Session ended successfully';

    await _notificationService?.playEncouragement(safeDisplayScore);

    final int pointsEarned = 200 + (safeDisplayScore ~/ 10) * 10;

    final String performanceLevel = safeDisplayScore >= 90
        ? 'Excellent'
        : safeDisplayScore >= 70
        ? 'Good'
        : safeDisplayScore >= 50
        ? 'Fair'
        : 'Needs Improvement';

    final Color performanceColor = safeDisplayScore >= 90
        ? const Color(0xFF66BB6A)
        : safeDisplayScore >= 70
        ? const Color(0xFF42A5F5)
        : safeDisplayScore >= 50
        ? const Color(0xFFFFA726)
        : const Color(0xFFEF5350);

    if (!mounted) return;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _ManagementCompletionView(
          completionMessage: completionMessage,
          day: backendResult?['day_completed'] ?? widget.day,
          orderNumber:
              backendResult?['order_number'] ??
              widget.videos[_currentVideoIndex].orderNumber,
          videosWatched: widget.videos.length,
          sessionDuration: _formatDuration(_sessionDuration),
          metricsCount: metricsCount,
          totalFrames: totalFrames,
          avgConcentration: avgConcentration,
          faceDetectionPercentage: faceDetectedPercentage,
          attentionPercentage: attentionPercentage,
          maxInattention: maxInattention,
          progressUpdated: progressUpdated,
          pointsEarned: pointsEarned,
          score: safeDisplayScore,
          performanceLevel: performanceLevel,
          performanceColor: performanceColor,
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

class _ManagementCompletionView extends StatelessWidget {
  final String completionMessage;
  final Object day;
  final Object orderNumber;
  final int videosWatched;
  final String sessionDuration;
  final int metricsCount;
  final int totalFrames;
  final double avgConcentration;
  final double faceDetectionPercentage;
  final double attentionPercentage;
  final double maxInattention;
  final bool progressUpdated;
  final int pointsEarned;
  final int score;
  final String performanceLevel;
  final Color performanceColor;
  final VoidCallback onDone;

  const _ManagementCompletionView({
    required this.completionMessage,
    required this.day,
    required this.orderNumber,
    required this.videosWatched,
    required this.sessionDuration,
    required this.metricsCount,
    required this.totalFrames,
    required this.avgConcentration,
    required this.faceDetectionPercentage,
    required this.attentionPercentage,
    required this.maxInattention,
    required this.progressUpdated,
    required this.pointsEarned,
    required this.score,
    required this.performanceLevel,
    required this.performanceColor,
    required this.onDone,
  });

  static const _dark = Color(0xFF070B10);
  static const _green = Color(0xFF76D978);
  static const _gold = Color(0xFFF7C14A);

  @override
  Widget build(BuildContext context) {
    final primaryMetrics = <_ManagementMetricData>[
      _ManagementMetricData(
        icon: Icons.psychology_outlined,
        label: 'Concentration',
        value: '${avgConcentration.toStringAsFixed(1)}/10',
      ),
      _ManagementMetricData(
        icon: Icons.face_outlined,
        label: 'Face detection',
        value: '${faceDetectionPercentage.toStringAsFixed(0)}%',
      ),
      _ManagementMetricData(
        icon: Icons.visibility_outlined,
        label: 'Attention',
        value: '${attentionPercentage.toStringAsFixed(0)}%',
      ),
      _ManagementMetricData(
        icon: Icons.task_alt_outlined,
        label: 'Progress',
        value: progressUpdated ? 'Updated' : 'Pending',
      ),
    ];

    final detailMetrics = <_ManagementMetricData>[
      _ManagementMetricData(
        icon: Icons.play_circle_outline,
        label: 'Videos watched',
        value: '$videosWatched',
      ),
      _ManagementMetricData(
        icon: Icons.timer_outlined,
        label: 'Duration',
        value: sessionDuration,
      ),
      _ManagementMetricData(
        icon: Icons.analytics_outlined,
        label: 'Metrics',
        value: '$metricsCount',
      ),
      _ManagementMetricData(
        icon: Icons.filter_frames_outlined,
        label: 'Frames',
        value: '$totalFrames',
      ),
      if (maxInattention > 0)
        _ManagementMetricData(
          icon: Icons.timer_off_outlined,
          label: 'Max inattention',
          value: '${maxInattention.toStringAsFixed(1)}s',
        ),
    ];

    return Material(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final size = MediaQuery.sizeOf(context);
          final shortest = size.shortestSide;
          final height = viewport.maxHeight;
          final scale = (shortest / 390).clamp(.82, 1.08).toDouble();
          final isShort = height < 700;
          final horizontalPadding = (shortest * .062).clamp(18, 28).toDouble();
          final buttonHorizontalPadding = (shortest * .035)
              .clamp(10, 16)
              .toDouble();
          final ringSize = isShort
              ? (shortest * .2).clamp(72, 92).toDouble()
              : (shortest * .27).clamp(96, 124).toDouble();

          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CompletionBgPainter()),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -.34),
                        radius: 1.12,
                        colors: [
                          const Color(0xFF1E2A33).withValues(alpha: .82),
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
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isShort ? 10 : 18 * scale,
                          horizontalPadding,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ManagementScoreRing(
                              score: score,
                              color: performanceColor,
                              size: ringSize,
                            ),
                            SizedBox(height: isShort ? 8 : 12 * scale),
                            Text(
                              'Session Complete',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isShort
                                    ? (24 * scale).clamp(21, 26)
                                    : (29 * scale).clamp(25, 32),
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: 0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: .55),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isShort ? 6 : 8 * scale),
                            Text(
                              completionMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .7),
                                fontSize: (14 * scale).clamp(12, 15),
                                height: 1.28,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: isShort ? 10 : 14 * scale),
                            _ManagementSummaryBand(
                              day: day,
                              orderNumber: orderNumber,
                              performanceLevel: performanceLevel,
                              performanceColor: performanceColor,
                              compact: isShort,
                            ),
                            SizedBox(height: isShort ? 10 : 12 * scale),
                            _PrimaryMetricGrid(
                              metrics: primaryMetrics,
                              compact: isShort,
                              scale: scale,
                            ),
                            SizedBox(height: isShort ? 10 : 12 * scale),
                            _PointsBand(
                              pointsEarned: pointsEarned,
                              compact: true,
                            ),
                            SizedBox(height: isShort ? 10 : 12 * scale),
                            _DetailMetricChips(
                              metrics: detailMetrics,
                              compact: isShort,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        buttonHorizontalPadding,
                        8,
                        buttonHorizontalPadding,
                        10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: (58 * scale).clamp(52, 64),
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
                                fontSize: (20 * scale).clamp(18, 22),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManagementScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  final double size;

  const _ManagementScoreRing({
    required this.score,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
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
                color: color.withValues(alpha: .1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .22),
                    blurRadius: size * .34,
                    spreadRadius: size * .05,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: size * .78,
              height: size * .78,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: size * .07,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: .1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * .24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: size * .04),
                Text(
                  'Attention',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: size * .085,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementSummaryBand extends StatelessWidget {
  final Object day;
  final Object orderNumber;
  final String performanceLevel;
  final Color performanceColor;
  final bool compact;

  const _ManagementSummaryBand({
    required this.day,
    required this.orderNumber,
    required this.performanceLevel,
    required this.performanceColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: performanceColor.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: performanceColor,
              size: compact ? 22 : 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performanceLevel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: performanceColor,
                    fontSize: compact ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day $day - Video $orderNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBand extends StatelessWidget {
  final int pointsEarned;
  final bool compact;

  const _PointsBand({required this.pointsEarned, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_ManagementCompletionView._gold, const Color(0xFFFFD95B)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ManagementCompletionView._gold.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.black,
            size: compact ? 26 : 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Points Earned',
              style: TextStyle(
                color: Colors.black87,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            '$pointsEarned',
            style: TextStyle(
              color: Colors.black,
              fontSize: compact ? 25 : 30,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMetricGrid extends StatelessWidget {
  final List<_ManagementMetricData> metrics;
  final bool compact;
  final double scale;

  const _PrimaryMetricGrid({
    required this.metrics,
    required this.compact,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8 * scale;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: tileWidth,
                  child: _PrimaryMetricPill(data: metric, compact: compact),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PrimaryMetricPill extends StatelessWidget {
  final _ManagementMetricData data;
  final bool compact;

  const _PrimaryMetricPill({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 64 : 74),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: _ManagementCompletionView._gold.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: _ManagementCompletionView._gold,
              size: compact ? 17 : 19,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetricChips extends StatelessWidget {
  final List<_ManagementMetricData> metrics;
  final bool compact;

  const _DetailMetricChips({required this.metrics, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: metrics
          .map((metric) => _DetailMetricChip(data: metric, compact: compact))
          .toList(),
    );
  }
}

class _DetailMetricChip extends StatelessWidget {
  final _ManagementMetricData data;
  final bool compact;

  const _DetailMetricChip({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            color: _ManagementCompletionView._gold,
            size: compact ? 14 : 15,
          ),
          const SizedBox(width: 6),
          Text(
            '${data.label}: ${data.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementMetricData {
  final IconData icon;
  final String label;
  final String value;

  const _ManagementMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });
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
