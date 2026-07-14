import 'package:attention_minder/module/attention_management/domain/reading_gaze_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = ReadingGazeClassifier();

  test('fixed gaze is stationary', () {
    expect(
      classifier.isStationary(
        _samples(
          [0.001, 0.002, 0.000, 0.003, 0.002, 0.001],
          [0.001, 0.000, 0.002, 0.001, 0.003, 0.002],
        ),
      ),
      isTrue,
    );
  });

  test('vertical bullet progression is not stationary', () {
    expect(
      classifier.isStationary(
        _samples(
          [0.001, 0.003, 0.002, 0.004, 0.003, 0.002],
          [0.000, 0.004, 0.009, 0.014, 0.020, 0.026],
        ),
      ),
      isFalse,
    );
  });

  test('horizontal paragraph scanning is not stationary', () {
    expect(
      classifier.isStationary(
        _samples(
          [0.000, 0.008, 0.016, 0.024, 0.032, 0.004],
          [0.001, 0.002, 0.001, 0.003, 0.002, 0.005],
        ),
      ),
      isFalse,
    );
  });

  test('one landmark outlier does not make a fixed gaze active', () {
    expect(
      classifier.isStationary(
        _samples(
          [
            0.001,
            0.002,
            0.001,
            0.080,
            0.003,
            0.002,
            0.001,
            0.002,
            0.003,
            0.001,
          ],
          [
            0.001,
            0.002,
            0.001,
            0.002,
            0.001,
            0.002,
            0.001,
            0.002,
            0.001,
            0.002,
          ],
        ),
      ),
      isTrue,
    );
  });

  test('alternating vertical landmark jitter remains stationary', () {
    expect(
      classifier.isStationary(
        _samples(
          [0.001, 0.002, 0.001, 0.003, 0.002, 0.001, 0.002],
          [0.000, 0.013, 0.001, 0.014, 0.002, 0.015, 0.001],
        ),
      ),
      isTrue,
    );
  });
}

List<ReadingGazeObservation> _samples(
  List<double> horizontal,
  List<double> vertical,
) => List.generate(
  horizontal.length,
  (index) => ReadingGazeObservation(
    timestampMs: index * 500,
    horizontal: horizontal[index],
    vertical: vertical[index],
  ),
);
