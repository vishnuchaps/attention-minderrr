class ReadingGazeObservation {
  const ReadingGazeObservation({
    required this.timestampMs,
    required this.horizontal,
    required this.vertical,
  });

  final int timestampMs;
  final double horizontal;
  final double vertical;
}

/// Classifies a fixed gaze independently from paragraph or list reading.
class ReadingGazeClassifier {
  const ReadingGazeClassifier({
    this.minimumSamples = 5,
    this.minimumObservationDuration = const Duration(seconds: 2),
    this.maximumStationaryHorizontalRange = 0.008,
    this.maximumStationaryVerticalRange = 0.007,
    this.minimumHorizontalCoherence = 0.50,
    this.minimumVerticalCoherence = 0.65,
  });

  final int minimumSamples;
  final Duration minimumObservationDuration;
  final double maximumStationaryHorizontalRange;
  final double maximumStationaryVerticalRange;
  final double minimumHorizontalCoherence;
  final double minimumVerticalCoherence;

  bool isStationary(List<ReadingGazeObservation> observations) {
    if (observations.length < minimumSamples) return false;
    if (observations.last.timestampMs - observations.first.timestampMs <
        minimumObservationDuration.inMilliseconds) {
      return false;
    }
    final horizontal = observations
        .map((sample) => sample.horizontal)
        .toList(growable: false);
    final vertical = observations
        .map((sample) => sample.vertical)
        .toList(growable: false);
    final hasHorizontalReadingMovement = _hasCoherentMovement(
      horizontal,
      minimumRange: maximumStationaryHorizontalRange,
      minimumCoherence: minimumHorizontalCoherence,
    );
    final hasVerticalReadingMovement = _hasCoherentMovement(
      vertical,
      minimumRange: maximumStationaryVerticalRange,
      minimumCoherence: minimumVerticalCoherence,
    );
    return !hasHorizontalReadingMovement && !hasVerticalReadingMovement;
  }

  double _trimmedRange(List<double> values) {
    final sorted = [...values]..sort();
    final lowerIndex = (sorted.length * 0.1).floor();
    final upperIndex = (sorted.length * 0.9).ceil() - 1;
    return sorted[upperIndex] - sorted[lowerIndex];
  }

  bool _hasCoherentMovement(
    List<double> values, {
    required double minimumRange,
    required double minimumCoherence,
  }) {
    if (_trimmedRange(values) < minimumRange) return false;

    var totalTravel = 0.0;
    var currentDirectionalTravel = 0.0;
    var longestDirectionalTravel = 0.0;
    var previousDirection = 0;
    for (var index = 1; index < values.length; index++) {
      final delta = values[index] - values[index - 1];
      final step = delta.abs();
      if (step < 0.002) continue;
      totalTravel += step;
      final direction = delta > 0 ? 1 : -1;
      if (previousDirection == 0 || direction == previousDirection) {
        currentDirectionalTravel += step;
      } else {
        if (currentDirectionalTravel > longestDirectionalTravel) {
          longestDirectionalTravel = currentDirectionalTravel;
        }
        currentDirectionalTravel = step;
      }
      previousDirection = direction;
    }
    if (currentDirectionalTravel > longestDirectionalTravel) {
      longestDirectionalTravel = currentDirectionalTravel;
    }
    return totalTravel > 0 &&
        longestDirectionalTravel / totalTravel >= minimumCoherence;
  }
}
