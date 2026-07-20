import 'dart:collection';

enum ReadingEngagementState { readingPdf, watchingVideo, idleDistracted }

class ReadingAttentionResult {
  const ReadingAttentionResult({
    required this.state,
    required this.triggerFeedback,
    required this.videoAttentive,
    required this.readingFocused,
    required this.engaged,
    required this.inattentionDurationSeconds,
    required this.gazeFrequencyHz,
    required this.gazeAmplitude,
  });

  final ReadingEngagementState state;
  final bool triggerFeedback;
  final bool videoAttentive;
  final bool readingFocused;
  final bool engaged;
  final double inattentionDurationSeconds;
  final double gazeFrequencyHz;
  final double gazeAmplitude;
}

/// Exact stateful Dart port of the numbered attention algorithm in
/// `management.py`.
///
/// Input acquisition is platform-native (MediaPipe/ML Kit), but every
/// threshold, window, comparison and formula below mirrors that specification.
class ReadingAttentionCalculator {
  ReadingAttentionCalculator({
    this.gazeLow = 0.6,
    this.gazeHigh = 2.5,
    this.headLimitDegrees = 25,
    this.inattentionLimit = const Duration(seconds: 4),
    this.readingWindow = const Duration(seconds: 10),
    this.minimumReadingAmplitude = 0.3,
    this.minimumReadingFrequencyHz = 0.1,
    this.maximumReadingFrequencyHz = 1.5,
  });

  final double gazeLow;
  final double gazeHigh;
  final double headLimitDegrees;
  final Duration inattentionLimit;
  final Duration readingWindow;
  final double minimumReadingAmplitude;
  final double minimumReadingFrequencyHz;
  final double maximumReadingFrequencyHz;

  final ListQueue<({int timestampMs, double gazeRatio})> _gazeHistory =
      ListQueue<({int timestampMs, double gazeRatio})>();

  int? _inattentionStartedAtMs;
  int _totalFrames = 0;
  int _engagedFrames = 0;
  int _readingFrames = 0;
  int _videoAttentiveFrames = 0;
  double _gazeRatioTotal = 0;
  int _gazeRatioSamples = 0;
  double _frequencyTotal = 0;
  double _amplitudeTotal = 0;
  int _dynamicsSamples = 0;
  ReadingAttentionResult? _latestResult;

  int get totalFrames => _totalFrames;
  int get engagedFrames => _engagedFrames;
  int get readingFrames => _readingFrames;
  int get videoAttentiveFrames => _videoAttentiveFrames;
  ReadingAttentionResult? get latestResult => _latestResult;

  double get attentionEngagementRate =>
      _percentage(_engagedFrames, _totalFrames);
  double get readingEngagementRate => _percentage(_readingFrames, _totalFrames);
  double get videoAttentionRate =>
      _percentage(_videoAttentiveFrames, _totalFrames);
  double get averageGazeRatio => _average(_gazeRatioTotal, _gazeRatioSamples);
  double get averageGazeFrequencyHz =>
      _average(_frequencyTotal, _dynamicsSamples);
  double get averageGazeAmplitude =>
      _average(_amplitudeTotal, _dynamicsSamples);

  ReadingAttentionResult update({
    required int timestampMs,
    required double? gazeRatio,
    required double drowsyState,
    required double pitch,
    required double yaw,
    required int faceCount,
  }) {
    if (gazeRatio != null && gazeRatio.isFinite) {
      _gazeHistory.add((timestampMs: timestampMs, gazeRatio: gazeRatio));
      _gazeRatioTotal += gazeRatio;
      _gazeRatioSamples++;
    }

    final windowStart = timestampMs - readingWindow.inMilliseconds;
    while (_gazeHistory.isNotEmpty &&
        _gazeHistory.first.timestampMs < windowStart) {
      _gazeHistory.removeFirst();
    }

    final dynamics = computeGazeDynamics(_gazeHistory);
    _frequencyTotal += dynamics.frequencyHz;
    _amplitudeTotal += dynamics.amplitude;
    _dynamicsSamples++;

    final validGazeRatio = gazeRatio != null && gazeRatio.isFinite
        ? gazeRatio
        : null;
    final videoAttentive =
        validGazeRatio != null &&
        isAttentiveToVideo(
          gazeRatio: validGazeRatio,
          drowsyState: drowsyState,
          pitch: pitch,
          yaw: yaw,
          faceCount: faceCount,
        );
    final readingFocused =
        validGazeRatio != null &&
        isReadingFocus(
          gazeRatio: validGazeRatio,
          drowsyState: drowsyState,
          pitch: pitch,
          yaw: yaw,
          faceCount: faceCount,
          frequencyHz: dynamics.frequencyHz,
          amplitude: dynamics.amplitude,
        );
    final engaged = videoAttentive || readingFocused;

    double inattentionDurationSeconds;
    if (engaged) {
      _inattentionStartedAtMs = null;
      inattentionDurationSeconds = 0;
    } else {
      _inattentionStartedAtMs ??= timestampMs;
      inattentionDurationSeconds =
          (timestampMs - _inattentionStartedAtMs!) / 1000;
    }

    final triggerFeedback =
        !engaged &&
        inattentionDurationSeconds >= inattentionLimit.inMilliseconds / 1000;
    final state = readingFocused
        ? ReadingEngagementState.readingPdf
        : videoAttentive
        ? ReadingEngagementState.watchingVideo
        : ReadingEngagementState.idleDistracted;

    _totalFrames++;
    if (engaged) _engagedFrames++;
    if (state == ReadingEngagementState.readingPdf) {
      _readingFrames++;
    } else if (state == ReadingEngagementState.watchingVideo) {
      _videoAttentiveFrames++;
    }

    return _latestResult = ReadingAttentionResult(
      state: state,
      triggerFeedback: triggerFeedback,
      videoAttentive: videoAttentive,
      readingFocused: readingFocused,
      engaged: engaged,
      inattentionDurationSeconds: inattentionDurationSeconds,
      gazeFrequencyHz: dynamics.frequencyHz,
      gazeAmplitude: dynamics.amplitude,
    );
  }

  bool isAttentiveToVideo({
    required double gazeRatio,
    required double drowsyState,
    required double pitch,
    required double yaw,
    required int faceCount,
  }) {
    if (!(gazeLow < gazeRatio && gazeRatio < gazeHigh)) return false;
    if (drowsyState != 0.2) return false;
    if (!(-headLimitDegrees <= pitch && pitch <= headLimitDegrees)) {
      return false;
    }
    if (!(-headLimitDegrees <= yaw && yaw <= headLimitDegrees)) return false;
    if (faceCount < 1) return false;
    return true;
  }

  bool isReadingFocus({
    required double gazeRatio,
    required double drowsyState,
    required double pitch,
    required double yaw,
    required int faceCount,
    required double frequencyHz,
    required double amplitude,
  }) {
    if (faceCount != 1) return false;
    if (!(-headLimitDegrees <= pitch && pitch <= headLimitDegrees)) {
      return false;
    }
    if (!(-headLimitDegrees <= yaw && yaw <= headLimitDegrees)) return false;
    if (drowsyState != 0.2) return false;
    if (!(gazeLow < gazeRatio && gazeRatio < gazeHigh)) return false;
    if (amplitude < minimumReadingAmplitude) return false;
    if (!(minimumReadingFrequencyHz <= frequencyHz &&
        frequencyHz <= maximumReadingFrequencyHz)) {
      return false;
    }
    return true;
  }

  ({double frequencyHz, double amplitude}) computeGazeDynamics(
    Iterable<({int timestampMs, double gazeRatio})> history,
  ) {
    final samples = history.toList(growable: false);
    if (samples.length < 3) return (frequencyHz: 0, amplitude: 0);

    final durationSeconds =
        (samples.last.timestampMs - samples.first.timestampMs) / 1000;
    if (durationSeconds <= 0) return (frequencyHz: 0, amplitude: 0);

    var minimum = samples.first.gazeRatio;
    var maximum = minimum;
    var directionChanges = 0;
    var lastSign = 0;

    for (var index = 1; index < samples.length; index++) {
      final value = samples[index].gazeRatio;
      if (value < minimum) minimum = value;
      if (value > maximum) maximum = value;

      final difference = value - samples[index - 1].gazeRatio;
      if (difference.abs() < 1e-3) continue;
      final sign = difference > 0 ? 1 : -1;
      if (lastSign != 0 && sign != lastSign) directionChanges++;
      lastSign = sign;
    }

    return (
      frequencyHz: (directionChanges / 2) / durationSeconds,
      amplitude: maximum - minimum,
    );
  }

  double _percentage(int numerator, int denominator) =>
      denominator == 0 ? 0 : (numerator / denominator) * 100;

  double _average(double total, int count) => count == 0 ? 0 : total / count;
}
