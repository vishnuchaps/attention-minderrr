import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:attention_minder/module/result/presentation/screens/management_session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpSession(
    WidgetTester tester,
    ManagementSession session,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(home: ManagementSessionDetailScreen(session: session)),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('renders PDF-specific reading details from the response', (
    tester,
  ) async {
    final session = ManagementSession.fromJson({
      'id': 13779,
      'content_type': 'pdf',
      'file_title': 'week-1',
      'final_score': 93,
      'created_at': '2026-07-20T08:50:04.137411+00:00',
      'time_label': '8:50 AM',
      'session_duration_seconds': 27,
      'duration_label': '0m',
      'concentration_score': 7.44,
      'reading_engagement_rate': 5.31,
      'attention_engagement_rate': 92.92,
      'reading_focused_frames': 6,
      'gaze_quality_avg': .5406,
      'gaze_ratio_avg': 1.021,
      'reading_gaze_frequency_avg_hz': .9589,
      'reading_gaze_amplitude_avg': .1752,
      'idle_distracted_frames': 8,
      'inattention_duration': 1.36,
      'blurry_frame_count': 0,
      'low_light_frame_count': 0,
      'eyes_closed_count': 0,
      'gaze_warning_count': 0,
    });

    await pumpSession(tester, session, const Size(430, 932));

    expect(find.text('Reading Focus Details'), findsOneWidget);
    expect(find.text('PDF Management Session'), findsOneWidget);
    expect(find.text('week-1'), findsOneWidget);
    expect(find.text('Reading Performance'), findsOneWidget);
    expect(find.text('Reading Engagement'), findsOneWidget);
    expect(find.text('5.31%'), findsOneWidget);
    expect(find.text('Attention Engagement'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('5.31%')).style?.color,
      const Color(0xFFD23F3F),
    );
    expect(
      tester.widget<Text>(find.text('92.92%')).style?.color,
      const Color(0xFF079455),
    );
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Average gaze ratio'), findsOneWidget);
    expect(find.text('1.02'), findsOneWidget);
    expect(find.text('8:50 AM'), findsOneWidget);
    expect(find.text('27 sec'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders video-specific metrics without overflow on narrow phone',
    (tester) async {
      final session = ManagementSession.fromJson({
        'id': 42,
        'content_type': 'video',
        'title': 'Guided Attention',
        'final_score': 79,
        'created_at': '2026-07-20T16:05:00',
        'session_duration_seconds': 600,
        'attention_engagement_rate': 76,
        'average_confidence': .91,
        'concentration_score': 7.6,
        'total_processed_frames': 140,
        'sampled_frames': 70,
        'gaze_ratio_avg': 1.5,
        'gaze_warning_count': 0,
        'eyes_closed_count': 0,
        'bad_frame_count': 0,
        'inattention_duration': 0,
      });

      await pumpSession(tester, session, const Size(320, 568));

      expect(find.text('Focus Training Details'), findsOneWidget);
      expect(find.text('Video Management Session'), findsOneWidget);
      expect(find.text('Focus Performance'), findsOneWidget);
      expect(find.text('Tracking Confidence'), findsOneWidget);
      expect(find.text('91%'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('91%')).style?.color,
        const Color(0xFF079455),
      );
      expect(find.text('Average gaze ratio'), findsNothing);
      expect(find.text('1.5'), findsNothing);
      expect(find.text('Gaze warnings'), findsNothing);
      expect(find.text('Eyes-closed events'), findsNothing);
      expect(find.text('Inattention duration'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
