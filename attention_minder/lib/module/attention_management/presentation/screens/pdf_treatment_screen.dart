import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:attention_minder/module/attention_management/data/model/pdf_reading_score_request.dart';
import 'package:attention_minder/module/attention_management/presentation/bloc/ai_assessment_score_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_treatment_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_attention_monitor.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/service/notification_service.dart';
import 'package:attention_minder/service/camera_frame_encoder.dart';
import 'package:attention_minder/service/treatment_document_loader.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  final PdfViewerController _pdfController = PdfViewerController();

  static const double _minimumZoom = 1;
  static const double _maximumZoom = 3;
  static const double _zoomStep = 0.25;

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
  BuildContext? _attentionDialogContext;

  // PDF tracking
  int _totalPages = 0;
  int _currentPage = 0;
  double _zoomLevel = _minimumZoom;
  bool _hasReachedLastPage = false;
  TreatmentDocumentType? _documentType;
  late final Future<LoadedTreatmentDocument> _documentFuture;

  // Message history for session summary
  final List<Map<String, dynamic>> _validationHistory = [];
  DateTime? _lastAlertTime;
  int _consecutiveGoodFrames = 0;
  bool _wasInAlert = false;
  bool _isHandlingCompletion = false;

  // Latest validation state
  Map<String, dynamic>? _latestValidationResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _documentFuture = TreatmentDocumentLoader.load(widget.localPath);
    _documentFuture.then<void>((document) {
      if (mounted) {
        setState(() => _documentType = document.type);
      }
    }, onError: (Object _, StackTrace _) {});
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
        _autoDismissAttentionAlertIfReady();

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
      final uiMessage = result['ui_message'] as Map<String, dynamic>?;
      final severity =
          uiMessage?['severity']?.toString().toLowerCase().trim() ?? '';
      final warningStillActive =
          result['should_show_alert'] == true ||
          severity == 'warning' ||
          severity == 'critical' ||
          severity == 'error' ||
          severity == 'danger';

      // Automatic recovery must be stricter than the previous manual button.
      // A centered head can make physical readiness true while the eyes are
      // still looking left or right. Keep the alert visible until both the
      // readiness checks pass and the detector clears the warning episode.
      return result['ready_to_continue'] == true && !warningStillActive;
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

  void _autoDismissAttentionAlertIfReady() {
    final dialogContext = _attentionDialogContext;
    if (!_isShowingAlert ||
        dialogContext == null ||
        !dialogContext.mounted ||
        !_verifyUserReady()) {
      return;
    }

    _attentionDialogContext = null;
    setState(() {
      _isShowingAlert = false;
      _consecutiveGoodFrames = 0;
    });
    Navigator.of(dialogContext).pop();
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          _attentionDialogContext = dialogContext;
          if (_verifyUserReady()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoDismissAttentionAlertIfReady();
            });
          }
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
          );
        },
      ),
    );
    _attentionDialogContext = null;
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

  AttentionSessionMetrics get _pdfScoreMetrics {
    final monitorMetrics = widget.attentionMonitor?.sessionMetrics;
    if (monitorMetrics != null) return monitorMetrics;

    final analysis = _analyzeSessionHistory();
    final totalFrames = (analysis['totalFrames'] as num?)?.toInt() ?? 0;
    final attentionRate =
        (analysis['attentionPercentage'] as num?)?.toDouble() ?? 0;
    final focusedFrames = totalFrames == 0
        ? 0
        : (totalFrames * attentionRate / 100).round();

    return AttentionSessionMetrics(
      finalScore: _attentionScore.clamp(0, 100),
      attentionEngagementRate: attentionRate.clamp(0, 100),
      faceDetectionRate:
          (analysis['faceDetectedPercentage'] as num?)?.toDouble() ?? 0,
      averageConfidence: 0,
      totalProcessedFrames: totalFrames,
      sampledFrames: totalFrames,
      sessionDurationSeconds: _sessionDuration,
      inattentionDuration:
          (analysis['totalInattentionTime'] as num?)?.toDouble() ?? 0,
      maximumInattentionDuration:
          (analysis['totalInattentionTime'] as num?)?.toDouble() ?? 0,
      gazeRatioAverage: 0,
      drowsyState: 0,
      brightnessScore: 0,
      pitch: 0,
      yaw: 0,
      roll: 0,
      blinkRatio: 0,
      yawnDistance: 0,
      badFrameCount: totalFrames - focusedFrames,
      blurryFrameCount: 0,
      lowLightFrameCount: 0,
      eyesClosedCount: 0,
      gazeWarningCount: _totalAlerts,
      readingEngagementRate: attentionRate.clamp(0, 100),
      readingFocusedFrames: focusedFrames,
      watchingVideoFrames: 0,
      idleDistractedFrames: totalFrames - focusedFrames,
    );
  }

  PdfReadingScoreRequest? _buildPdfScoreRequest() {
    final fileId = widget.fileData.id;
    if (fileId == null) return null;

    return PdfReadingScoreRequest(
      fileId: fileId,
      isAssessment: false,
      metrics: _pdfScoreMetrics,
    );
  }

  Future<void> _savePdfScoreAndExit(BuildContext dialogContext) async {
    final request = _buildPdfScoreRequest();
    if (request == null) {
      _showError(
        'Unable to save this reading session because its document ID is missing.',
      );
      return;
    }

    final bloc = context.read<AiAssessmentScoreBloc>();
    if (bloc.state is AiAssessmentScoreSaving) return;

    final result = bloc.stream.firstWhere(
      (state) =>
          state is AiAssessmentScoreSaveSuccess ||
          state is AiAssessmentScoreSaveFailure,
    );
    bloc.add(SaveAiAssessmentScoreRequested(request));
    final state = await result;
    if (!mounted || !dialogContext.mounted) return;

    if (state is AiAssessmentScoreSaveFailure) {
      _showError(state.message);
      return;
    }

    Navigator.of(dialogContext).pop();
    if (mounted) Navigator.of(context).pop();
  }

  void _showCompletionDialog() async {
    if (_isHandlingCompletion ||
        (_documentType == TreatmentDocumentType.pdf && !_hasReachedLastPage)) {
      return;
    }

    _isHandlingCompletion = true;
    try {
      await widget.attentionMonitor?.complete(
        totalDuration: Duration(seconds: _sessionDuration),
      );
      final metrics = _pdfScoreMetrics;

      await _notificationService?.playSessionComplete();
      await _notificationService?.playEncouragement(metrics.finalScore);
      if (!mounted) return;

      final score = metrics.finalScore.clamp(0, 100);
      final performanceLevel = score >= 90
          ? 'Excellent'
          : score >= 70
          ? 'Good'
          : score >= 50
          ? 'Fair'
          : 'Needs Improvement';
      final performanceColor = score >= 90
          ? const Color(0xFF66BB6A)
          : score >= 70
          ? const Color(0xFF42A5F5)
          : score >= 50
          ? const Color(0xFFFFA726)
          : const Color(0xFFEF5350);

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return ManagementCompletionView(
            sessionTitle: 'Reading Complete',
            completionMessage:
                'Great job completing Day ${widget.day} reading session!',
            day: widget.day,
            orderNumber: widget.fileData.orderNumber,
            completedItemLabel: 'Pages read',
            completedItemValue: _totalPages > 0 ? '$_totalPages' : 'Complete',
            completedItemIcon: Icons.menu_book_outlined,
            sessionDuration: _formatDuration(metrics.sessionDurationSeconds),
            metricsCount: metrics.sampledFrames,
            totalFrames: metrics.totalProcessedFrames,
            avgConcentration: metrics.readingEngagementRate / 10,
            faceDetectionPercentage: metrics.faceDetectionRate,
            attentionPercentage: metrics.readingEngagementRate,
            maxInattention: metrics.maximumInattentionDuration,
            attentionMetricLabel: 'Reading focus',
            fourthMetricLabel: 'Focused samples',
            fourthMetricValue: '${metrics.readingFocusedFrames}',
            fourthMetricIcon: Icons.auto_stories_outlined,
            score: score,
            performanceLevel: performanceLevel,
            performanceColor: performanceColor,
            onDone: () => _savePdfScoreAndExit(dialogContext),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to complete PDF reading session: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showError(
          'Unable to complete this reading session. Please try again.',
        );
      }
    } finally {
      _isHandlingCompletion = false;
    }
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
    _pdfController.dispose();
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
          return Stack(
            children: [
              SfPdfViewer.file(
                File(widget.localPath),
                controller: _pdfController,
                pageLayoutMode: PdfPageLayoutMode.single,
                scrollDirection: PdfScrollDirection.horizontal,
                enableDoubleTapZooming: true,
                maxZoomLevel: _maximumZoom,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                onDocumentLoaded: (details) {
                  final totalPages = details.document.pages.count;
                  setState(() {
                    _totalPages = totalPages;
                    _currentPage = totalPages > 0 ? 1 : 0;
                    _hasReachedLastPage = totalPages == 1;
                  });
                },
                onPageChanged: (details) {
                  widget.attentionMonitor?.recordContentInteraction();
                  setState(() {
                    _currentPage = details.newPageNumber;
                    if (details.isLastPage) {
                      _hasReachedLastPage = true;
                    }
                  });
                },
                onZoomLevelChanged: (details) {
                  final zoom = details.newZoomLevel
                      .clamp(_minimumZoom, _maximumZoom)
                      .toDouble();
                  if ((_zoomLevel - zoom).abs() > 0.001) {
                    setState(() => _zoomLevel = zoom);
                  }
                },
              ),
              Positioned(right: 12, bottom: 12, child: _buildZoomControls()),
            ],
          );
        },
      ),
    );
  }

  void _changeZoom(double change) {
    final newZoom = (_zoomLevel + change)
        .clamp(_minimumZoom, _maximumZoom)
        .toDouble();
    if ((newZoom - _zoomLevel).abs() <= 0.001) return;
    widget.attentionMonitor?.recordContentInteraction();
    _pdfController.zoomLevel = newZoom;
    setState(() => _zoomLevel = newZoom);
  }

  Widget _buildZoomControls() {
    final canZoomOut = _zoomLevel > _minimumZoom;
    final canZoomIn = _zoomLevel < _maximumZoom;
    final zoomPercentage = (_zoomLevel * 100).round();

    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Zoom out',
              onPressed: canZoomOut ? () => _changeZoom(-_zoomStep) : null,
              icon: const Icon(Icons.remove_rounded),
              color: const Color(0xFF111827),
              disabledColor: const Color(0xFFB8BEC7),
              iconSize: 23,
            ),
            Semantics(
              label: 'Current zoom $zoomPercentage percent',
              child: SizedBox(
                width: 50,
                child: Text(
                  '$zoomPercentage%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: canZoomIn ? () => _changeZoom(_zoomStep) : null,
              icon: const Icon(Icons.add_rounded),
              color: const Color(0xFF111827),
              disabledColor: const Color(0xFFB8BEC7),
              iconSize: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderBottomBar() {
    final pageLabel = _totalPages > 0
        ? 'Page $_currentPage of $_totalPages'
        : 'Reading document';
    final canComplete =
        _documentType == TreatmentDocumentType.docx || _hasReachedLastPage;
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
              onPressed: canComplete ? _showCompletionDialog : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF374151),
                disabledForegroundColor: const Color(0xFF9CA3AF),
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
