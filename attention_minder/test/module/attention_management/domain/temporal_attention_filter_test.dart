import 'package:attention_minder/module/attention_management/domain/temporal_attention_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SustainedValueFilter', () {
    late SustainedValueFilter<bool> filter;

    setUp(() {
      filter = SustainedValueFilter<bool>(
        enterDuration: const Duration(seconds: 2),
        dropoutTolerance: const Duration(milliseconds: 1250),
        exitDuration: const Duration(milliseconds: 650),
      );
    });

    test('ignores a natural glance shorter than two seconds', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 500), isNull);
      expect(_away(filter, 1000), isNull);
      expect(_away(filter, 1500), isNull);
      expect(_center(filter, 1750), isNull);
      expect(filter.active, isNull);
    });

    test('confirms sustained away evidence at two seconds', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 500), isNull);
      expect(_away(filter, 1000), isNull);
      expect(_away(filter, 1500), isNull);
      expect(_away(filter, 2000), isTrue);
      expect(filter.active, isTrue);
    });

    test('preserves a candidate through a short unavailable sample', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 500), isNull);
      expect(_unknown(filter, 1000), isNull);
      expect(_away(filter, 1500), isNull);
      expect(_away(filter, 2000), isTrue);
    });

    test('keeps one continuous away episode across direction changes', () {
      // Direction is intentionally reduced to binary away evidence before it
      // enters this filter. Left -> up -> right must remain one episode.
      expect(_away(filter, 0), isNull); // left
      expect(_away(filter, 500), isNull); // left
      expect(_away(filter, 1000), isNull); // up
      expect(_away(filter, 1500), isNull); // right
      expect(_away(filter, 2000), isTrue); // right
    });

    test('does not combine inconsistent directional classifications', () {
      final directionFilter = SustainedValueFilter<String>(
        enterDuration: const Duration(seconds: 2),
        dropoutTolerance: const Duration(milliseconds: 1250),
        exitDuration: const Duration(milliseconds: 650),
      );

      expect(
        directionFilter.update(value: 'left', isReliable: true, timestampMs: 0),
        isNull,
      );
      expect(
        directionFilter.update(
          value: 'left',
          isReliable: true,
          timestampMs: 500,
        ),
        isNull,
      );
      expect(
        directionFilter.update(
          value: 'up',
          isReliable: true,
          timestampMs: 1000,
        ),
        isNull,
      );
      expect(
        directionFilter.update(
          value: 'left',
          isReliable: true,
          timestampMs: 1500,
        ),
        isNull,
      );
      expect(
        directionFilter.update(
          value: 'up',
          isReliable: true,
          timestampMs: 2000,
        ),
        isNull,
      );
      expect(directionFilter.active, isNull);
    });

    test('does not combine separate brief glances', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 700), isNull);
      expect(_center(filter, 900), isNull);
      expect(_away(filter, 1700), isNull);
      expect(_away(filter, 2500), isNull);
      expect(_center(filter, 2700), isNull);
      expect(filter.active, isNull);
    });

    test('reliable centered evidence resets a pending glance', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 1000), isNull);
      expect(_center(filter, 1200), isNull);
      expect(_away(filter, 2000), isNull);
      expect(_away(filter, 3000), isNull);
      expect(_away(filter, 4000), isTrue);
    });

    test('requires stable recovery before clearing a warning', () {
      _away(filter, 0);
      _away(filter, 500);
      _away(filter, 1000);
      _away(filter, 1500);
      expect(_away(filter, 2000), isTrue);

      expect(_center(filter, 2200), isTrue);
      expect(_center(filter, 2700), isTrue);
      expect(_center(filter, 2850), isNull);
      expect(filter.active, isNull);
    });

    test('does not invent evidence across a long camera stall', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 500), isNull);
      expect(_away(filter, 3000), isNull);
      expect(filter.active, isNull);
    });

    test('supports slow on-device inference when configured', () {
      final slowInferenceFilter = SustainedValueFilter<bool>(
        enterDuration: const Duration(seconds: 2),
        maximumObservationGap: const Duration(seconds: 5),
        minimumPositiveSamples: 3,
      );

      expect(_away(slowInferenceFilter, 0), isNull);
      expect(_away(slowInferenceFilter, 2000), isNull);
      expect(_away(slowInferenceFilter, 4000), isTrue);
    });

    test('ignores out-of-order observations', () {
      expect(_away(filter, 1000), isNull);
      expect(_away(filter, 500), isNull);
      expect(_away(filter, 1500), isNull);
      expect(_away(filter, 2500), isNull);
      expect(_away(filter, 3000), isTrue);
    });

    test('normal blink sequence never confirms closed eyes', () {
      expect(_away(filter, 0), isNull);
      expect(_away(filter, 200), isNull);
      expect(_center(filter, 350), isNull);
      expect(filter.active, isNull);
    });
  });
}

bool? _away(SustainedValueFilter<bool> filter, int milliseconds) {
  return filter.update(
    value: true,
    isReliable: true,
    timestampMs: milliseconds,
  );
}

bool? _center(SustainedValueFilter<bool> filter, int milliseconds) {
  return filter.update(
    value: null,
    isReliable: true,
    timestampMs: milliseconds,
  );
}

bool? _unknown(SustainedValueFilter<bool> filter, int milliseconds) {
  return filter.update(
    value: null,
    isReliable: false,
    timestampMs: milliseconds,
  );
}
