class AiAssessmentScoreRequest {
  const AiAssessmentScoreRequest({
    required this.fileId,
    required this.isAssessment,
    required this.finalScore,
    required this.attentionEngagementRate,
    required this.averageConfidence,
    required this.totalProcessedFrames,
    required this.sampledFrames,
    required this.sessionDurationSeconds,
    required this.inattentionDuration,
    required this.gazeRatioAvg,
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
  });

  final int fileId;
  final bool isAssessment;
  final int finalScore;
  final double attentionEngagementRate;
  final double averageConfidence;
  final int totalProcessedFrames;
  final int sampledFrames;
  final int sessionDurationSeconds;
  final double inattentionDuration;
  final double gazeRatioAvg;
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'file_id': fileId,
    'is_assessment': isAssessment,
    'final_score': finalScore,
    'attention_engagement_rate': attentionEngagementRate,
    'average_confidence': averageConfidence,
    'total_processed_frames': totalProcessedFrames,
    'sampled_frames': sampledFrames,
    'session_duration_seconds': sessionDurationSeconds,
    'inattention_duration': inattentionDuration,
    'gaze_ratio_avg': gazeRatioAvg,
    'drowsy_state': drowsyState,
    'brightness_score': brightnessScore,
    'pitch': pitch,
    'yaw': yaw,
    'roll': roll,
    'blink_ratio': blinkRatio,
    'yawn_distance': yawnDistance,
    'bad_frame_count': badFrameCount,
    'blurry_frame_count': blurryFrameCount,
    'low_light_frame_count': lowLightFrameCount,
    'eyes_closed_count': eyesClosedCount,
    'gaze_warning_count': gazeWarningCount,
  };
}
