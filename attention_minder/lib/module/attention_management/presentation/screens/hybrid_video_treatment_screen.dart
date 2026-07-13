import 'dart:math';
import 'dart:ui' as ui;

import 'package:attention_minder/module/attention_management/presentation/screens/video_attention_monitor.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/pdf_treatment_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_treatment_screen.dart';
import 'package:attention_minder/module/attention_management/domain/temporal_attention_filter.dart';
import 'package:attention_minder/module/attention_management/domain/management_session_scorer.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart' as mp;

Widget buildVideoTreatmentScreen({
  required int day,
  required List<VideoFile> videos,
  bool isAssessment = false,
}) {
  return HybridVideoTreatmentScreen(
    day: day,
    videos: videos,
    isAssessment: isAssessment,
  );
}

/// Single construction point for on-device PDF treatment monitoring.
Widget buildPdfTreatmentScreen({
  required int day,
  required VideoFile fileData,
  required String localPath,
}) {
  return PdfTreatmentScreen(
    day: day,
    fileData: fileData,
    localPath: localPath,
    attentionMonitor: HybridMlKitAttentionMonitor(
      requireReadingPattern: true,
      readingPatternGracePeriod: const Duration(seconds: 6),
      maximumReadingPause: const Duration(seconds: 6),
    ),
  );
}

/// Experimental hybrid treatment screen.
///
/// It deliberately delegates rendering and interaction to the production
/// [VideoTreatmentScreen], injecting only a different monitoring strategy.
class HybridVideoTreatmentScreen extends StatefulWidget {
  final int day;
  final List<VideoFile> videos;
  final bool isAssessment;

  const HybridVideoTreatmentScreen({
    super.key,
    required this.day,
    required this.videos,
    this.isAssessment = false,
  });

  @override
  State<HybridVideoTreatmentScreen> createState() =>
      _HybridVideoTreatmentScreenState();
}

class _HybridVideoTreatmentScreenState
    extends State<HybridVideoTreatmentScreen> {
  late final HybridMlKitAttentionMonitor _monitor;

  @override
  void initState() {
    super.initState();
    _monitor = HybridMlKitAttentionMonitor();
  }

  @override
  Widget build(BuildContext context) {
    return VideoTreatmentScreen(
      day: widget.day,
      videos: widget.videos,
      isAssessment: widget.isAssessment,
      attentionMonitor: _monitor,
    );
  }
}

enum _AttentionState {
  focused,
  lowLight,
  faceMissing,
  eyesClosed,
  leftEyeClosed,
  rightEyeClosed,
  yawning,
  lookingLeft,
  lookingRight,
  lookingUp,
  lookingDown,
  readingNotDetected,
}

/// On-device detector and event aggregator for the backend's hybrid proposal.
///
/// Raw images and per-frame values remain on-device. The existing WebSocket is
/// used only for lifecycle messages, grouped events, and 30-second summaries.
class HybridMlKitAttentionMonitor implements VideoAttentionMonitor {
  HybridMlKitAttentionMonitor({
    this.summaryInterval = const Duration(seconds: 30),
    this.eyeOpenThreshold = 0.35,
    this.eyeBlinkThreshold = 0.55,
    this.headYawEnterThreshold = 17,
    this.headYawExitThreshold = 10,
    this.headPitchEnterThreshold = 16,
    this.headPitchExitThreshold = 10,
    this.irisGazeEnterThreshold = 0.06,
    this.irisGazeExitThreshold = 0.035,
    this.verticalIrisGazeEnterThreshold = 0.08,
    this.verticalIrisGazeExitThreshold = 0.045,
    this.minimumDirectionalDistractionDuration = const Duration(seconds: 2),
    this.irisDropoutTolerance = const Duration(milliseconds: 1250),
    this.minimumFaceMissingDuration = const Duration(seconds: 2),
    this.minimumBothEyesClosedDuration = const Duration(seconds: 2),
    this.singleEyeClosedThreshold = 0.30,
    this.singleEyeOpenThreshold = 0.65,
    this.singleEyeReopenThreshold = 0.55,
    this.minimumSingleEyeClosureDuration = const Duration(seconds: 2),
    this.lowLightEnterThreshold = 0.30,
    this.lowLightExitThreshold = 0.36,
    this.minimumLowLightDuration = const Duration(seconds: 2),
    this.mouthOpenRatioThreshold = 0.22,
    this.minimumYawnDuration = const Duration(seconds: 2),
    this.minimumIrisConfidence = 0.65,
    this.initialAlertGracePeriod = const Duration(seconds: 1),
    this.maximumDetectorObservationGap = const Duration(seconds: 5),
    this.requireReadingPattern = false,
    this.readingPatternGracePeriod = const Duration(seconds: 25),
    this.maximumReadingPause = const Duration(seconds: 18),
    bool? isIOSPlatform,
    bool? normalizeMirroredFrontCameraSemantics,
  }) : _isIOSPlatform =
           isIOSPlatform ?? defaultTargetPlatform == TargetPlatform.iOS,
       _normalizeMirroredFrontCameraSemantics =
           normalizeMirroredFrontCameraSemantics ??
           defaultTargetPlatform == TargetPlatform.iOS,
       _detector = FaceDetector(
         options: FaceDetectorOptions(
           performanceMode: FaceDetectorMode.accurate,
           enableContours: true,
           enableClassification: true,
           enableLandmarks: true,
           enableTracking: true,
         ),
       );

  static const String modelVersion =
      'attention-monitor-2.0-mlkit-mediapipe-temporal';

  final Duration summaryInterval;
  final double eyeOpenThreshold;
  final double eyeBlinkThreshold;
  final double headYawEnterThreshold;
  final double headYawExitThreshold;
  final double headPitchEnterThreshold;
  final double headPitchExitThreshold;
  final double irisGazeEnterThreshold;
  final double irisGazeExitThreshold;
  final double verticalIrisGazeEnterThreshold;
  final double verticalIrisGazeExitThreshold;
  final Duration minimumDirectionalDistractionDuration;
  final Duration irisDropoutTolerance;
  final Duration minimumFaceMissingDuration;
  final Duration minimumBothEyesClosedDuration;
  final double singleEyeClosedThreshold;
  final double singleEyeOpenThreshold;
  final double singleEyeReopenThreshold;
  final Duration minimumSingleEyeClosureDuration;
  final double lowLightEnterThreshold;
  final double lowLightExitThreshold;
  final Duration minimumLowLightDuration;
  final double mouthOpenRatioThreshold;
  final Duration minimumYawnDuration;
  final double minimumIrisConfidence;
  final Duration initialAlertGracePeriod;
  final Duration maximumDetectorObservationGap;
  final bool requireReadingPattern;
  final Duration readingPatternGracePeriod;
  final Duration maximumReadingPause;
  final bool _isIOSPlatform;
  final bool _normalizeMirroredFrontCameraSemantics;
  final FaceDetector _detector;
  mp.FaceDetectorProcessor? _meshFaceDetector;
  mp.FaceMeshProcessor? _faceMeshProcessor;
  mp.FaceMeshInferencePipeline? _faceMeshPipeline;
  mp.FaceBlendshapesProcessor? _blendshapesProcessor;

  AttentionMessageSender? _send;
  late final String _sessionId;
  final Stopwatch _observationClock = Stopwatch();
  bool _started = false;
  bool _completed = false;
  int _lastSummaryAtMs = 0;
  int _lastVideoPositionMs = 0;
  int _latestVideoPositionMs = 0;
  int _faceVisibleMs = 0;
  int _focusedMs = 0;
  int _distractedMs = 0;
  int _blinkCount = 0;
  int _longEyeClosureCount = 0;
  int _drowsinessWarningCount = 0;
  int _yawnCount = 0;
  _AttentionState _state = _AttentionState.focused;
  int _stateStartedAtMs = 0;
  bool _eyesWereClosed = false;
  int? _eyeClosureStartedAtMs;
  bool _yawnActive = false;
  _AttentionState? _directionCandidate;
  _AttentionState? _confirmedGazeDirection;
  final List<double> _irisCalibrationSamples = <double>[];
  final List<double> _verticalIrisCalibrationSamples = <double>[];
  final List<double> _headYawCalibrationSamples = <double>[];
  final List<double> _headPitchCalibrationSamples = <double>[];
  double? _irisGazeBaseline;
  double? _verticalIrisGazeBaseline;
  double? _headYawBaseline;
  double? _headPitchBaseline;
  double? _filteredIrisRatio;
  double? _filteredVerticalIrisRatio;
  int? _readingObservationStartedAtMs;
  int? _lastReadingActivityAtMs;
  int? _lastContentInteractionAtMs;
  final List<_ReadingGazePoint> _readingGazeWindow = <_ReadingGazePoint>[];
  _AttentionState? _singleEyeClosureCandidate;
  int? _singleEyeClosureCandidateStartedAtVideoMs;
  int? _lowLightCandidateStartedAtVideoMs;
  int _lowLightCandidateHeldMs = 0;
  _BrightnessSample? _latestBrightness;
  String _irisTrackingStatus = 'initializing';
  int _irisLandmarkCount = 0;
  int _meshDetectionCount = 0;
  int _processedFrameCount = 0;
  int _sampledFrameCount = 0;
  int _badFrameCount = 0;
  int _lowLightFrameCount = 0;
  int _eyesClosedFrameCount = 0;
  int _gazeWarningCount = 0;
  double _confidenceTotal = 0;
  int _confidenceSampleCount = 0;
  double _brightnessTotal = 0;
  int _brightnessSampleCount = 0;
  double _gazeQualityTotal = 0;
  int _gazeQualitySampleCount = 0;
  double _pitchTotal = 0;
  double _yawTotal = 0;
  double _rollTotal = 0;
  int _poseSampleCount = 0;
  double _mouthRatioTotal = 0;
  int _mouthRatioSampleCount = 0;
  int _faceDetectedFrameCount = 0;
  final ManagementSessionScorer _sessionScorer = ManagementSessionScorer();

  late final SustainedValueFilter<_AttentionState> _gazeAwayFilter =
      SustainedValueFilter<_AttentionState>(
        enterDuration: minimumDirectionalDistractionDuration,
        dropoutTolerance: irisDropoutTolerance,
        exitDuration: const Duration(milliseconds: 650),
        maximumObservationGap: maximumDetectorObservationGap,
      );
  late final SustainedValueFilter<bool> _faceMissingFilter =
      SustainedValueFilter<bool>(
        enterDuration: minimumFaceMissingDuration,
        dropoutTolerance: const Duration(milliseconds: 650),
        exitDuration: const Duration(milliseconds: 350),
        maximumObservationGap: maximumDetectorObservationGap,
      );
  late final SustainedValueFilter<bool> _bothEyesClosedFilter =
      SustainedValueFilter<bool>(
        enterDuration: minimumBothEyesClosedDuration,
        dropoutTolerance: const Duration(milliseconds: 750),
        exitDuration: const Duration(milliseconds: 350),
        maximumObservationGap: maximumDetectorObservationGap,
      );
  late final SustainedValueFilter<bool> _yawnFilter =
      SustainedValueFilter<bool>(
        enterDuration: minimumYawnDuration,
        dropoutTolerance: const Duration(milliseconds: 750),
        exitDuration: const Duration(milliseconds: 450),
        maximumObservationGap: maximumDetectorObservationGap,
      );

  @override
  Future<void> start({
    required AttentionMessageSender send,
    required int day,
    required bool isAssessment,
  }) async {
    _send = send;
    if (_started) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionId = _newId('session', now);
    _observationClock
      ..reset()
      ..start();
    _lastSummaryAtMs = 0;
    _stateStartedAtMs = 0;
    _started = true;

    await _initializeIrisTracking();

    _emit({
      'type': 'attention_session_started',
      'sessionId': _sessionId,
      'day': day,
      'isAssessment': isAssessment,
      'startedAtMs': now,
      'processingMode': 'on_device_hybrid',
      'modelVersion': modelVersion,
      'gazeModel': 'mediapipe-face-mesh-iris',
    });
  }

  Future<void> _initializeIrisTracking() async {
    try {
      final detector = await mp.FaceDetectorProcessor.create(
        model: mp.FaceDetectionModel.shortRange,
        delegate: mp.FaceMeshDelegate.xnnpack,
        maxResults: 1,
      );
      final mesh = await mp.FaceMeshProcessor.create(
        delegate: mp.FaceMeshDelegate.xnnpack,
        enableSmoothing: true,
        enableRoiTracking: true,
        enableIris: true,
      );
      _meshFaceDetector = detector;
      _faceMeshProcessor = mesh;
      _faceMeshPipeline = mp.FaceMeshInferencePipeline(
        detector: detector,
        mesh: mesh,
      );
      try {
        _blendshapesProcessor = await mp.FaceBlendshapesProcessor.create(
          delegate: mp.FaceMeshDelegate.xnnpack,
        );
      } catch (error) {
        // Geometric iris + ML Kit pose remain fully functional when the
        // optional trained blendshape model is unavailable.
        debugPrint('MediaPipe blendshape initialization failed: $error');
        _blendshapesProcessor = null;
      }
      _irisTrackingStatus = 'ready';
    } catch (error) {
      _irisTrackingStatus = 'initialization_failed';
      debugPrint('MediaPipe iris initialization failed: $error');
      _meshFaceDetector?.close();
      _blendshapesProcessor?.close();
      _faceMeshProcessor?.close();
      _meshFaceDetector = null;
      _faceMeshProcessor = null;
      _faceMeshPipeline = null;
      _blendshapesProcessor = null;
    }
  }

  @override
  Future<Map<String, dynamic>> analyze({
    required XFile image,
    required Duration videoPosition,
  }) async {
    final now = _observationClock.elapsedMilliseconds;
    final videoPositionMs = videoPosition.inMilliseconds;
    final sampleDuration = (videoPositionMs - _lastVideoPositionMs).clamp(
      0,
      2000,
    );
    _lastVideoPositionMs = videoPositionMs;
    _latestVideoPositionMs = videoPositionMs;

    final mlKitFacesFuture = _detector.processImage(
      InputImage.fromFilePath(image.path),
    );
    final irisSampleFuture = _analyzeIris(image);
    final faces = await mlKitFacesFuture;
    final irisSample = await irisSampleFuture;
    _processedFrameCount++;
    _sampledFrameCount++;
    final lowLightState = _confirmedLowLight(
      brightness: _latestBrightness,
      timestampMs: now,
    );
    final face = faces.isEmpty ? null : faces.first;
    final faceVisible = face != null || irisSample != null;
    final leftEye = face?.leftEyeOpenProbability;
    final rightEye = face?.rightEyeOpenProbability;
    final mlKitEyesClosed =
        face != null &&
        leftEye != null &&
        rightEye != null &&
        leftEye < eyeOpenThreshold &&
        rightEye < eyeOpenThreshold;
    // ML Kit classification can return null or stale open probabilities on
    // iOS once both eyelids cover the iris. MediaPipe's independent blink
    // coefficients keep the closed-eye alert observable in that condition.
    // Requiring both coefficients plus the sustained filter below avoids
    // treating a wink or a natural blink as an alert.
    final mediaPipeEyesClosed =
        irisSample?.blinkLeftScore != null &&
        irisSample?.blinkRightScore != null &&
        irisSample!.blinkLeftScore! >= eyeBlinkThreshold &&
        irisSample.blinkRightScore! >= eyeBlinkThreshold;
    final rawEyesClosed = mlKitEyesClosed || mediaPipeEyesClosed;
    final eyeClosureSampleReliable =
        (face != null && leftEye != null && rightEye != null) ||
        (irisSample?.blinkLeftScore != null &&
            irisSample?.blinkRightScore != null);
    final faceMissing =
        _faceMissingFilter.update(
          value: faceVisible ? null : true,
          isReliable: true,
          timestampMs: now,
        ) ==
        true;
    final eyesClosed =
        _bothEyesClosedFilter.update(
          value: rawEyesClosed ? true : null,
          isReliable: eyeClosureSampleReliable,
          timestampMs: now,
        ) ==
        true;
    final singleEyeClosureState = face == null || rawEyesClosed
        ? _resetSingleEyeClosureCandidate()
        : _confirmedSingleEyeClosure(
            leftEyeOpenProbability: leftEye,
            rightEyeOpenProbability: rightEye,
            timestampMs: now,
          );
    final rawYaw = face?.headEulerAngleY ?? 0;
    final yaw = _normalizeMirroredFrontCameraSemantics ? -rawYaw : rawYaw;
    final pitch = face?.headEulerAngleX ?? 0;
    final roll = face?.headEulerAngleZ ?? 0;
    // ML Kit on iOS can omit inner-lip contours for an otherwise valid face.
    // MediaPipe observes the same expression, so use its normalized jaw-open
    // coefficient when the contour measurement is unavailable.
    final mlKitMouthOpenRatio = face == null ? null : _mouthOpenRatio(face);
    final mouthOpenRatio = mlKitMouthOpenRatio ?? irisSample?.jawOpenScore;
    final yawning = _updateYawnState(
      mouthOpenRatio: mouthOpenRatio,
      nowMs: now,
    );
    final gazeOffset = _processIrisSample(
      irisSample: irisSample,
      headYaw: yaw,
      headPitch: pitch,
      allowCalibration:
          face != null &&
          leftEye != null &&
          rightEye != null &&
          leftEye >= singleEyeReopenThreshold &&
          rightEye >= singleEyeReopenThreshold &&
          yaw.abs() <= 7 &&
          // A portrait iPhone is commonly held below eye level. ML Kit then
          // reports a non-zero neutral pitch even while the user is looking
          // correctly at the screen. Permit that normal mounting offset to
          // seed the personalized iris baseline; Android keeps its proven,
          // tighter calibration window.
          pitch.abs() <= (_isIOSPlatform ? 18 : 7) &&
          roll.abs() <= 10,
    );
    final irisDirection = gazeOffset == null
        ? null
        : _normalizeHorizontalDirection(_rawDirectionFromIris(gazeOffset));
    final blendshapeDirection = _normalizeHorizontalDirection(
      _rawDirectionFromBlendshapes(irisSample),
    );
    final eyeDirection = _fusedEyeDirection(
      irisDirection: irisDirection,
      blendshapeDirection: blendshapeDirection,
    );
    _updateHeadPoseCalibration(
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      eyesReliablyOpen:
          leftEye != null &&
          rightEye != null &&
          leftEye >= singleEyeReopenThreshold &&
          rightEye >= singleEyeReopenThreshold,
      eyeDirection: eyeDirection,
    );
    final relativeYaw = yaw - (_headYawBaseline ?? 0);
    final relativePitch = pitch - (_headPitchBaseline ?? 0);
    final headDirection = _headYawBaseline == null || _headPitchBaseline == null
        ? null
        : _rawDirectionFromHeadPose(yaw: relativeYaw, pitch: relativePitch);
    final rawDirection = rawEyesClosed
        ? null
        : _fusedDirection(
            irisDirection: eyeDirection,
            headDirection: headDirection,
          );
    final directionSampleReliable =
        !rawEyesClosed && (gazeOffset != null || headDirection != null);
    final directionalState =
        lowLightState != null ||
            faceMissing ||
            eyesClosed ||
            singleEyeClosureState != null ||
            yawning
        ? _resetDirectionCandidate()
        : _confirmedDirection(
            direction: rawDirection,
            visualAwayEvidence: rawDirection != null || face == null,
            sampleReliable: directionSampleReliable || face == null,
            timestampMs: now,
          );

    var nextState =
        lowLightState ??
        (faceMissing
            ? _AttentionState.faceMissing
            : eyesClosed
            ? _AttentionState.eyesClosed
            : singleEyeClosureState ??
                  (yawning
                      ? _AttentionState.yawning
                      : directionalState ?? _AttentionState.focused));

    if (requireReadingPattern) {
      final readingNotDetected = _updateReadingPattern(
        gazeOffset: gazeOffset,
        timestampMs: now,
        isEligible:
            nextState == _AttentionState.focused &&
            faceVisible &&
            !rawEyesClosed,
      );
      if (nextState == _AttentionState.focused && readingNotDetected) {
        nextState = _AttentionState.readingNotDetected;
      }
    }

    // Do not emit warnings while the camera exposure, face models, and
    // per-user gaze baselines are warming up. Reset pending evidence so a
    // warning cannot become active immediately after the grace window.
    final warmingUp = now < initialAlertGracePeriod.inMilliseconds;
    if (warmingUp) {
      _faceMissingFilter.reset();
      _bothEyesClosedFilter.reset();
      _yawnFilter.reset();
      _resetDirectionCandidate();
      _resetSingleEyeClosureCandidate();
      _lowLightCandidateStartedAtVideoMs = null;
      _lowLightCandidateHeldMs = 0;
      nextState = _AttentionState.focused;
    }

    _recordFrameMetrics(
      face: face,
      faceVisible: faceVisible,
      irisSample: irisSample,
      gazeOffset: gazeOffset,
      brightness: _latestBrightness,
      pitch: pitch,
      yaw: yaw,
      roll: roll,
      mouthOpenRatio: mouthOpenRatio,
      eyesClosed: eyesClosed,
      lowLight: lowLightState != null,
      state: nextState,
    );
    _sessionScorer.recordFrame(
      attentive: nextState == _AttentionState.focused,
      timestampMs: now,
    );

    if (faceVisible) _faceVisibleMs += sampleDuration;
    if (nextState == _AttentionState.focused) {
      _focusedMs += sampleDuration;
    } else {
      _distractedMs += sampleDuration;
    }

    _trackBlink(eyesClosed: rawEyesClosed, nowMs: now);
    if (nextState != _state) {
      if (_isDirectionalState(nextState)) _gazeWarningCount++;
      _closeCurrentEvent(videoPositionMs);
      _state = nextState;
      _stateStartedAtMs = videoPositionMs;
    }

    if (now - _lastSummaryAtMs >= summaryInterval.inMilliseconds) {
      _emitSummary(now);
    }

    final attentive = nextState == _AttentionState.focused;
    // Alert recovery must describe the current frame, not the temporally held
    // warning state. The hold is useful for preventing warning flicker during
    // playback, but it must not keep the Continue button locked after the user
    // has visibly corrected every issue.
    // Warning hysteresis uses the smaller exit thresholds so alerts do not
    // flicker. Recovery deliberately uses the normal entry boundaries: once
    // the user's current pose and gaze are back inside the valid attention
    // region, the dialog should unlock without requiring exaggerated movement.
    final calibratedIrisCentered =
        gazeOffset != null &&
        gazeOffset.horizontal.abs() < irisGazeEnterThreshold &&
        gazeOffset.vertical.abs() < verticalIrisGazeEnterThreshold;
    // A neutral raw iris position is a safe fallback when a personalized
    // baseline drifted during the distraction that caused the alert.
    final neutralIrisGeometry =
        irisSample != null &&
        irisSample.confidence >= 0.65 &&
        irisSample.horizontalRatio >= 0.34 &&
        irisSample.horizontalRatio <= 0.66 &&
        irisSample.verticalRatio >= 0.25 &&
        irisSample.verticalRatio <= 0.75;
    final irisCenteredForRecovery =
        calibratedIrisCentered || neutralIrisGeometry;

    final relativeHeadCentered =
        _headYawBaseline != null &&
        _headPitchBaseline != null &&
        relativeYaw.abs() < headYawEnterThreshold &&
        relativePitch.abs() < headPitchEnterThreshold;
    // ML Kit's absolute neutral pose prevents a stale calibration baseline
    // from locking the recovery UI indefinitely.
    final absoluteHeadCentered =
        yaw.abs() < headYawExitThreshold &&
        pitch.abs() < headPitchExitThreshold &&
        roll.abs() < 12;
    final headCenteredForRecovery =
        relativeHeadCentered || absoluteHeadCentered;

    // Either reliable eye geometry or a clearly centered head pose is enough
    // to confirm recovery. Requiring both made one noisy model a permanent
    // veto even when every visible attention condition had been corrected.
    final gazeCenteredForRecovery =
        irisCenteredForRecovery || headCenteredForRecovery;
    final readyToContinue =
        faceVisible &&
        lowLightState == null &&
        !rawEyesClosed &&
        singleEyeClosureState == null &&
        !yawning &&
        gazeCenteredForRecovery;
    final score = _attentionScore;
    final message = _messageFor(nextState);
    final recommendations = attentive
        ? <String>[]
        : [_recommendationFor(nextState)];
    final elapsedSeconds = videoPositionMs / 1000;

    return {
      'face_detected': faceVisible,
      'validation_passed': attentive,
      'ready_to_continue': readyToContinue,
      'readiness': {
        'face_visible': faceVisible,
        'lighting_ok': lowLightState == null,
        'eyes_open': !rawEyesClosed && singleEyeClosureState == null,
        'not_yawning': !yawning,
        'iris_centered': irisCenteredForRecovery,
        'head_centered': headCenteredForRecovery,
        'gaze_centered': gazeCenteredForRecovery,
      },
      'concentration_score': (score / 10).round().clamp(0, 10),
      'message': message,
      'recommendations': recommendations,
      'analysis': {
        'low_light': lowLightState != null,
        'not_drowsy': !eyesClosed,
        'yawning': yawning,
        'eyes_closed': eyesClosed,
        'left_eye_closed':
            singleEyeClosureState == _AttentionState.leftEyeClosed,
        'right_eye_closed':
            singleEyeClosureState == _AttentionState.rightEyeClosed,
        'left_eye_open_probability': leftEye,
        'right_eye_open_probability': rightEye,
        'reading_pattern_required': requireReadingPattern,
        'reading_pattern_detected':
            !requireReadingPattern ||
            nextState != _AttentionState.readingNotDetected,
      },
      'engagement': {
        'video_attentive': attentive,
        'state': attentive ? 'focused' : _eventType(nextState).toLowerCase(),
        'inattention_duration': _distractedMs / 1000,
      },
      'metrics': {
        'raw_concentration_score': score / 10,
        'left_eye_open_probability': leftEye,
        'right_eye_open_probability': rightEye,
        'yaw': yaw,
        'mouth_open_ratio': mouthOpenRatio,
        'mlkit_mouth_open_ratio': mlKitMouthOpenRatio,
        'mediapipe_jaw_open_score': irisSample?.jawOpenScore,
        'mouth_open_ratio_threshold': mouthOpenRatioThreshold,
        'mean_luminance': _latestBrightness?.meanLuminance,
        'dark_pixel_ratio': _latestBrightness?.darkPixelRatio,
        'low_light_enter_threshold': lowLightEnterThreshold,
        'low_light_exit_threshold': lowLightExitThreshold,
        'low_light_hold_threshold_ms': minimumLowLightDuration.inMilliseconds,
        'low_light_candidate_active':
            _lowLightCandidateStartedAtVideoMs != null,
        'low_light_candidate_held_ms': _lowLightCandidateHeldMs,
        'gaze_direction': _gazeDirection(nextState),
        'gaze_estimation_method': eyeDirection != null && headDirection != null
            ? 'fused_eye_head_pose'
            : blendshapeDirection != null
            ? 'mediapipe_blendshape_iris'
            : irisDirection != null
            ? 'mediapipe_iris_geometry'
            : 'head_pose_fallback',
        'iris_horizontal_ratio': irisSample?.horizontalRatio,
        'left_iris_horizontal_ratio': irisSample?.leftEyeRatio,
        'right_iris_horizontal_ratio': irisSample?.rightEyeRatio,
        'iris_vertical_ratio': irisSample?.verticalRatio,
        'left_iris_vertical_ratio': irisSample?.leftEyeVerticalRatio,
        'right_iris_vertical_ratio': irisSample?.rightEyeVerticalRatio,
        'iris_eye_ratio_difference': irisSample?.eyeRatioDifference,
        'vertical_iris_eye_ratio_difference':
            irisSample?.verticalEyeRatioDifference,
        'iris_confidence': irisSample?.confidence,
        'minimum_iris_confidence': minimumIrisConfidence,
        'warming_up': warmingUp,
        'mlkit_face_detected': face != null,
        'mediapipe_face_detected': irisSample != null,
        'blendshape_gaze_left': irisSample?.blendshapeLeft,
        'blendshape_gaze_right': irisSample?.blendshapeRight,
        'blendshape_gaze_up': irisSample?.blendshapeUp,
        'blendshape_gaze_down': irisSample?.blendshapeDown,
        'iris_tracking_status': _irisTrackingStatus,
        'iris_landmark_count': _irisLandmarkCount,
        'mesh_detection_count': _meshDetectionCount,
        'iris_gaze_baseline': _irisGazeBaseline,
        'vertical_iris_gaze_baseline': _verticalIrisGazeBaseline,
        'iris_filtered_ratio': _filteredIrisRatio,
        'vertical_iris_filtered_ratio': _filteredVerticalIrisRatio,
        'iris_calibration_samples': _irisCalibrationSamples.length,
        'vertical_iris_calibration_samples':
            _verticalIrisCalibrationSamples.length,
        'iris_gaze_offset': gazeOffset?.horizontal,
        'vertical_iris_gaze_offset': gazeOffset?.vertical,
        'iris_gaze_enter_threshold': irisGazeEnterThreshold,
        'iris_gaze_exit_threshold': irisGazeExitThreshold,
        'vertical_iris_gaze_enter_threshold': verticalIrisGazeEnterThreshold,
        'vertical_iris_gaze_exit_threshold': verticalIrisGazeExitThreshold,
        'head_yaw_enter_threshold': headYawEnterThreshold,
        'head_yaw_exit_threshold': headYawExitThreshold,
        'head_yaw_baseline': _headYawBaseline,
        'head_pitch_baseline': _headPitchBaseline,
        'relative_head_yaw': relativeYaw,
        'relative_head_pitch': relativePitch,
        'head_pitch_enter_threshold': headPitchEnterThreshold,
        'head_pitch_exit_threshold': headPitchExitThreshold,
        'direction_hold_threshold_ms':
            minimumDirectionalDistractionDuration.inMilliseconds,
        'maximum_detector_observation_gap_ms':
            maximumDetectorObservationGap.inMilliseconds,
        'reading_pattern_grace_ms': readingPatternGracePeriod.inMilliseconds,
        'maximum_reading_pause_ms': maximumReadingPause.inMilliseconds,
        'last_reading_activity_ms': _lastReadingActivityAtMs,
        'last_content_interaction_ms': _lastContentInteractionAtMs,
        'direction_candidate': _directionCandidate == null
            ? null
            : _gazeDirection(_directionCandidate!),
        'single_eye_closure_candidate': _singleEyeClosureCandidate == null
            ? null
            : _eventType(_singleEyeClosureCandidate!).toLowerCase(),
        'single_eye_closure_hold_threshold_ms':
            minimumSingleEyeClosureDuration.inMilliseconds,
        'faces_count': faces.length,
        'elapsed_seconds': elapsedSeconds,
        'processing_mode': 'on_device_hybrid',
        'model_version': modelVersion,
      },
      'ui_message': {
        'severity': attentive ? 'info' : 'warning',
        'reason': _eventType(nextState).toLowerCase(),
        'message': message,
      },
    };
  }

  void _recordFrameMetrics({
    required Face? face,
    required bool faceVisible,
    required _IrisGazeSample? irisSample,
    required _IrisGazeOffset? gazeOffset,
    required _BrightnessSample? brightness,
    required double pitch,
    required double yaw,
    required double roll,
    required double? mouthOpenRatio,
    required bool eyesClosed,
    required bool lowLight,
    required _AttentionState state,
  }) {
    if (state != _AttentionState.focused) _badFrameCount++;
    if (lowLight) _lowLightFrameCount++;
    if (eyesClosed) _eyesClosedFrameCount++;
    if (faceVisible) _faceDetectedFrameCount++;

    if (face != null) {
      _pitchTotal += pitch;
      _yawTotal += yaw;
      _rollTotal += roll;
      _poseSampleCount++;
    }
    if (irisSample != null) {
      _confidenceTotal += irisSample.confidence.clamp(0.0, 1.0);
      _confidenceSampleCount++;
    }
    if (brightness != null) {
      _brightnessTotal += brightness.meanLuminance.clamp(0.0, 1.0) * 100;
      _brightnessSampleCount++;
    }
    if (mouthOpenRatio != null) {
      _mouthRatioTotal += mouthOpenRatio;
      _mouthRatioSampleCount++;
    }
    if (gazeOffset != null) {
      final horizontal = gazeOffset.horizontal.abs() / irisGazeEnterThreshold;
      final vertical =
          gazeOffset.vertical.abs() / verticalIrisGazeEnterThreshold;
      final deviation = max(horizontal, vertical).clamp(0.0, 1.0);
      _gazeQualityTotal += 1 - deviation;
      _gazeQualitySampleCount++;
    }
  }

  double _average(double total, int count) => count == 0 ? 0 : total / count;

  @override
  AttentionSessionMetrics get sessionMetrics {
    final frameCount = max(_sampledFrameCount, 1);
    final score = _sessionScorer.finalScore;
    return AttentionSessionMetrics(
      finalScore: score,
      attentionEngagementRate: _sessionScorer.attentionEngagementRate,
      faceDetectionRate: (_faceDetectedFrameCount / frameCount) * 100,
      averageConfidence: _average(_confidenceTotal, _confidenceSampleCount),
      totalProcessedFrames: _processedFrameCount,
      sampledFrames: _sampledFrameCount,
      sessionDurationSeconds: (_latestVideoPositionMs / 1000).round(),
      inattentionDuration: _sessionScorer.inattentionDurationSeconds,
      maximumInattentionDuration:
          _sessionScorer.maximumInattentionDurationSeconds,
      gazeRatioAverage: _average(_gazeQualityTotal, _gazeQualitySampleCount),
      drowsyState: _eyesClosedFrameCount / frameCount,
      brightnessScore: _average(_brightnessTotal, _brightnessSampleCount),
      pitch: _average(_pitchTotal, _poseSampleCount),
      yaw: _average(_yawTotal, _poseSampleCount),
      roll: _average(_rollTotal, _poseSampleCount),
      blinkRatio: _blinkCount / frameCount,
      yawnDistance: _average(_mouthRatioTotal, _mouthRatioSampleCount),
      badFrameCount: _badFrameCount,
      blurryFrameCount: 0,
      lowLightFrameCount: _lowLightFrameCount,
      eyesClosedCount: _eyesClosedFrameCount,
      gazeWarningCount: _gazeWarningCount,
    );
  }

  void _trackBlink({required bool eyesClosed, required int nowMs}) {
    if (eyesClosed && !_eyesWereClosed) {
      _eyeClosureStartedAtMs = nowMs;
    } else if (!eyesClosed && _eyesWereClosed) {
      final closureDuration = nowMs - (_eyeClosureStartedAtMs ?? nowMs);
      if (closureDuration >= 100 && closureDuration < 1500) {
        _blinkCount++;
      } else if (closureDuration >= 1500) {
        _longEyeClosureCount++;
        _drowsinessWarningCount++;
      }
      _eyeClosureStartedAtMs = null;
    }
    _eyesWereClosed = eyesClosed;
  }

  _AttentionState? _confirmedSingleEyeClosure({
    required double? leftEyeOpenProbability,
    required double? rightEyeOpenProbability,
    required int timestampMs,
  }) {
    if (leftEyeOpenProbability == null || rightEyeOpenProbability == null) {
      return _resetSingleEyeClosureCandidate();
    }

    _AttentionState? detectedSide;
    // ML Kit on iOS already reports anatomical eye labels for mirrored
    // front-camera frames. Android's sensor-oriented stream requires the
    // opposite-side mapping retained by the legacy path.
    final leftProbability = _normalizeMirroredFrontCameraSemantics
        ? leftEyeOpenProbability
        : rightEyeOpenProbability;
    final rightProbability = _normalizeMirroredFrontCameraSemantics
        ? rightEyeOpenProbability
        : leftEyeOpenProbability;
    if (_state == _AttentionState.leftEyeClosed &&
        leftProbability < singleEyeReopenThreshold &&
        rightProbability >= singleEyeReopenThreshold) {
      detectedSide = _AttentionState.leftEyeClosed;
    } else if (_state == _AttentionState.rightEyeClosed &&
        rightProbability < singleEyeReopenThreshold &&
        leftProbability >= singleEyeReopenThreshold) {
      detectedSide = _AttentionState.rightEyeClosed;
    } else if (leftProbability <= singleEyeClosedThreshold &&
        rightProbability >= singleEyeOpenThreshold) {
      detectedSide = _AttentionState.leftEyeClosed;
    } else if (rightProbability <= singleEyeClosedThreshold &&
        leftProbability >= singleEyeOpenThreshold) {
      detectedSide = _AttentionState.rightEyeClosed;
    }

    if (detectedSide == null) return _resetSingleEyeClosureCandidate();
    if (_state == detectedSide) return detectedSide;

    if (_singleEyeClosureCandidate != detectedSide) {
      _singleEyeClosureCandidate = detectedSide;
      _singleEyeClosureCandidateStartedAtVideoMs = timestampMs;
      return null;
    }

    final heldFor =
        timestampMs -
        (_singleEyeClosureCandidateStartedAtVideoMs ?? timestampMs);
    if (heldFor >= minimumSingleEyeClosureDuration.inMilliseconds) {
      return detectedSide;
    }
    return null;
  }

  _AttentionState? _resetSingleEyeClosureCandidate() {
    _singleEyeClosureCandidate = null;
    _singleEyeClosureCandidateStartedAtVideoMs = null;
    return null;
  }

  _AttentionState? _confirmedLowLight({
    required _BrightnessSample? brightness,
    required int timestampMs,
  }) {
    if (brightness == null) {
      _lowLightCandidateStartedAtVideoMs = null;
      _lowLightCandidateHeldMs = 0;
      return null;
    }

    final alreadyConfirmed = _state == _AttentionState.lowLight;
    final tooDark = alreadyConfirmed
        ? brightness.meanLuminance < lowLightExitThreshold ||
              brightness.darkPixelRatio > 0.45
        : brightness.meanLuminance <= lowLightEnterThreshold ||
              brightness.darkPixelRatio >= 0.58;
    if (!tooDark) {
      _lowLightCandidateStartedAtVideoMs = null;
      _lowLightCandidateHeldMs = 0;
      return null;
    }
    if (alreadyConfirmed) return _AttentionState.lowLight;

    _lowLightCandidateStartedAtVideoMs ??= timestampMs;
    _lowLightCandidateHeldMs =
        timestampMs - _lowLightCandidateStartedAtVideoMs!;
    return _lowLightCandidateHeldMs >= minimumLowLightDuration.inMilliseconds
        ? _AttentionState.lowLight
        : null;
  }

  _BrightnessSample _measureBrightness({
    required Uint8List pixels,
    required int width,
    required int height,
  }) {
    final startX = (width * 0.10).round();
    final endX = (width * 0.90).round();
    final startY = (height * 0.10).round();
    final endY = (height * 0.90).round();
    const sampleStep = 6;
    var luminanceSum = 0.0;
    var darkPixels = 0;
    var sampleCount = 0;

    for (var y = startY; y < endY; y += sampleStep) {
      for (var x = startX; x < endX; x += sampleStep) {
        final offset = (y * width + x) * 4;
        if (offset + 2 >= pixels.length) continue;
        final luminance =
            (0.2126 * pixels[offset] +
                0.7152 * pixels[offset + 1] +
                0.0722 * pixels[offset + 2]) /
            255;
        luminanceSum += luminance;
        if (luminance < 0.22) darkPixels++;
        sampleCount++;
      }
    }

    if (sampleCount == 0) {
      return const _BrightnessSample(meanLuminance: 0, darkPixelRatio: 1);
    }
    return _BrightnessSample(
      meanLuminance: luminanceSum / sampleCount,
      darkPixelRatio: darkPixels / sampleCount,
    );
  }

  Future<_IrisGazeSample?> _analyzeIris(XFile imageFile) async {
    _latestBrightness = null;
    ui.Codec? codec;
    ui.Image? decodedImage;
    try {
      final encodedBytes = await imageFile.readAsBytes();
      codec = await ui.instantiateImageCodec(encodedBytes);
      final frame = await codec.getNextFrame();
      decodedImage = frame.image;
      final byteData = await decodedImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return null;

      final pixels = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      _latestBrightness = _measureBrightness(
        pixels: pixels,
        width: decodedImage.width,
        height: decodedImage.height,
      );
      final pipeline = _faceMeshPipeline;
      if (pipeline == null) {
        _irisTrackingStatus = 'pipeline_unavailable';
        return null;
      }

      final input = mp.FaceMeshImage(
        pixels: pixels,
        width: decodedImage.width,
        height: decodedImage.height,
        pixelFormat: mp.FaceMeshPixelFormat.rgba,
      );
      final inference = pipeline.process(input);
      final mesh = inference.meshResult;
      _meshDetectionCount = inference.detectionResult?.detections.length ?? 0;
      _irisLandmarkCount = mesh?.landmarks.length ?? 0;
      if (mesh == null) {
        _irisTrackingStatus = 'face_mesh_not_detected';
        return null;
      }
      if (mesh.landmarks.length < 478) {
        _irisTrackingStatus = 'iris_landmarks_unavailable';
        return null;
      }
      _irisTrackingStatus = 'tracking';

      Map<mp.FaceBlendshape, double>? blendshapes;
      try {
        blendshapes = _blendshapesProcessor?.process(mesh);
      } catch (error) {
        debugPrint('MediaPipe blendshape inference failed: $error');
      }

      final landmarks = mesh.landmarks;
      final rightRatio = _irisRatioWithinEye(
        iris: landmarks[468],
        cornerA: landmarks[33],
        cornerB: landmarks[133],
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );
      final leftRatio = _irisRatioWithinEye(
        iris: landmarks[473],
        cornerA: landmarks[362],
        cornerB: landmarks[263],
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );
      final rightVerticalRatio = _irisRatioBetweenLids(
        iris: landmarks[468],
        upperLid: landmarks[159],
        lowerLid: landmarks[145],
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );
      final leftVerticalRatio = _irisRatioBetweenLids(
        iris: landmarks[473],
        upperLid: landmarks[386],
        lowerLid: landmarks[374],
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
      );
      if (rightRatio == null ||
          leftRatio == null ||
          rightVerticalRatio == null ||
          leftVerticalRatio == null) {
        return null;
      }
      final eyeRatioDifference = (rightRatio - leftRatio).abs();
      final verticalEyeRatioDifference =
          (rightVerticalRatio - leftVerticalRatio).abs();
      final strongestTrainedGaze = <double>[
        blendshapes?[mp.FaceBlendshape.eyeLookDownLeft] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookDownRight] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookUpLeft] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookUpRight] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookInLeft] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookInRight] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookOutLeft] ?? 0,
        blendshapes?[mp.FaceBlendshape.eyeLookOutRight] ?? 0,
      ].reduce(max);
      // Large eye-to-eye differences are common at an extreme side gaze when
      // one iris is partly occluded. Reject only clearly implausible samples;
      // the temporal filter handles ordinary landmark noise.
      if (((eyeRatioDifference > 0.30 || verticalEyeRatioDifference > 0.32) &&
              strongestTrainedGaze < 0.28) ||
          mesh.score < 0.45) {
        _irisTrackingStatus = 'low_quality_iris_sample';
        return null;
      }
      return _IrisGazeSample(
        horizontalRatio: (rightRatio + leftRatio) / 2,
        verticalRatio: (rightVerticalRatio + leftVerticalRatio) / 2,
        leftEyeRatio: leftRatio,
        rightEyeRatio: rightRatio,
        leftEyeVerticalRatio: leftVerticalRatio,
        rightEyeVerticalRatio: rightVerticalRatio,
        confidence: mesh.score,
        blendshapeLeft: _pairedBlendshapeScore(
          blendshapes,
          mp.FaceBlendshape.eyeLookOutLeft,
          mp.FaceBlendshape.eyeLookInRight,
        ),
        blendshapeRight: _pairedBlendshapeScore(
          blendshapes,
          mp.FaceBlendshape.eyeLookInLeft,
          mp.FaceBlendshape.eyeLookOutRight,
        ),
        blendshapeUp: _pairedBlendshapeScore(
          blendshapes,
          mp.FaceBlendshape.eyeLookUpLeft,
          mp.FaceBlendshape.eyeLookUpRight,
        ),
        blendshapeDown: _pairedBlendshapeScore(
          blendshapes,
          mp.FaceBlendshape.eyeLookDownLeft,
          mp.FaceBlendshape.eyeLookDownRight,
        ),
        blinkLeftScore: blendshapes?[mp.FaceBlendshape.eyeBlinkLeft],
        blinkRightScore: blendshapes?[mp.FaceBlendshape.eyeBlinkRight],
        jawOpenScore: blendshapes?[mp.FaceBlendshape.jawOpen],
      );
    } catch (error) {
      _irisTrackingStatus = 'inference_failed';
      debugPrint('MediaPipe iris inference failed: $error');
      return null;
    } finally {
      decodedImage?.dispose();
      codec?.dispose();
    }
  }

  double? _pairedBlendshapeScore(
    Map<mp.FaceBlendshape, double>? scores,
    mp.FaceBlendshape first,
    mp.FaceBlendshape second,
  ) {
    final firstScore = scores?[first];
    final secondScore = scores?[second];
    if (firstScore == null || secondScore == null) return null;
    final strongerEye = max(firstScore, secondScore);
    final weakerEye = min(firstScore, secondScore);
    return (strongerEye * 0.65 + weakerEye * 0.35).clamp(0.0, 1.0);
  }

  double? _irisRatioWithinEye({
    required mp.FaceMeshLandmark iris,
    required mp.FaceMeshLandmark cornerA,
    required mp.FaceMeshLandmark cornerB,
    required int imageWidth,
    required int imageHeight,
  }) {
    final start = cornerA.x <= cornerB.x ? cornerA : cornerB;
    final end = cornerA.x <= cornerB.x ? cornerB : cornerA;
    return _projectedLandmarkRatio(
      point: iris,
      start: start,
      end: end,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  double? _irisRatioBetweenLids({
    required mp.FaceMeshLandmark iris,
    required mp.FaceMeshLandmark upperLid,
    required mp.FaceMeshLandmark lowerLid,
    required int imageWidth,
    required int imageHeight,
  }) => _projectedLandmarkRatio(
    point: iris,
    start: upperLid,
    end: lowerLid,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );

  double? _projectedLandmarkRatio({
    required mp.FaceMeshLandmark point,
    required mp.FaceMeshLandmark start,
    required mp.FaceMeshLandmark end,
    required int imageWidth,
    required int imageHeight,
  }) {
    final axisX = (end.x - start.x) * imageWidth;
    final axisY = (end.y - start.y) * imageHeight;
    final axisLengthSquared = axisX * axisX + axisY * axisY;
    if (axisLengthSquared < 0.000025) return null;

    final pointX = (point.x - start.x) * imageWidth;
    final pointY = (point.y - start.y) * imageHeight;
    final ratio = (pointX * axisX + pointY * axisY) / axisLengthSquared;
    if (!ratio.isFinite || ratio < -0.1 || ratio > 1.1) return null;
    return ratio.clamp(0.0, 1.0);
  }

  _IrisGazeOffset? _processIrisSample({
    required _IrisGazeSample? irisSample,
    required double headYaw,
    required double headPitch,
    required bool allowCalibration,
  }) {
    if (irisSample == null ||
        irisSample.confidence < minimumIrisConfidence ||
        headYaw.abs() > 28 ||
        headPitch.abs() > 25) {
      return null;
    }

    if (_irisGazeBaseline == null || _verticalIrisGazeBaseline == null) {
      final plausibleCenter =
          irisSample.horizontalRatio >= 0.30 &&
          irisSample.horizontalRatio <= 0.70 &&
          irisSample.verticalRatio >= 0.20 &&
          irisSample.verticalRatio <= 0.80;
      if (allowCalibration &&
          plausibleCenter &&
          irisSample.confidence >= 0.65 &&
          _directionCandidate == null &&
          !_isDirectionalState(_state)) {
        _irisCalibrationSamples.add(irisSample.horizontalRatio);
        _verticalIrisCalibrationSamples.add(irisSample.verticalRatio);
        if (_irisCalibrationSamples.length >= 6) {
          final horizontal = List<double>.of(_irisCalibrationSamples)..sort();
          final vertical = List<double>.of(_verticalIrisCalibrationSamples)
            ..sort();
          _irisGazeBaseline = horizontal[horizontal.length ~/ 2];
          _verticalIrisGazeBaseline = vertical[vertical.length ~/ 2];
          _filteredIrisRatio = _irisGazeBaseline;
          _filteredVerticalIrisRatio = _verticalIrisGazeBaseline;
        }
      }
      if (_irisGazeBaseline == null || _verticalIrisGazeBaseline == null) {
        // Never infer inattention from an assumed 0.5 center. Neutral iris
        // geometry varies materially by eye shape, camera angle, and device.
        // Head-pose detection remains active while these centered samples are
        // collected, and iris warnings begin only after calibration succeeds.
        return null;
      }
    }

    // Fast attack avoids adding several seconds of latency before the temporal
    // hold even begins; temporal confirmation below provides the noise filter.
    const smoothingFactor = 0.68;
    _filteredIrisRatio = _filteredIrisRatio == null
        ? irisSample.horizontalRatio
        : _filteredIrisRatio! * (1 - smoothingFactor) +
              irisSample.horizontalRatio * smoothingFactor;
    _filteredVerticalIrisRatio = _filteredVerticalIrisRatio == null
        ? irisSample.verticalRatio
        : _filteredVerticalIrisRatio! * (1 - smoothingFactor) +
              irisSample.verticalRatio * smoothingFactor;

    var horizontalOffset = _filteredIrisRatio! - _irisGazeBaseline!;
    var verticalOffset =
        _filteredVerticalIrisRatio! - _verticalIrisGazeBaseline!;
    final canAdaptBaseline =
        horizontalOffset.abs() <= irisGazeExitThreshold &&
        verticalOffset.abs() <= verticalIrisGazeExitThreshold &&
        _directionCandidate == null &&
        !_isDirectionalState(_state);
    if (canAdaptBaseline) {
      const baselineLearningRate = 0.025;
      _irisGazeBaseline =
          _irisGazeBaseline! + horizontalOffset * baselineLearningRate;
      _verticalIrisGazeBaseline =
          _verticalIrisGazeBaseline! + verticalOffset * baselineLearningRate;
      horizontalOffset = _filteredIrisRatio! - _irisGazeBaseline!;
      verticalOffset = _filteredVerticalIrisRatio! - _verticalIrisGazeBaseline!;
    }
    return _IrisGazeOffset(
      horizontal: horizontalOffset,
      vertical: verticalOffset,
    );
  }

  bool _updateReadingPattern({
    required _IrisGazeOffset? gazeOffset,
    required int timestampMs,
    required bool isEligible,
  }) {
    if (!isEligible) {
      // Do not count time spent correcting another attention issue as
      // reading inactivity. Reading evaluation resumes from a clean sample.
      _lastReadingActivityAtMs = timestampMs;
      _readingGazeWindow.clear();
      return false;
    }

    if (gazeOffset == null) {
      // Reading cannot be classified before personalized iris calibration.
      return false;
    }

    _readingObservationStartedAtMs ??= timestampMs;
    _lastReadingActivityAtMs ??= timestampMs;

    _readingGazeWindow.add(
      _ReadingGazePoint(
        timestampMs: timestampMs,
        horizontal: gazeOffset.horizontal,
        vertical: gazeOffset.vertical,
      ),
    );
    final windowStart = timestampMs - const Duration(seconds: 6).inMilliseconds;
    _readingGazeWindow.removeWhere(
      (sample) => sample.timestampMs < windowStart,
    );

    if (_readingGazeWindow.length >= 5) {
      var minimumHorizontal = _readingGazeWindow.first.horizontal;
      var maximumHorizontal = minimumHorizontal;
      var minimumVertical = _readingGazeWindow.first.vertical;
      var maximumVertical = minimumVertical;
      var horizontalTravel = 0.0;
      var meaningfulSteps = 0;
      var currentDirectionalTravel = 0.0;
      var longestDirectionalTravel = 0.0;
      var previousDirection = 0;
      final stepSizes = <double>[];

      for (var index = 1; index < _readingGazeWindow.length; index++) {
        final current = _readingGazeWindow[index];
        final previous = _readingGazeWindow[index - 1];
        minimumHorizontal = min(minimumHorizontal, current.horizontal);
        maximumHorizontal = max(maximumHorizontal, current.horizontal);
        minimumVertical = min(minimumVertical, current.vertical);
        maximumVertical = max(maximumVertical, current.vertical);
        final step = (current.horizontal - previous.horizontal).abs();
        stepSizes.add(step);
        if (step >= 0.0045) {
          horizontalTravel += step;
          meaningfulSteps++;
          final direction = current.horizontal > previous.horizontal ? 1 : -1;
          if (direction == previousDirection || previousDirection == 0) {
            currentDirectionalTravel += step;
          } else {
            longestDirectionalTravel = max(
              longestDirectionalTravel,
              currentDirectionalTravel,
            );
            currentDirectionalTravel = step;
          }
          previousDirection = direction;
        }
      }
      longestDirectionalTravel = max(
        longestDirectionalTravel,
        currentDirectionalTravel,
      );
      stepSizes.sort();
      final noiseStep = stepSizes[stepSizes.length ~/ 4];

      final horizontalCoverage = maximumHorizontal - minimumHorizontal;
      final verticalProgression = maximumVertical - minimumVertical;
      // Camera distance, eye shape, and sensor noise vary materially between
      // users. Scale the evidence floor from the observed median movement,
      // while retaining absolute minima so stationary landmark jitter cannot
      // certify reading.
      final coverageFloor = max(0.012, noiseStep * 3.2);
      final travelFloor = max(0.022, noiseStep * 5.5);
      final directionalFloor = max(0.008, noiseStep * 2.2);
      final hasRecentContentInteraction =
          _lastContentInteractionAtMs != null &&
          timestampMs - _lastContentInteractionAtMs! <= 2500;
      // Scrolling or changing pages supports an already plausible gaze
      // pattern, but never certifies reading by itself.
      final interactionFactor = hasRecentContentInteraction ? 0.88 : 1.0;
      final clearLineScan =
          horizontalCoverage >= coverageFloor * interactionFactor &&
          horizontalTravel >= travelFloor * interactionFactor &&
          longestDirectionalTravel >= directionalFloor * interactionFactor &&
          meaningfulSteps >= 3;
      final scanWithLineProgression =
          horizontalCoverage >= coverageFloor * 0.75 &&
          horizontalTravel >= travelFloor * 0.85 &&
          longestDirectionalTravel >= directionalFloor * 0.8 &&
          verticalProgression >= max(0.006, noiseStep * 1.5) &&
          meaningfulSteps >= 3;
      if (clearLineScan || scanWithLineProgression) {
        _lastReadingActivityAtMs = timestampMs;
        // Start a fresh evidence window. This prevents one old wide movement
        // from continuously certifying a later motionless stare as reading.
        _readingGazeWindow.clear();
      }
    }

    return _readingInactivityExceeded(timestampMs);
  }

  bool _readingInactivityExceeded(int timestampMs) {
    final graceElapsed =
        timestampMs - _readingObservationStartedAtMs! >=
        readingPatternGracePeriod.inMilliseconds;
    final readingPauseExceeded =
        timestampMs - _lastReadingActivityAtMs! >=
        maximumReadingPause.inMilliseconds;
    return graceElapsed && readingPauseExceeded;
  }

  @override
  void recordContentInteraction() {
    if (!requireReadingPattern || !_observationClock.isRunning) return;
    _lastContentInteractionAtMs = _observationClock.elapsedMilliseconds;
  }

  double? _mouthOpenRatio(Face face) {
    final upperLip = face.contours[FaceContourType.upperLipBottom]?.points;
    final lowerLip = face.contours[FaceContourType.lowerLipTop]?.points;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;

    if (upperLip == null ||
        upperLip.isEmpty ||
        lowerLip == null ||
        lowerLip.isEmpty ||
        leftMouth == null ||
        rightMouth == null) {
      return null;
    }

    final mouthCenterX = (leftMouth.x + rightMouth.x) / 2;
    final upperCenter = upperLip.reduce(
      (current, point) =>
          (point.x - mouthCenterX).abs() < (current.x - mouthCenterX).abs()
          ? point
          : current,
    );
    final lowerCenter = lowerLip.reduce(
      (current, point) =>
          (point.x - mouthCenterX).abs() < (current.x - mouthCenterX).abs()
          ? point
          : current,
    );
    final mouthWidth = sqrt(
      pow(leftMouth.x - rightMouth.x, 2) + pow(leftMouth.y - rightMouth.y, 2),
    );
    if (mouthWidth <= 0) return null;

    return (lowerCenter.y - upperCenter.y).abs() / mouthWidth;
  }

  bool _updateYawnState({required double? mouthOpenRatio, required int nowMs}) {
    final mouthIsOpen =
        mouthOpenRatio != null && mouthOpenRatio >= mouthOpenRatioThreshold;
    final wasActive = _yawnActive;
    _yawnActive =
        _yawnFilter.update(
          value: mouthIsOpen ? true : null,
          isReliable: mouthOpenRatio != null,
          timestampMs: nowMs,
        ) ==
        true;
    if (_yawnActive && !wasActive) {
      _yawnCount++;
    }
    return _yawnActive;
  }

  void _updateHeadPoseCalibration({
    required double yaw,
    required double pitch,
    required double roll,
    required bool eyesReliablyOpen,
    required _AttentionState? eyeDirection,
  }) {
    final stableCenter =
        eyesReliablyOpen &&
        eyeDirection == null &&
        roll.abs() <= 10 &&
        _directionCandidate == null &&
        !_isDirectionalState(_state);
    if (!stableCenter) return;

    if (_headYawBaseline == null || _headPitchBaseline == null) {
      _headYawCalibrationSamples.add(yaw);
      _headPitchCalibrationSamples.add(pitch);
      if (_headYawCalibrationSamples.length < 6) return;

      final sortedYaw = List<double>.of(_headYawCalibrationSamples)..sort();
      final sortedPitch = List<double>.of(_headPitchCalibrationSamples)..sort();
      _headYawBaseline = sortedYaw[sortedYaw.length ~/ 2];
      _headPitchBaseline = sortedPitch[sortedPitch.length ~/ 2];
      return;
    }

    final yawOffset = yaw - _headYawBaseline!;
    final pitchOffset = pitch - _headPitchBaseline!;
    if (yawOffset.abs() <= headYawExitThreshold &&
        pitchOffset.abs() <= headPitchExitThreshold) {
      const learningRate = 0.015;
      _headYawBaseline = _headYawBaseline! + yawOffset * learningRate;
      _headPitchBaseline = _headPitchBaseline! + pitchOffset * learningRate;
    }
  }

  _AttentionState? _rawDirectionFromHeadPose({
    required double yaw,
    required double pitch,
  }) {
    final leftThreshold = _isTrackingDirection(_AttentionState.lookingLeft)
        ? headYawExitThreshold
        : headYawEnterThreshold;
    final rightThreshold = _isTrackingDirection(_AttentionState.lookingRight)
        ? headYawExitThreshold
        : headYawEnterThreshold;
    final upThreshold = _isTrackingDirection(_AttentionState.lookingUp)
        ? headPitchExitThreshold
        : headPitchEnterThreshold;
    final downThreshold = _isTrackingDirection(_AttentionState.lookingDown)
        ? headPitchExitThreshold
        : headPitchEnterThreshold;

    if (yaw >= leftThreshold) return _AttentionState.lookingLeft;
    if (yaw <= -rightThreshold) return _AttentionState.lookingRight;
    // ML Kit defines positive Euler X as looking upward.
    if (pitch >= upThreshold) return _AttentionState.lookingUp;
    if (pitch <= -downThreshold) return _AttentionState.lookingDown;
    return null;
  }

  _AttentionState? _fusedDirection({
    required _AttentionState? irisDirection,
    required _AttentionState? headDirection,
  }) {
    // Head pose and eye gaze are independent attention signals. During a real
    // head turn the eyes commonly counter-rotate toward the screen, producing
    // the opposite iris direction. Treating that disagreement as centered
    // suppressed the required face-turn alert. A calibrated head turn must
    // therefore stand on its own; iris direction remains the fallback for an
    // eye-only glance while the face stays centered.
    return headDirection ?? irisDirection;
  }

  _AttentionState? _rawDirectionFromBlendshapes(_IrisGazeSample? sample) {
    if (sample == null) return null;
    const enterThreshold = 0.32;
    const exitThreshold = 0.22;
    final candidates = <(_AttentionState, double)>[];

    void addCandidate(_AttentionState direction, double? score) {
      if (score == null) return;
      final threshold = _isTrackingDirection(direction)
          ? exitThreshold
          : enterThreshold;
      if (score >= threshold) candidates.add((direction, score / threshold));
    }

    addCandidate(_AttentionState.lookingLeft, sample.blendshapeLeft);
    addCandidate(_AttentionState.lookingRight, sample.blendshapeRight);
    addCandidate(_AttentionState.lookingUp, sample.blendshapeUp);
    addCandidate(_AttentionState.lookingDown, sample.blendshapeDown);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    return candidates.first.$1;
  }

  _AttentionState? _normalizeHorizontalDirection(_AttentionState? direction) {
    if (!_normalizeMirroredFrontCameraSemantics) return direction;
    return switch (direction) {
      _AttentionState.lookingLeft => _AttentionState.lookingRight,
      _AttentionState.lookingRight => _AttentionState.lookingLeft,
      _ => direction,
    };
  }

  _AttentionState? _fusedEyeDirection({
    required _AttentionState? irisDirection,
    required _AttentionState? blendshapeDirection,
  }) {
    // On iOS the vertical blendshape coefficients are sensitive to the usual
    // below-eye front-camera position and can label a neutral screen gaze as
    // looking down. Never let an uncalibrated vertical coefficient create a
    // warning by itself. Calibrated iris geometry remains authoritative for
    // eye-only up/down gaze, while calibrated ML Kit pitch still detects a
    // vertical head turn. Horizontal blendshapes remain a useful iOS fallback
    // when a side gaze partly occludes one iris.
    if (irisDirection == null) {
      if (!_isIOSPlatform) return null;
      return blendshapeDirection == _AttentionState.lookingLeft ||
              blendshapeDirection == _AttentionState.lookingRight
          ? blendshapeDirection
          : null;
    }
    if (blendshapeDirection == null || irisDirection == blendshapeDirection) {
      return irisDirection;
    }
    // When the optional model disagrees with calibrated geometry, prefer the
    // personalized geometric result rather than turning disagreement into a
    // false positive.
    return irisDirection;
  }

  _AttentionState? _rawDirectionFromIris(_IrisGazeOffset offset) {
    final leftThreshold = _isTrackingDirection(_AttentionState.lookingLeft)
        ? irisGazeExitThreshold
        : irisGazeEnterThreshold;
    final rightThreshold = _isTrackingDirection(_AttentionState.lookingRight)
        ? irisGazeExitThreshold
        : irisGazeEnterThreshold;
    final upThreshold = _isTrackingDirection(_AttentionState.lookingUp)
        ? verticalIrisGazeExitThreshold
        : verticalIrisGazeEnterThreshold;
    final downThreshold = _isTrackingDirection(_AttentionState.lookingDown)
        ? verticalIrisGazeExitThreshold
        : verticalIrisGazeEnterThreshold;

    final candidates = <(_AttentionState, double)>[];
    // Captured front-camera JPEGs are not preview-mirrored: movement toward
    // the user's left increases image-space X, and right decreases it.
    if (offset.horizontal >= leftThreshold) {
      candidates.add((
        _AttentionState.lookingLeft,
        offset.horizontal / leftThreshold,
      ));
    }
    if (offset.horizontal <= -rightThreshold) {
      candidates.add((
        _AttentionState.lookingRight,
        -offset.horizontal / rightThreshold,
      ));
    }
    if (offset.vertical <= -upThreshold) {
      candidates.add((
        _AttentionState.lookingUp,
        -offset.vertical / upThreshold,
      ));
    }
    if (offset.vertical >= downThreshold) {
      candidates.add((
        _AttentionState.lookingDown,
        offset.vertical / downThreshold,
      ));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    return candidates.first.$1;
  }

  bool _isTrackingDirection(_AttentionState direction) =>
      _state == direction || _directionCandidate == direction;

  bool _isDirectionalState(_AttentionState state) =>
      state == _AttentionState.lookingLeft ||
      state == _AttentionState.lookingRight ||
      state == _AttentionState.lookingUp ||
      state == _AttentionState.lookingDown;

  _AttentionState? _confirmedDirection({
    required _AttentionState? direction,
    required bool visualAwayEvidence,
    required bool sampleReliable,
    required int timestampMs,
  }) {
    final confirmedDirection = _gazeAwayFilter.update(
      value: visualAwayEvidence ? direction : null,
      isReliable: sampleReliable,
      timestampMs: timestampMs,
    );
    _directionCandidate = _gazeAwayFilter.candidate;
    if (confirmedDirection == null) {
      if (_gazeAwayFilter.candidate == null) {
        _directionCandidate = null;
        _confirmedGazeDirection = null;
      }
      return null;
    }
    _confirmedGazeDirection = confirmedDirection;
    return _confirmedGazeDirection;
  }

  _AttentionState? _resetDirectionCandidate() {
    _gazeAwayFilter.reset();
    _directionCandidate = null;
    _confirmedGazeDirection = null;
    return null;
  }

  String _gazeDirection(_AttentionState state) => switch (state) {
    _AttentionState.lookingLeft => 'left',
    _AttentionState.lookingRight => 'right',
    _AttentionState.lookingUp => 'up',
    _AttentionState.lookingDown => 'down',
    _ => 'center',
  };

  void _closeCurrentEvent(int endPositionMs) {
    if (_state == _AttentionState.focused) return;
    final duration = endPositionMs - _stateStartedAtMs;
    if (duration < 500) return;

    _emit({
      'type': 'attention_event',
      'event': {
        'eventId': _newId('event', DateTime.now().millisecondsSinceEpoch),
        'sessionId': _sessionId,
        'type': _eventType(_state),
        'startTimeMs': _stateStartedAtMs,
        'endTimeMs': endPositionMs,
        'durationMs': duration,
        'severity': duration >= 5000 ? 'high' : 'moderate',
        'confidence': 0.9,
        'modelVersion': modelVersion,
      },
    });
  }

  void _emitSummary(int nowMs) {
    _lastSummaryAtMs = nowMs;
    _emit({'type': 'attention_summary', 'summary': _summary()});
  }

  Map<String, dynamic> _summary() => {
    'sessionId': _sessionId,
    'elapsedMs': _latestVideoPositionMs,
    'faceVisibleMs': _faceVisibleMs,
    'focusedMs': _focusedMs,
    'distractedMs': _distractedMs,
    'blinkCount': _blinkCount,
    'yawnCount': _yawnCount,
    'longEyeClosureCount': _longEyeClosureCount,
    'drowsinessWarningCount': _drowsinessWarningCount,
    'previewAttentionScore': _attentionScore,
  };

  int get _attentionScore {
    if (_sessionScorer.totalFrames == 0) return 100;
    return _sessionScorer.finalScore;
  }

  @override
  Future<void> complete({required Duration totalDuration}) async {
    if (!_started || _completed) return;
    final now = _observationClock.elapsedMilliseconds;
    _latestVideoPositionMs = totalDuration.inMilliseconds;
    _closeCurrentEvent(_latestVideoPositionMs);
    _emitSummary(now);
    _emit({
      'type': 'attention_session_completed',
      'session': {
        ..._summary(),
        'status': 'completed',
        'totalDurationMs': totalDuration.inMilliseconds,
      },
    });
    _completed = true;
    _observationClock.stop();
  }

  void _emit(Map<String, dynamic> message) => _send?.call(message);

  String _newId(String prefix, int timestamp) =>
      '$prefix-$timestamp-${Random.secure().nextInt(1 << 32)}';

  String _eventType(_AttentionState state) => switch (state) {
    _AttentionState.focused => 'FOCUSED',
    _AttentionState.lowLight => 'LOW_LIGHT',
    _AttentionState.faceMissing => 'FACE_MISSING',
    _AttentionState.eyesClosed => 'EYES_CLOSED',
    _AttentionState.leftEyeClosed => 'LEFT_EYE_CLOSED',
    _AttentionState.rightEyeClosed => 'RIGHT_EYE_CLOSED',
    _AttentionState.yawning => 'YAWNING',
    _AttentionState.lookingLeft => 'LOOKING_LEFT',
    _AttentionState.lookingRight => 'LOOKING_RIGHT',
    _AttentionState.lookingUp => 'LOOKING_UP',
    _AttentionState.lookingDown => 'LOOKING_DOWN',
    _AttentionState.readingNotDetected => 'READING_NOT_DETECTED',
  };

  String _messageFor(_AttentionState state) => switch (state) {
    _AttentionState.focused => 'Your attention is focused on the treatment.',
    _AttentionState.lowLight =>
      'The lighting is too low for reliable attention monitoring. Please move to a brighter area or turn on a light.',
    _AttentionState.faceMissing =>
      'Your face is not visible. Please position yourself clearly in front of the camera.',
    _AttentionState.eyesClosed =>
      'Your eyes appear to be closed. Please open your eyes and return your attention to the screen.',
    _AttentionState.leftEyeClosed =>
      'Your left eye appears to be closed. Please open both eyes and return your attention to the screen.',
    _AttentionState.rightEyeClosed =>
      'Your right eye appears to be closed. Please open both eyes and return your attention to the screen.',
    _AttentionState.yawning =>
      'You appear to be yawning. If you feel tired, please take a short break before continuing.',
    _AttentionState.lookingLeft =>
      'You are looking to the left. Please return your attention to the screen.',
    _AttentionState.lookingRight =>
      'You are looking to the right. Please return your attention to the screen.',
    _AttentionState.lookingUp =>
      'You are looking upward. Please return your attention to the screen.',
    _AttentionState.lookingDown =>
      'You are looking downward. Please return your attention to the screen.',
    _AttentionState.readingNotDetected =>
      'Active reading was not detected. Please continue reading the document naturally, moving through each line at a comfortable pace.',
  };

  String _recommendationFor(_AttentionState state) => switch (state) {
    _AttentionState.focused => 'Continue focusing on the treatment.',
    _AttentionState.lowLight =>
      'Increase the room lighting so your face and eyes are clearly visible.',
    _AttentionState.faceMissing =>
      'Position your face clearly in front of the camera.',
    _AttentionState.eyesClosed =>
      'Keep both eyes open and take a break if tired.',
    _AttentionState.leftEyeClosed || _AttentionState.rightEyeClosed =>
      'Open both eyes and keep them focused on the treatment.',
    _AttentionState.yawning => 'Take a short break if you feel tired.',
    _AttentionState.lookingLeft ||
    _AttentionState.lookingRight ||
    _AttentionState.lookingUp ||
    _AttentionState.lookingDown =>
      'Face the screen directly and keep your gaze centered.',
    _AttentionState.readingNotDetected =>
      'Resume reading the document line by line at your normal pace.',
  };

  @override
  Future<void> dispose() async {
    _observationClock.stop();
    _faceMeshPipeline = null;
    _blendshapesProcessor?.close();
    _faceMeshProcessor?.close();
    _meshFaceDetector?.close();
    _faceMeshProcessor = null;
    _meshFaceDetector = null;
    _blendshapesProcessor = null;
    await _detector.close();
  }
}

class _IrisGazeSample {
  const _IrisGazeSample({
    required this.horizontalRatio,
    required this.verticalRatio,
    required this.leftEyeRatio,
    required this.rightEyeRatio,
    required this.leftEyeVerticalRatio,
    required this.rightEyeVerticalRatio,
    required this.confidence,
    this.blendshapeLeft,
    this.blendshapeRight,
    this.blendshapeUp,
    this.blendshapeDown,
    this.blinkLeftScore,
    this.blinkRightScore,
    this.jawOpenScore,
  });

  final double horizontalRatio;
  final double verticalRatio;
  final double leftEyeRatio;
  final double rightEyeRatio;
  final double leftEyeVerticalRatio;
  final double rightEyeVerticalRatio;
  final double confidence;
  final double? blendshapeLeft;
  final double? blendshapeRight;
  final double? blendshapeUp;
  final double? blendshapeDown;
  final double? blinkLeftScore;
  final double? blinkRightScore;
  final double? jawOpenScore;

  double get eyeRatioDifference => (leftEyeRatio - rightEyeRatio).abs();
  double get verticalEyeRatioDifference =>
      (leftEyeVerticalRatio - rightEyeVerticalRatio).abs();
}

class _ReadingGazePoint {
  const _ReadingGazePoint({
    required this.timestampMs,
    required this.horizontal,
    required this.vertical,
  });

  final int timestampMs;
  final double horizontal;
  final double vertical;
}

class _IrisGazeOffset {
  const _IrisGazeOffset({required this.horizontal, required this.vertical});

  final double horizontal;
  final double vertical;
}

class _BrightnessSample {
  const _BrightnessSample({
    required this.meanLuminance,
    required this.darkPixelRatio,
  });

  final double meanLuminance;
  final double darkPixelRatio;
}
