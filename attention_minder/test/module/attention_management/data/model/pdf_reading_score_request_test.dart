import 'package:attention_minder/module/attention_management/data/model/ai_assessment_score_request.dart';
import 'package:attention_minder/module/attention_management/data/model/pdf_reading_score_request.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_attention_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes video content type in the shared score payload', () {
    const request = AiAssessmentScoreRequest(
      fileId: 7,
      contentType: 'video',
      isAssessment: false,
      finalScore: 80,
      attentionEngagementRate: 80,
      averageConfidence: 0.9,
      totalProcessedFrames: 10,
      sampledFrames: 10,
      sessionDurationSeconds: 30,
      inattentionDuration: 2,
      gazeRatioAvg: 1,
      drowsyState: 0.2,
      brightnessScore: 70,
      pitch: 0,
      yaw: 0,
      roll: 0,
      blinkRatio: 0.1,
      yawnDistance: 0,
      badFrameCount: 2,
      blurryFrameCount: 0,
      lowLightFrameCount: 0,
      eyesClosedCount: 0,
      gazeWarningCount: 1,
    );

    expect(request.toJson()['content_type'], 'video');
  });

  test('serializes the complete PDF backend field contract', () {
    const metrics = AttentionSessionMetrics(
      finalScore: 75,
      attentionEngagementRate: 75,
      faceDetectionRate: 90,
      averageConfidence: 0.91,
      totalProcessedFrames: 40,
      sampledFrames: 20,
      sessionDurationSeconds: 60,
      inattentionDuration: 12,
      maximumInattentionDuration: 4,
      gazeRatioAverage: 1.1,
      drowsyState: 0.23,
      brightnessScore: 68,
      pitch: 2,
      yaw: -1,
      roll: 0.5,
      blinkRatio: 0.08,
      yawnDistance: 0.1,
      badFrameCount: 5,
      blurryFrameCount: 0,
      lowLightFrameCount: 1,
      eyesClosedCount: 2,
      gazeWarningCount: 3,
      gazeQualityAverage: 0.82,
      readingEngagementRate: 50,
      readingFocusedFrames: 10,
      watchingVideoFrames: 5,
      idleDistractedFrames: 5,
      readingGazeFrequencyHz: 0.3,
      readingGazeAmplitude: 0.4,
    );

    final AiAssessmentScoreRequest request = PdfReadingScoreRequest(
      fileId: 42,
      isAssessment: false,
      metrics: metrics,
    );
    final json = request.toJson();

    expect(json['file_id'], 42);
    expect(json['content_type'], 'pdf');
    expect(json['calculation_version'], 'management_py_reading_v1');
    expect(json['attention_engagement_rate'], 75);
    expect(json['reading_engagement_rate'], 50);
    expect(json['reading_focused_frames'], 10);
    expect(json['watching_video_frames'], 5);
    expect(json['idle_distracted_frames'], 5);
    expect(json['gaze_ratio_avg'], 1.1);
    expect(json['reading_gaze_frequency_avg_hz'], 0.3);
    expect(json['reading_gaze_amplitude_avg'], 0.4);
    expect(json.keys, hasLength(32));
  });
}
