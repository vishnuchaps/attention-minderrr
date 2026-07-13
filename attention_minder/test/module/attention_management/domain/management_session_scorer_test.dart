import 'package:attention_minder/module/attention_management/domain/management_session_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagementSessionScorer backend parity', () {
    test('returns zero for an empty session', () {
      final scorer = ManagementSessionScorer();

      expect(scorer.totalFrames, 0);
      expect(scorer.attentionEngagementRate, 0);
      expect(scorer.finalScore, 0);
      expect(scorer.inattentionDurationSeconds, 0);
    });

    test('calculates AER from attentive frames over all frames', () {
      final scorer = ManagementSessionScorer();

      for (var index = 0; index < 7; index++) {
        scorer.recordFrame(attentive: true, timestampMs: index * 500);
      }
      for (var index = 7; index < 10; index++) {
        scorer.recordFrame(attentive: false, timestampMs: index * 500);
      }

      expect(scorer.totalFrames, 10);
      expect(scorer.attentiveFrames, 7);
      expect(scorer.distractedFrames, 3);
      expect(scorer.attentionEngagementRate, 70);
      expect(scorer.finalScore, 70);
    });

    test('rounds the backend percentage only for final score', () {
      final scorer = ManagementSessionScorer();
      scorer.recordFrame(attentive: true, timestampMs: 0);
      scorer.recordFrame(attentive: true, timestampMs: 500);
      scorer.recordFrame(attentive: false, timestampMs: 1000);

      expect(scorer.attentionEngagementRate, closeTo(66.666666, 0.00001));
      expect(scorer.finalScore, 67);
    });

    test('counts observed inattentive time while video is paused', () {
      final scorer = ManagementSessionScorer();
      scorer.recordFrame(attentive: false, timestampMs: 0);
      scorer.recordFrame(attentive: false, timestampMs: 500);
      scorer.recordFrame(attentive: false, timestampMs: 1000);
      scorer.recordFrame(attentive: true, timestampMs: 1500);

      expect(scorer.inattentionDurationSeconds, 1.5);
      expect(scorer.maximumInattentionDurationSeconds, 1.5);
    });

    test(
      'tracks the longest inattention episode separately from total time',
      () {
        final scorer = ManagementSessionScorer();
        scorer.recordFrame(attentive: false, timestampMs: 0);
        scorer.recordFrame(attentive: false, timestampMs: 500);
        scorer.recordFrame(attentive: true, timestampMs: 1000);
        scorer.recordFrame(attentive: false, timestampMs: 1500);
        scorer.recordFrame(attentive: false, timestampMs: 2000);
        scorer.recordFrame(attentive: false, timestampMs: 2500);
        scorer.recordFrame(attentive: true, timestampMs: 3000);

        expect(scorer.inattentionDurationSeconds, 2.5);
        expect(scorer.maximumInattentionDurationSeconds, 1.5);
      },
    );

    test('does not manufacture duration across a camera stall', () {
      final scorer = ManagementSessionScorer();
      scorer.recordFrame(attentive: false, timestampMs: 0);
      scorer.recordFrame(attentive: true, timestampMs: 5000);

      expect(scorer.inattentionDurationSeconds, 0);
      expect(scorer.attentionEngagementRate, 50);
    });

    test('ignores out-of-order frames', () {
      final scorer = ManagementSessionScorer();
      scorer.recordFrame(attentive: true, timestampMs: 1000);
      scorer.recordFrame(attentive: false, timestampMs: 500);

      expect(scorer.totalFrames, 1);
      expect(scorer.finalScore, 100);
    });
  });
}
