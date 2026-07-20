import 'package:attention_minder/module/result/data/model/assessment_history_model.dart';
import 'package:attention_minder/module/result/presentation/screens/ai_assessment_result_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final result = AssessmentHistoryItem.fromJson({
    'id': '27',
    'title': 'AI Focus Assessment',
    'final_score': '100',
    'attention_engagement_rate': '80',
    'average_confidence': 0.92,
    'total_processed_frames': '30',
    'sampled_frames': 24,
    'session_duration_seconds': '300',
    'created_at': '2026-07-15T16:51:00Z',
  });

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(home: AiAssessmentResultDetailScreen(result: result)),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('renders dynamic AI history metrics on a standard phone', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(430, 932));

    expect(find.text('AI Assessment Details'), findsOneWidget);
    expect(find.text('100 / 100'), findsOneWidget);
    expect(find.text('Excellent'), findsWidgets);
    expect(find.text('10.0 / 10'), findsOneWidget);
    expect(find.text('8.0 / 10'), findsOneWidget);
    expect(find.text('80.0%'), findsOneWidget);
    expect(find.text('92.0%'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('300 sec'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(find.textContaining('Session Timeline'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on a narrow short phone', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));

    expect(find.text('AI Assessment Details'), findsOneWidget);
    expect(find.text('Performance Summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
