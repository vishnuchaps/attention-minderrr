import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:attention_minder/module/attention_management/presentation/screens/video_attention_monitor.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/service/notification_service.dart';
import 'package:attention_minder/service/camera_frame_encoder.dart';
import 'package:attention_minder/service/treatment_document_loader.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfTreatmentScreen extends StatefulWidget {
  final int day;
  final VideoFile fileData;
  final String localPath;
  final VideoAttentionMonitor? attentionMonitor;

  const PdfTreatmentScreen({
    super.key,
    required this.day,
    required this.fileData,
    required this.localPath,
    this.attentionMonitor,
  });

  @override
  State<PdfTreatmentScreen> createState() => _PdfTreatmentScreenState();
}

class _DocxReader extends StatelessWidget {
  const _DocxReader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F4F6),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: SelectionArea(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 17,
                  height: 1.65,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentLoadError extends StatelessWidget {
  const _DocumentLoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 48,
                color: Color(0xFFEF5350),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to display this document',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('FormatException: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfTreatmentScreenState extends State<PdfTreatmentScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  NotificationService? _notificationService;
  // PDFViewController? _pdfController; // Unused

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
  // Unused tracking variables removed to fix lints
  // double _totalInattentionDuration = 0;
  final List<int> _concentrationScores = [];
  // String _lastFeedback = '';
  // List<String> _lastRecommendations = [];
  bool _isShowingAlert = false;
  bool _hasAttentionAdvisory = false;
  bool _didShowReadingAdvisory = false;
  bool _pausedByLifecycle = false;
  bool _isAppInForeground = true;

  // PDF tracking
  int _totalPages = 0;
  int _currentPage = 0;
  late final Future<LoadedTreatmentDocument> _documentFuture;

  // Message history for session summary
  final List<Map<String, dynamic>> _validationHistory = [];
  DateTime? _lastAlertTime;
  int _consecutiveGoodFrames = 0;
  bool _wasInAlert = false;

  // Latest validation state
  Map<String, dynamic>? _latestValidationResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _documentFuture = TreatmentDocumentLoader.load(widget.localPath);
    _initializeNotificationService();
    _initializeCamera();
    _startSessionTimer();
    // Auto start monitoring after a short delay to allow camera init
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _startAIMonitoring();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      if (_pausedByLifecycle) {
        _pausedByLifecycle = false;
        unawaited(_startAIMonitoring());
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      if (_isAIMonitoringActive && !_pausedByLifecycle) {
        _pausedByLifecycle = true;
        unawaited(_stopAIMonitoring());
      }
    }
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
        debugPrint('No cameras available');
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
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startAIMonitoring() async {
    if (!_isAppInForeground) {
      _pausedByLifecycle = true;
      return;
    }
    if (!_isCameraInitialized) {
      // Retry if camera not ready yet
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isAIMonitoringActive) _startAIMonitoring();
      });
      return;
    }

    try {
      final localMonitor = widget.attentionMonitor;
      if (localMonitor == null) {
        throw StateError(
          'An on-device attention monitor is required. WebSocket detection '
          'has been disabled.',
        );
      }
      await localMonitor.start(
        send: (_) {},
        day: widget.day,
        isAssessment: false,
      );
      await _activateFrameMonitoring();
    } catch (e) {
      debugPrint('Error starting AI monitoring: $e');
      _showError('Failed to start AI monitoring');
    }
  }

  Future<void> _activateFrameMonitoring() async {
    _frameTimer?.cancel();
    if (_cameraController?.value.isStreamingImages != true) {
      await _cameraController?.startImageStream(_onCameraFrame);
    }
    if (mounted) setState(() => _isAIMonitoringActive = true);
  }

  DateTime _nextFrameAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _onCameraFrame(CameraImage frame) {
    final now = DateTime.now();
    if (_isSendingFrame || now.isBefore(_nextFrameAt)) return;
    // Reading saccades are often shorter than 100 ms. A 250 ms cadence can
    // sample only the fixations on either side and miss the movement entirely,
    // especially on iOS. Request up to 10 observations per second; the
    // in-flight guard below naturally applies backpressure on slower devices.
    _nextFrameAt = now.add(const Duration(milliseconds: 100));
    _sendCameraFrame(frame);
  }

  Future<void> _stopAIMonitoring() async {
    _frameTimer?.cancel();
    if (_cameraController?.value.isStreamingImages == true) {
      await _cameraController?.stopImageStream();
    }

    setState(() {
      _isAIMonitoringActive = false;
    });
  }

  Future<void> _sendCameraFrame(CameraImage frame) async {
    if (_isSendingFrame ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    _isSendingFrame = true;
    XFile? image;
    try {
      image = await CameraFrameEncoder.encode(
        frame,
        rotationDegrees: CameraFrameEncoder.rotationForCamera(
          camera: _cameraController!.description,
          deviceOrientation: _cameraController!.value.deviceOrientation,
          isIOS: defaultTargetPlatform == TargetPlatform.iOS,
        ),
      );
      if (widget.attentionMonitor case final monitor?) {
        final result = await monitor.analyze(
          image: image,
          videoPosition: Duration(seconds: _sessionDuration),
        );
        _handleWebSocketMessage(
          jsonEncode({'type': 'validation_result', 'result': result}),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error sending frame: $e');
    } finally {
      try {
        if (image != null) await File(image.path).delete();
      } catch (_) {}
      _isSendingFrame = false;
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      // Skip connection status messages
      if (data['type'] == 'connection_established' || data['type'] == 'error') {
        debugPrint('WebSocket status: ${data['message']}');
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
        final uiMessage = result['ui_message'] as Map<String, dynamic>?;
        final uiSeverity =
            uiMessage?['severity']?.toString().toLowerCase().trim() ?? '';
        final uiAlertMessage = uiMessage?['message']?.toString().trim() ?? '';
        final normalizedReason =
            result['reason_code']?.toString().toUpperCase().trim() ?? '';
        final hasConfirmedLocalWarning =
            result['should_show_alert'] == true ||
            uiSeverity == 'warning' ||
            uiSeverity == 'critical' ||
            uiSeverity == 'error' ||
            uiSeverity == 'danger';
        final advisoryContractValue = result['should_show_advisory'];
        final hasLocalAdvisory = advisoryContractValue is bool
            ? advisoryContractValue
            : normalizedReason == 'READING_NOT_DETECTED';
        if (!hasLocalAdvisory && !hasConfirmedLocalWarning) {
          _didShowReadingAdvisory = false;
        }

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
        final bool isAttentionGood = widget.attentionMonitor != null
            ? !hasConfirmedLocalWarning && !hasLocalAdvisory
            : faceDetected &&
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
          _hasAttentionAdvisory = hasLocalAdvisory;
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
        if (hasLocalAdvisory && _didShowReadingAdvisory) return;

        final now = DateTime.now();
        if (_lastAlertTime != null &&
            now.difference(_lastAlertTime!).inSeconds < 5) {
          return; // Cooldown period - don't spam alerts
        }

        // Check for negative scenarios that require pausing
        bool shouldPause = false;
        String alertMessage = '';

        if (widget.attentionMonitor != null) {
          // Reading-pattern uncertainty is advisory-only. It must not cover
          // the PDF or prevent a genuinely focused user from continuing.
          shouldPause = hasConfirmedLocalWarning;
          alertMessage = uiAlertMessage.isNotEmpty
              ? uiAlertMessage
              : message.isNotEmpty
              ? message
              : 'Please refocus on the reading material.';
        } else if (!faceDetected) {
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
          if (hasLocalAdvisory) _didShowReadingAdvisory = true;
          _pauseCount++;
          _totalAlerts++;
          _lastAlertTime = now;
          _wasInAlert = true;
          _showAttentionAlert(alertMessage, recommendations);
        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
      debugPrint('Message content: $message');
    }
  }

  bool _verifyUserReady() {
    if (_latestValidationResult == null) return false;

    final result = _latestValidationResult!;
    if (widget.attentionMonitor != null) {
      // A reading-pattern warning is raised after sustained inactivity, but
      // the blocking dialog covers the document so the user cannot prove a
      // new scan while it is open. The monitor exposes physical readiness
      // separately, allowing Continue once face, eyes, lighting, and gaze are
      // corrected without weakening the reading alert itself.
      return result['ready_to_continue'] == true;
    }
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
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFF151719),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.2),
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
                  _buildAlertCameraPanel(isReady: _verifyUserReady()),
                  const SizedBox(height: 16),
                  // Main message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.3),
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
                          ? const Color(0xFF66BB6A).withValues(alpha: 0.1)
                          : const Color(0xFFEF5350).withValues(alpha: 0.1),
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
                    backgroundColor: _verifyUserReady()
                        ? const Color(0xFF43E267)
                        : const Color(0xFF4B535A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _verifyUserReady()
                        ? 'Continue Document'
                        : 'Correct Your Focus to Continue',
                    style: const TextStyle(
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

  Widget _buildAlertCameraPanel({required bool isReady}) {
    final result = _latestValidationResult;
    final analysis = result?['analysis'] as Map<String, dynamic>?;
    final faceOk = result?['face_detected'] == true;
    final eyesOk = analysis?['eyes_closed'] != true;
    final lightOk = analysis?['low_light'] != true;
    final color = isReady ? const Color(0xFF43E267) : const Color(0xFFFF4D5E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isCameraInitialized && _cameraController != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                const ColoredBox(
                  color: Color(0xFF24272A),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCameraStatusChip('Face', faceOk),
                    _buildCameraStatusChip('Eyes', eyesOk),
                    _buildCameraStatusChip('Light', lightOk),
                    _buildCameraStatusChip('Focus', isReady),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraStatusChip(String label, bool isOk) {
    final color = isOk ? const Color(0xFF43E267) : const Color(0xFFFF4D5E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_rounded : Icons.close_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    await widget.attentionMonitor?.complete(
      totalDuration: Duration(seconds: _sessionDuration),
    );
    // Analyze session history
    final sessionAnalysis = _analyzeSessionHistory();
    final localMetrics = widget.attentionMonitor?.sessionMetrics;

    // Play completion sound and message
    await _notificationService?.playSessionComplete();

    final double attentionPercentage = localMetrics != null
        ? localMetrics.attentionEngagementRate
        : (sessionAnalysis['attentionPercentage'] ?? 0.0);
    final double avgConcentration = attentionPercentage / 10;
    final double faceDetectedPercentage = localMetrics != null
        ? localMetrics.faceDetectionRate
        : (sessionAnalysis['faceDetectedPercentage'] ?? 0.0);
    final double maximumInattention = localMetrics != null
        ? localMetrics.maximumInattentionDuration
        : (sessionAnalysis['totalInattentionTime'] ?? 0.0);
    final int displayScore = attentionPercentage.round().clamp(0, 100);
    await _notificationService?.playEncouragement(displayScore);

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
                color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
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
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
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
                      _formatDuration(
                        localMetrics?.sessionDurationSeconds ??
                            _sessionDuration,
                      ),
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
                    if (maximumInattention > 0) ...[
                      const Divider(height: 20, color: Colors.grey),
                      _buildSessionStat(
                        'Max Inattention',
                        '${maximumInattention.toStringAsFixed(1)}s',
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
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _frameTimer?.cancel();
    _sessionTimer?.cancel();
    _notificationService?.dispose();
    unawaited(widget.attentionMonitor?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildReaderToolbar(context),
            Expanded(child: _buildDocumentReader()),
            _buildReaderBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderToolbar(BuildContext context) {
    final statusColor = !_isAIMonitoringActive
        ? const Color(0xFF6B7280)
        : _hasAttentionAdvisory
        ? const Color(0xFFD97706)
        : _attentionDetected
        ? const Color(0xFF15803D)
        : const Color(0xFFB42318);
    final statusText = !_isAIMonitoringActive
        ? 'Monitoring paused'
        : _hasAttentionAdvisory
        ? 'Check your focus'
        : _attentionDetected
        ? 'Monitoring active'
        : 'Attention needed';

    return Material(
      color: Colors.white,
      elevation: 1,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.fileData.displayTitle.isEmpty
                    ? 'Reading document'
                    : widget.fileData.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: false,
              label: statusText,
              child: Tooltip(
                message: 'Attention monitoring is required for this session',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentReader() {
    return Listener(
      onPointerMove: (event) {
        if (event.delta.distance >= 1) {
          widget.attentionMonitor?.recordContentInteraction();
        }
      },
      child: FutureBuilder<LoadedTreatmentDocument>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _DocumentLoadError(
              message:
                  snapshot.error?.toString() ??
                  'The document could not be opened.',
            );
          }
          final document = snapshot.data!;
          if (document.type == TreatmentDocumentType.docx) {
            return _DocxReader(text: document.text!);
          }
          return PDFView(
            filePath: widget.localPath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) => setState(() => _totalPages = pages ?? 0),
            onViewCreated: (controller) {},
            onPageChanged: (page, total) {
              widget.attentionMonitor?.recordContentInteraction();
              setState(() => _currentPage = page ?? 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildReaderBottomBar() {
    final pageLabel = _totalPages > 0
        ? 'Page ${_currentPage + 1} of $_totalPages'
        : 'Reading document';
    return Material(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF9CA3AF),
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _showCompletionDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Complete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
