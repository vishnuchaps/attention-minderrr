import 'package:attention_minder/module/result/data/model/questionnaire_result_model.dart';
import 'package:attention_minder/module/result/presentation/screens/single_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final result = ManagementResult(
    id: 17,
    user: 'admin',
    result: 'Moderate difficulty',
    rawTotal: 45,
    tenScore: 5,
    readFocusTotal: 3,
    visualTrackingTotal: 0,
    audioListeningTotal: 0,
    isCompleted: true,
    createdAt: DateTime.utc(2026, 7, 16, 3, 12),
    completedAt: DateTime.utc(2026, 7, 16, 3, 13),
  );

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(home: SingleResultScreen(result: result)),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  testWidgets('renders backend values on a standard phone', (tester) async {
    await pumpAtSize(tester, const Size(430, 932));

    expect(find.text('Moderate difficulty'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Assessment Details'));
    expect(title.style?.fontSize, lessThanOrEqualTo(22));
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(find.text('#17'), findsOneWidget);
    expect(find.text('5.0 / 10'), findsOneWidget);
    final tScoreText = tester.widget<Text>(find.text('T-Score: 5.0 / 10'));
    expect(tScoreText.maxLines, 1);
    expect(tScoreText.softWrap, isFalse);
    expect(find.text('45'), findsOneWidget);
    expect(find.textContaining('points'), findsNothing);
    final resultTop = tester.getTopLeft(find.text('Moderate difficulty')).dy;
    final assessmentIdTop = tester.getTopLeft(find.text('#17')).dy;
    expect((resultTop - assessmentIdTop).abs(), lessThan(80));
    expect(find.text('Visual Tracking'), findsNothing);
    expect(find.text('Audio Listening'), findsNothing);
    expect(find.text('View Recommendations'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on a narrow short phone', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));

    expect(find.text('Assessment Details'), findsOneWidget);
    expect(find.text('Performance Summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
