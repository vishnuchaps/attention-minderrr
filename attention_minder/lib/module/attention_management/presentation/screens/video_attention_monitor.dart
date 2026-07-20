import 'package:camera/camera.dart';

typedef AttentionMessageSender = void Function(Map<String, dynamic> message);

class AttentionSessionMetrics {
  const AttentionSessionMetrics({
    required this.finalScore,
    required this.attentionEngagementRate,
    required this.faceDetectionRate,
    required this.averageConfidence,
    required this.totalProcessedFrames,
    required this.sampledFrames,
    required this.sessionDurationSeconds,
    required this.inattentionDuration,
    required this.maximumInattentionDuration,
    required this.gazeRatioAverage,
    required this.drowsyState,
    required this.brightnessScore,
    required this.pitch,
    required this.yaw,
    required this.roll,
    required this.blinkRatio,
    required this.yawnDistance,
    required this.badFrameCount,
    required this.blurryFrameCount,
    required this.lowLightFrameCount,
    required this.eyesClosedCount,
    required this.gazeWarningCount,
    this.gazeQualityAverage = 0,
    this.readingEngagementRate = 0,
    this.readingFocusedFrames = 0,
    this.watchingVideoFrames = 0,
    this.idleDistractedFrames = 0,
    this.readingGazeFrequencyHz = 0,
    this.readingGazeAmplitude = 0,
  });

  final int finalScore;
  final double attentionEngagementRate;
  final double faceDetectionRate;
  final double averageConfidence;
  final int totalProcessedFrames;
  final int sampledFrames;
  final int sessionDurationSeconds;
  final double inattentionDuration;
  final double maximumInattentionDuration;
  final double gazeRatioAverage;
  final double drowsyState;
  final double brightnessScore;
  final double pitch;
  final double yaw;
  final double roll;
  final double blinkRatio;
  final double yawnDistance;
  final int badFrameCount;
  final int blurryFrameCount;
  final int lowLightFrameCount;
  final int eyesClosedCount;
  final int gazeWarningCount;
  final double gazeQualityAverage;
  final double readingEngagementRate;
  final int readingFocusedFrames;
  final int watchingVideoFrames;
  final int idleDistractedFrames;
  final double readingGazeFrequencyHz;
  final double readingGazeAmplitude;
}

/// Pluggable monitoring strategy used by [VideoTreatmentScreen].
///
/// When this is absent, the screen keeps its legacy behavior and uploads
/// frames to the backend. Experimental strategies can instead process frames
/// locally and return the same normalized validation shape consumed by the UI.
abstract interface class VideoAttentionMonitor {
  AttentionSessionMetrics get sessionMetrics;

  Future<void> start({
    required AttentionMessageSender send,
    required int day,
    required bool isAssessment,
  });

  Future<Map<String, dynamic>> analyze({
    required XFile image,
    required Duration videoPosition,
  });

  /// Records direct interaction with reading content, such as scrolling or a
  /// page change. Video screens do not need to call this.
  void recordContentInteraction();

  Future<void> complete({required Duration totalDuration});

  Future<void> dispose();
}
