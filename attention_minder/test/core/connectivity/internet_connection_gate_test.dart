import 'package:attention_minder/core/connectivity/internet_connection_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows offline UI and restores content after retry', (
    tester,
  ) async {
    var online = false;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: InternetConnectionGate(
          navigatorKey: navigatorKey,
          probe: () async => online,
          child: const Scaffold(body: Text('Connected content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.text('Connected content'), findsOneWidget);

    online = true;
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No Internet Connection'), findsNothing);
    expect(find.text('Connected content'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
