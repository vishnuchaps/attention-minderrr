import 'package:attention_minder/module/attention_management/domain/reading_attention_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingAttentionCalculator management.py parity', () {
    test('computes amplitude and direction-change frequency exactly', () {
      final calculator = ReadingAttentionCalculator();
      final dynamics = calculator.computeGazeDynamics([
        (timestampMs: 0, gazeRatio: 1.0),
        (timestampMs: 1000, gazeRatio: 1.4),
        (timestampMs: 2000, gazeRatio: 1.1),
        (timestampMs: 3000, gazeRatio: 1.5),
        (timestampMs: 4000, gazeRatio: 1.2),
      ]);

      expect(dynamics.amplitude, closeTo(0.5, 1e-9));
      expect(dynamics.frequencyHz, closeTo(0.375, 1e-9));
    });

    test('returns zero dynamics with fewer than three samples', () {
      final calculator = ReadingAttentionCalculator();
      final dynamics = calculator.computeGazeDynamics([
        (timestampMs: 0, gazeRatio: 1.0),
        (timestampMs: 1000, gazeRatio: 1.4),
      ]);

      expect(dynamics.frequencyHz, 0);
      expect(dynamics.amplitude, 0);
    });

    test('reading requires every management.py boundary', () {
      final calculator = ReadingAttentionCalculator();

      expect(
        calculator.isReadingFocus(
          gazeRatio: 1,
          drowsyState: 0.2,
          pitch: 0,
          yaw: 0,
          faceCount: 1,
          frequencyHz: 0.2,
          amplitude: 0.4,
        ),
        isTrue,
      );
      expect(
        calculator.isReadingFocus(
          gazeRatio: 0.6,
          drowsyState: 0.2,
          pitch: 0,
          yaw: 0,
          faceCount: 1,
          frequencyHz: 0.2,
          amplitude: 0.4,
        ),
        isFalse,
      );
      expect(
        calculator.isReadingFocus(
          gazeRatio: 1,
          drowsyState: 0.2,
          pitch: 25.01,
          yaw: 0,
          faceCount: 1,
          frequencyHz: 0.2,
          amplitude: 0.4,
        ),
        isFalse,
      );
      expect(
        calculator.isReadingFocus(
          gazeRatio: 1,
          drowsyState: 0.8,
          pitch: 0,
          yaw: 0,
          faceCount: 1,
          frequencyHz: 0.2,
          amplitude: 0.4,
        ),
        isFalse,
      );
      expect(
        calculator.isReadingFocus(
          gazeRatio: 1,
          drowsyState: 0.2,
          pitch: 0,
          yaw: 0,
          faceCount: 2,
          frequencyHz: 0.2,
          amplitude: 0.4,
        ),
        isFalse,
      );
    });

    test('triggers feedback after four continuous disengaged seconds', () {
      final calculator = ReadingAttentionCalculator();

      for (var second = 0; second < 4; second++) {
        final result = calculator.update(
          timestampMs: second * 1000,
          gazeRatio: 3,
          drowsyState: 0.2,
          pitch: 0,
          yaw: 0,
          faceCount: 1,
        );
        expect(result.triggerFeedback, isFalse);
      }

      final result = calculator.update(
        timestampMs: 4000,
        gazeRatio: 3,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );

      expect(result.state, ReadingEngagementState.idleDistracted);
      expect(result.inattentionDurationSeconds, 4);
      expect(result.triggerFeedback, isTrue);
    });

    test('engagement resets the continuous inattention timer', () {
      final calculator = ReadingAttentionCalculator();

      calculator.update(
        timestampMs: 0,
        gazeRatio: 3,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );
      final attentive = calculator.update(
        timestampMs: 3000,
        gazeRatio: 1,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );
      final distractedAgain = calculator.update(
        timestampMs: 5000,
        gazeRatio: 3,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );

      expect(attentive.engaged, isTrue);
      expect(attentive.inattentionDurationSeconds, 0);
      expect(distractedAgain.inattentionDurationSeconds, 0);
      expect(distractedAgain.triggerFeedback, isFalse);
    });

    test('state frame counts remain mutually exclusive', () {
      final calculator = ReadingAttentionCalculator();
      final ratios = [1.0, 1.4, 1.0, 1.4, 3.0];

      for (var index = 0; index < ratios.length; index++) {
        calculator.update(
          timestampMs: index * 1000,
          gazeRatio: ratios[index],
          drowsyState: 0.2,
          pitch: 0,
          yaw: 0,
          faceCount: 1,
        );
      }

      expect(
        calculator.readingFrames +
            calculator.videoAttentiveFrames +
            (calculator.totalFrames - calculator.engagedFrames),
        calculator.totalFrames,
      );
    });

    test('keeps only the latest ten seconds of gaze history', () {
      final calculator = ReadingAttentionCalculator();

      calculator.update(
        timestampMs: 0,
        gazeRatio: 0.7,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );
      calculator.update(
        timestampMs: 10000,
        gazeRatio: 1,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );
      calculator.update(
        timestampMs: 11000,
        gazeRatio: 1.2,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );
      final result = calculator.update(
        timestampMs: 12000,
        gazeRatio: 1.1,
        drowsyState: 0.2,
        pitch: 0,
        yaw: 0,
        faceCount: 1,
      );

      expect(result.gazeAmplitude, closeTo(0.2, 1e-9));
    });
  });
}
