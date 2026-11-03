import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_activity1_appdev/screens/activities/multi_screen_navigation_screen.dart';

void main() {
  testWidgets('Activity 1 opens both screens and updates local state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ActivityOneFeatureCard())),
    );
    await tester.tap(find.text('Multi-Screen Navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap Counter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a tap'));
    await tester.pump();
    expect(find.text('1 taps'), findsOneWidget);
    await tester.tap(find.text('Reset counter'));
    await tester.pump();
    expect(find.text('0 taps'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study Checklist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review the lesson'));
    await tester.pump();
    expect(find.text('1 of 3 completed'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your activity dashboard'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Multi-Screen Navigation'), findsOneWidget);
  });

  for (final width in [240.0, 375.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Activity screens fit $width px at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final screen in const [
          MultiScreenNavigationScreen(),
          TapCounterScreen(),
          StudyChecklistScreen(),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: screen,
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
