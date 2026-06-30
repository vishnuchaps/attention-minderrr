import 'dart:async';
import 'dart:convert';
import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/service/notification_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PdfTreatmentScreen extends StatefulWidget {
  final int day;
  final VideoFile fileData;
  final String localPath;

  const PdfTreatmentScreen({
    super.key,
    required this.day,
    required this.fileData,
    required this.localPath,
  });

  @override
  State<PdfTreatmentScreen> createState() => _PdfTreatmentScreenState();
}

class _PdfTreatmentScreenState extends State<PdfTreatmentScreen> {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  NotificationService? _notificationService;
  // PDFViewController? _pdfController; // Unused

  bool _isCameraInitialized = false;
  bool _isAIMonitoringActive = false;
  bool _attentionDetected = true;
  Timer? _frameTimer;
  Timer? _sessionTimer;

  // Session tracking
  int _sessionDuration = 0;
  int _attentionScore = 100;
  int _pauseCount = 0;
  int _totalAlerts = 0;
  // Unused tracking variables removed to fix lints
  // double _totalInattentionDuration = 0;
  List<int> _concentrationScores = [];
  // String _lastFeedback = '';
  // List<String> _lastRecommendations = [];
  bool _isShowingAlert = false;

  // PDF tracking
  int _totalPages = 0;
  int _currentPage = 0;

  // Message history for session summary
  List<Map<String, dynamic>> _validationHistory = [];
  DateTime? _lastAlertTime;
  int _consecutiveGoodFrames = 0;
  bool _wasInAlert = false;

  // Latest validation state
  Map<String, dynamic>? _latestValidationResult;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
    _initializeCamera();
    _startSessionTimer();
    // Auto start monitoring after a short delay to allow camera init
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _startAIMonitoring();
    });
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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      // Use front camera
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

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startAIMonitoring() {
    if (!_isCameraInitialized) {
      // Retry if camera not ready yet
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isAIMonitoringActive) _startAIMonitoring();
      });
      return;
    }

    try {
      // Connect to WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(wsFaceDetectionUrl));

      // Listen to WebSocket messages
      _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          // _showError('Connection lost. Retrying...');
          Future.delayed(const Duration(seconds: 2), () {
            if (_isAIMonitoringActive && mounted) {
              _startAIMonitoring();
            }
          });
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );

      // Start sending camera frames
      _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _sendCameraFrame();
      });

      setState(() {
        _isAIMonitoringActive = true;
      });
    } catch (e) {
      print('Error starting AI monitoring: $e');
      _showError('Failed to start AI monitoring');
    }
  }

  void _stopAIMonitoring() {
    _frameTimer?.cancel();
    _channel?.sink.close();

    setState(() {
      _isAIMonitoringActive = false;
    });
  }

  Future<void> _sendCameraFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get frame dimensions from camera preview size
      final previewSize = _cameraController!.value.previewSize;
      final frameWidth = previewSize?.width.toInt() ?? 640;
      final frameHeight = previewSize?.height.toInt() ?? 480;
      final frameId =
          'frame-${DateTime.now().millisecondsSinceEpoch}-${_validationHistory.length + 1}';
      final timestampSeconds = _sessionDuration.toDouble();

      // Send frame to WebSocket in the expected format
      final message = {
        'type': 'validate_face',
        'frame_base64': base64Image,
        'frame_id': frameId,
        'face': {
          'x': 0,
          'y': 0,
          'width': frameWidth,
          'height': frameHeight,
          'confidence': null,
          'timestamp_seconds': timestampSeconds,
          'frame_id': frameId,
        },
        'frame': {'width': frameWidth, 'height': frameHeight},
        'left_eye_open_probability': null,
        'right_eye_open_probability': null,
        'is_assessment': false,
      };

      final jsonMessage = jsonEncode(message);
      // print('Sending WebSocket message: ${jsonMessage.substring(0, 100)}...');
      _channel?.sink.add(jsonMessage);
    } catch (e) {
      print('Error sending frame: $e');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      // Skip connection status messages
      if (data['type'] == 'connection_established' || data['type'] == 'error') {
        print('WebSocket status: ${data['message']}');
        return;
      }

      // Handle validation_result messages
      if (data['type'] == 'validation_result' && data['result'] != null) {
        final result = data['result'] as Map<String, dynamic>;

        // Store validation message in history for session summary
        _validationHistory.add({
          'timestamp': DateTime.now().toIso8601String(),
          'result': result,
        });

        // Store latest validation result
        _latestValidationResult = result;

        // Extract all relevant data
        final bool faceDetected = result['face_detected'] ?? false;
        final bool validationPassed = result['validation_passed'] ?? true;
        final int concentrationScore = result['concentration_score'] ?? 5;
        final String message = result['message'] ?? '';

        // Extract engagement data
        final engagement = result['engagement'] as Map<String, dynamic>?;
        final bool videoAttentive = engagement?['video_attentive'] ?? true;
        final String engagementState = engagement?['state'] ?? 'focused';

        // Extract feedback data
        final feedback = result['feedback'] as Map<String, dynamic>?;
        final bool actionRequired = feedback?['action_required'] ?? false;
        // final String alertLevel = feedback?['alert_level'] ?? 'low'; // Unused

        // Extract recommendations
        final recommendations =
            (result['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Determine if attention is good
        final bool isAttentionGood =
            faceDetected &&
            validationPassed &&
            videoAttentive &&
            !actionRequired &&
            concentrationScore >= 5 &&
            !engagementState.contains('distracted');

        // Track consecutive good frames
        if (isAttentionGood && !_isShowingAlert) {
          _consecutiveGoodFrames++;
          // After 3 consecutive good frames, clear alert state
          if (_consecutiveGoodFrames >= 3 && _wasInAlert) {
            setState(() {
              _wasInAlert = false;
              _attentionDetected = true;
            });
          }
        } else {
          _consecutiveGoodFrames = 0;
        }

        // Update state
        setState(() {
          _attentionDetected = isAttentionGood;
          // _lastFeedback = message;
          // _lastRecommendations = recommendations;

          // Track concentration scores for averaging
          if (concentrationScore >= 0) {
            _concentrationScores.add(concentrationScore);
            // Calculate average attention score (0-10 scale to 0-100 percentage)
            final avgScore =
                _concentrationScores.reduce((a, b) => a + b) /
                _concentrationScores.length;
            _attentionScore = (avgScore * 10).round().clamp(0, 100);
          }

          // Track inattention duration
          // if (inattentionDuration > 0) {
          //   _totalInattentionDuration = inattentionDuration;
          // }
        });

        // Don't show alert if:
        // 1. Already showing alert
        // 2. Alert was just shown (within 5 seconds)
        // 3. Attention is good
        if (_isShowingAlert) return;
        if (isAttentionGood) return;

        final now = DateTime.now();
        if (_lastAlertTime != null &&
            now.difference(_lastAlertTime!).inSeconds < 5) {
          return; // Cooldown period - don't spam alerts
        }

        // Check for negative scenarios that require pausing
        bool shouldPause = false;
        String alertMessage = '';

        if (!faceDetected) {
          shouldPause = true;
          alertMessage =
              'Face not detected! Please position your face in front of the camera.';
        } else if (!validationPassed) {
          shouldPause = true;
          alertMessage =
              'Please adjust your position. ${recommendations.isNotEmpty ? recommendations.first : ''}';
        } else if (!videoAttentive) {
          shouldPause = true;
          alertMessage = 'You seem distracted. Please focus on the screen.';
        } else if (actionRequired) {
          shouldPause = true;
          alertMessage = message.isNotEmpty
              ? message
              : 'Please refocus on the reading.';
        } else if (concentrationScore < 5) {
          shouldPause = true;
          alertMessage =
              'Low concentration detected. Take a moment to refocus.';
        } else if (engagementState.contains('distracted') ||
            engagementState == 'idle_distracted') {
          shouldPause = true;
          alertMessage = 'Please pay attention to the reading material.';
        }

        // Show alert if needed
        if (shouldPause) {
          _pauseCount++;
          _totalAlerts++;
          _lastAlertTime = now;
          _wasInAlert = true;
          _showAttentionAlert(alertMessage, recommendations);
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
    final bool faceDetected = result['face_detected'] ?? false;
    final bool validationPassed = result['validation_passed'] ?? false;
    final int concentrationScore = result['concentration_score'] ?? 0;

    // Extract engagement data
    final engagement = result['engagement'] as Map<String, dynamic>?;
    final bool videoAttentive = engagement?['video_attentive'] ?? false;
    final String engagementState = engagement?['state'] ?? '';

    // User is ready if:
    // 1. Face is detected
    // 2. Validation passed (proper position)
    // 3. Concentration score >= 5
    // 4. Not in distracted state
    final bool isReady =
        faceDetected &&
        validationPassed &&
        concentrationScore >= 5 &&
        videoAttentive &&
        !engagementState.contains('distracted');

    return isReady;
  }

  void _showAttentionAlert(String message, List<String> recommendations) async {
    if (_isShowingAlert) return;

    setState(() {
      _isShowingAlert = true;
    });

    // Play alert sound and speak message
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
          // Update dialog every 500ms to show real-time readiness status
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
                  // Main message
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

                  // Attention score
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

                  // Recommendations
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

                  // Real-time readiness status
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

                  // Session stats
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
                    // Verify user is ready via WebSocket data
                    if (_verifyUserReady()) {
                      // User is ready - resume
                      setState(() {
                        _isShowingAlert = false;
                        _consecutiveGoodFrames = 0;
                      });
                      Navigator.pop(context);
                    } else {
                      // User is NOT ready - show feedback
                      final latestResult = _latestValidationResult;
                      String feedbackMessage = 'Please ensure:';
                      List<String> issues = [];

                      if (latestResult != null) {
                        if (!(latestResult['face_detected'] ?? false)) {
                          issues.add('✗ Your face is visible in the camera');
                        }
                        if (!(latestResult['validation_passed'] ?? false)) {
                          issues.add('✗ You are properly positioned');
                        }
                        final concentrationScore =
                            latestResult['concentration_score'] ?? 0;
                        if (concentrationScore < 5) {
                          issues.add(
                            '✗ Your concentration level is adequate (currently: $concentrationScore/10)',
                          );
                        }
                        final engagement =
                            latestResult['engagement'] as Map<String, dynamic>?;
                        if (engagement != null &&
                            !(engagement['video_attentive'] ?? false)) {
                          issues.add('✗ You are looking at the screen');
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

                      // Play TTS feedback
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
                    'I\'m Ready - Resume',
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

      // Count face detection
      if (result['face_detected'] == true) faceDetectedCount++;
      if (result['validation_passed'] == true) validationPassedCount++;

      // Track concentration
      final concentration = result['concentration_score'] ?? 0;
      totalConcentration += concentration;

      // Track engagement
      final engagement = result['engagement'] as Map<String, dynamic>?;
      if (engagement != null) {
        if (engagement['video_attentive'] == true) videoAttentiveCount++;
        final state = engagement['state'] ?? '';
        if (state.contains('distracted')) distractedFrames++;

        final inattention = (engagement['inattention_duration'] ?? 0)
            .toDouble();
        if (inattention > maxInattention) maxInattention = inattention;
      }

      // Track drowsiness
      final analysis = result['analysis'] as Map<String, dynamic>?;
      if (analysis != null && analysis['not_drowsy'] == false) {
        drowsyFrames++;
      }

      // Count common issues from recommendations
      final recommendations = result['recommendations'] as List<dynamic>?;
      if (recommendations != null) {
        for (var rec in recommendations) {
          final recStr = rec.toString();
          issueCounter[recStr] = (issueCounter[recStr] ?? 0) + 1;
        }
      }
    }

    // Get top 3 most common issues
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
    // Analyze session history
    final sessionAnalysis = _analyzeSessionHistory();

    // Play completion sound and message
    await _notificationService?.playSessionComplete();
    await _notificationService?.playEncouragement(_attentionScore);

    // Calculate performance metrics from actual data
    final double attentionPercentage =
        sessionAnalysis['attentionPercentage'] ?? 0.0;
    final double avgConcentration = sessionAnalysis['avgConcentration'] ?? 0.0;
    final double faceDetectedPercentage =
        sessionAnalysis['faceDetectedPercentage'] ?? 0.0;

    // Use the highest metric as overall score
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
              // Success message
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

              // Performance score
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
                    // Circular progress indicator
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

              // Session statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSessionStat(
                      'Pages',
                      '$_totalPages',
                      Icons.description_outlined,
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

              // Common issues detected
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

              // Points earned
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
                Navigator.pop(context);
                Navigator.pop(context);
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
            // PDF Viewer
            Column(
              children: [
                Expanded(
                  child: PDFView(
                    filePath: widget.localPath,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: true,
                    pageSnap: true,
                    fitPolicy: FitPolicy.BOTH,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                      });
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      // _pdfController = pdfViewController;
                    },
                    onPageChanged: (int? page, int? total) {
                      setState(() {
                        _currentPage = page ?? 0;
                      });
                    },
                  ),
                ),
                // Bottom bar with controls and Complete button
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade900,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page info
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: Colors.white),
                      ),

                      // Complete Session Button
                      ElevatedButton(
                        onPressed: _showCompletionDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Complete Session',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Camera Preview (Picture-in-Picture)
            if (_isCameraInitialized && _isAIMonitoringActive)
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

            // AI Status Indicator
            if (_isAIMonitoringActive)
              Positioned(
                top: 24,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    if (_isAIMonitoringActive) {
                      _stopAIMonitoring();
                    } else {
                      _startAIMonitoring();
                    }
                  },
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAIMonitoringActive
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAIMonitoringActive ? 'AI Active' : 'AI Paused',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Back button (top left, below AI status)
            Positioned(
              top: 70,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
