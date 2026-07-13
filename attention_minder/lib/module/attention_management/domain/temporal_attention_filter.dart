/// Converts noisy per-frame observations into a sustained state.
///
/// A `null` observation can mean either a reliable neutral sample or an
/// unavailable sample. Unavailable samples receive a short grace period so a
/// single landmark dropout does not erase genuine accumulated evidence.
class SustainedValueFilter<T> {
  SustainedValueFilter({
    required this.enterDuration,
    this.dropoutTolerance = const Duration(milliseconds: 750),
    this.exitDuration = const Duration(milliseconds: 350),
    this.maximumObservationGap = const Duration(milliseconds: 1600),
    this.minimumPositiveSamples = 3,
  });

  final Duration enterDuration;
  final Duration dropoutTolerance;
  final Duration exitDuration;
  final Duration maximumObservationGap;
  final int minimumPositiveSamples;

  T? _candidate;
  T? _active;
  int? _candidateStartedAtMs;
  int? _lastPositiveAtMs;
  int? _recoveryStartedAtMs;
  int? _lastTimestampMs;
  int _candidateSampleCount = 0;

  T? get candidate => _candidate;
  T? get active => _active;

  T? update({
    required T? value,
    required bool isReliable,
    required int timestampMs,
  }) {
    final previousTimestamp = _lastTimestampMs;
    if (previousTimestamp != null && timestampMs < previousTimestamp) {
      return _active;
    }
    final nowMs = _prepareTimestamp(timestampMs);

    if (_active != null) {
      if (value == _active) {
        _lastPositiveAtMs = nowMs;
        _recoveryStartedAtMs = null;
        return _active;
      }

      if (!isReliable && _withinDropoutGrace(nowMs)) return _active;

      _recoveryStartedAtMs ??= nowMs;
      if (nowMs - _recoveryStartedAtMs! < exitDuration.inMilliseconds) {
        return _active;
      }

      _active = null;
      _candidate = null;
      _candidateStartedAtMs = null;
      _lastPositiveAtMs = null;
      _candidateSampleCount = 0;
      _recoveryStartedAtMs = null;
    }

    if (value == null) {
      if (isReliable || !_withinDropoutGrace(nowMs)) {
        _candidate = null;
        _candidateStartedAtMs = null;
        _lastPositiveAtMs = null;
        _candidateSampleCount = 0;
      }
      return null;
    }

    if (_candidate != value) {
      _candidate = value;
      _candidateStartedAtMs = nowMs;
      _candidateSampleCount = 1;
    } else {
      _candidateSampleCount++;
    }
    _lastPositiveAtMs = nowMs;

    if (_candidateSampleCount >= minimumPositiveSamples &&
        nowMs - (_candidateStartedAtMs ?? nowMs) >=
            enterDuration.inMilliseconds) {
      _active = value;
      _recoveryStartedAtMs = null;
      return value;
    }
    return null;
  }

  void reset() {
    _candidate = null;
    _active = null;
    _candidateStartedAtMs = null;
    _lastPositiveAtMs = null;
    _recoveryStartedAtMs = null;
    _lastTimestampMs = null;
    _candidateSampleCount = 0;
  }

  bool _withinDropoutGrace(int nowMs) {
    final lastPositiveAtMs = _lastPositiveAtMs;
    return lastPositiveAtMs != null &&
        nowMs - lastPositiveAtMs <= dropoutTolerance.inMilliseconds;
  }

  int _prepareTimestamp(int timestampMs) {
    final previous = _lastTimestampMs;
    if (previous != null &&
        timestampMs - previous > maximumObservationGap.inMilliseconds) {
      // Never manufacture sustained attention evidence across app suspension,
      // camera stalls, or very slow inference gaps.
      _candidate = null;
      _active = null;
      _candidateStartedAtMs = null;
      _lastPositiveAtMs = null;
      _recoveryStartedAtMs = null;
      _candidateSampleCount = 0;
    }
    final normalized = previous == null || timestampMs >= previous
        ? timestampMs
        : previous;
    _lastTimestampMs = normalized;
    return normalized;
  }
}
