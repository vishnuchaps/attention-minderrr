/// Frame-based session scoring ported from the backend management scripts.
///
/// The source formula is:
///   AER = attentive frame count / total frame count * 100
///
/// This class deliberately receives already-classified attention states. It
/// performs aggregation only and cannot affect detection behavior.
class ManagementSessionScorer {
  ManagementSessionScorer({
    this.maximumObservationGap = const Duration(milliseconds: 1600),
  });

  final Duration maximumObservationGap;

  int _totalFrames = 0;
  int _attentiveFrames = 0;
  int _inattentionMilliseconds = 0;
  int _currentInattentionEpisodeMilliseconds = 0;
  int _maximumInattentionEpisodeMilliseconds = 0;
  int? _lastTimestampMs;
  bool? _lastFrameWasAttentive;

  int get totalFrames => _totalFrames;
  int get attentiveFrames => _attentiveFrames;
  int get distractedFrames => _totalFrames - _attentiveFrames;

  double get attentionEngagementRate {
    if (_totalFrames == 0) return 0;
    return (_attentiveFrames / _totalFrames) * 100;
  }

  int get finalScore => attentionEngagementRate.round().clamp(0, 100);

  double get inattentionDurationSeconds => _inattentionMilliseconds / 1000;
  double get maximumInattentionDurationSeconds =>
      _maximumInattentionEpisodeMilliseconds / 1000;

  void recordFrame({required bool attentive, required int timestampMs}) {
    final previousTimestamp = _lastTimestampMs;
    if (previousTimestamp != null && timestampMs < previousTimestamp) return;

    if (previousTimestamp != null && _lastFrameWasAttentive == false) {
      final gap = timestampMs - previousTimestamp;
      if (gap <= maximumObservationGap.inMilliseconds) {
        _inattentionMilliseconds += gap;
        _currentInattentionEpisodeMilliseconds += gap;
        if (_currentInattentionEpisodeMilliseconds >
            _maximumInattentionEpisodeMilliseconds) {
          _maximumInattentionEpisodeMilliseconds =
              _currentInattentionEpisodeMilliseconds;
        }
      }
    }

    if (attentive) _currentInattentionEpisodeMilliseconds = 0;

    _totalFrames++;
    if (attentive) _attentiveFrames++;
    _lastTimestampMs = timestampMs;
    _lastFrameWasAttentive = attentive;
  }
}
