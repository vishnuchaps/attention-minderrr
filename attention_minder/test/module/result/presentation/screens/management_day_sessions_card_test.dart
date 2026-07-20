import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:attention_minder/module/result/presentation/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final day = ManagementDay.fromJson({
    'date': '2026-07-20',
    'sessions': [
      {
        'content_type': 'pdf',
        'title': 'Reading Focus',
        'final_score': 82,
        'created_at': '2026-07-20T10:15:00',
        'session_duration_seconds': 720,
      },
      {
        'content_type': 'video',
        'title': 'Focus Training With A Long Responsive Title',
        'final_score': 86,
        'created_at': '2026-07-20T11:40:00',
        'session_duration_seconds': 900,
      },
    ],
  });

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ManagementDaySessionsCard(day: day),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('renders separate PDF and video management rows', (tester) async {
    await pumpAtSize(tester, const Size(430, 932));

    expect(find.text('2 sessions  •  27 min total'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('Reading Focus'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on a narrow phone and opens details', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(320, 568));

    await tester.tap(find.text('Reading Focus'));
    await tester.pumpAndSettle();

    expect(find.text('Reading Focus Details'), findsOneWidget);
    expect(find.text('PDF Management Session'), findsOneWidget);
    expect(find.text('82 / 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
