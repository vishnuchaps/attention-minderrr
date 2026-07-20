import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_attention_monitor.dart';

class PdfReadingScoreRequest extends AiAssessmentScoreRequest {
  PdfReadingScoreRequest({
    required super.fileId,
    required super.isAssessment,
    required this.metrics,
  }) : super(
         contentType: 'pdf',
         finalScore: metrics.finalScore,
         attentionEngagementRate: metrics.attentionEngagementRate,
         averageConfidence: metrics.averageConfidence,
         totalProcessedFrames: metrics.totalProcessedFrames,
         sampledFrames: metrics.sampledFrames,
         sessionDurationSeconds: metrics.sessionDurationSeconds,
         inattentionDuration: metrics.inattentionDuration,
         gazeRatioAvg: metrics.gazeRatioAverage,
         drowsyState: metrics.drowsyState,
         brightnessScore: metrics.brightnessScore,
         pitch: metrics.pitch,
         yaw: metrics.yaw,
         roll: metrics.roll,
         blinkRatio: metrics.blinkRatio,
         yawnDistance: metrics.yawnDistance,
         badFrameCount: metrics.badFrameCount,
         blurryFrameCount: metrics.blurryFrameCount,
         lowLightFrameCount: metrics.lowLightFrameCount,
         eyesClosedCount: metrics.eyesClosedCount,
         gazeWarningCount: metrics.gazeWarningCount,
       );

  final AttentionSessionMetrics metrics;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'calculation_version': 'management_py_reading_v1',
    'reading_engagement_rate': metrics.readingEngagementRate,
    'reading_focused_frames': metrics.readingFocusedFrames,
    'watching_video_frames': metrics.watchingVideoFrames,
    'idle_distracted_frames': metrics.idleDistractedFrames,
    'maximum_inattention_duration': metrics.maximumInattentionDuration,
    'gaze_quality_avg': metrics.gazeQualityAverage,
    'reading_gaze_frequency_avg_hz': metrics.readingGazeFrequencyHz,
    'reading_gaze_amplitude_avg': metrics.readingGazeAmplitude,
  };
}
