import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_activity1_appdev/models/activity_model.dart';
import 'package:flutter_activity1_appdev/providers/app_provider.dart';
import 'package:flutter_activity1_appdev/screens/activities/labtrack_activity_screen.dart';
import 'package:flutter_activity1_appdev/providers/mesh_provider.dart';
import 'package:flutter_activity1_appdev/providers/network_health_provider.dart';
import 'package:flutter_activity1_appdev/screens/activities/network_diagnostics_dashboard_screen.dart';
import 'package:flutter_activity1_appdev/screens/mesh_chat_screen.dart';
import 'package:flutter_activity1_appdev/screens/home_screen.dart';

void main() {
  test('MeshProvider ignores a start request while active', () async {
    final mesh = MeshProvider()..status = MeshStatus.active;

    await mesh.start('Test device');

    expect(mesh.status, MeshStatus.active);
  });

  testWidgets('Home header fits a narrow viewport with a long name', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375.2, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final app = AppProvider()
      ..updateProfile(name: 'A student with a very long name', role: 'Student');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider(
            create: (_) => NetworkHealthProvider(autoStart: false),
          ),
        ],
        child: const MaterialApp(home: HomeTab()),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Hello, ${app.userName} '), findsOneWidget);
    expect(find.byIcon(Icons.speed_rounded), findsWidgets);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Activity layouts fit 315px at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(315.2, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Widget host(Widget screen) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(
            create: (_) => NetworkHealthProvider(autoStart: false),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      );

      await tester.pumpWidget(host(const HomeTab()));
      expect(tester.takeException(), isNull);
      for (final activity in ActivityData.activities) {
        await tester.pumpWidget(
          host(LabTrackActivityScreen(activity: activity)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  for (final width in [172.0, 240.0, 280.0, 320.0]) {
    testWidgets('Main tabs fit a ${width}px viewport', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
            ChangeNotifierProvider(
              create: (_) => NetworkHealthProvider(autoStart: false),
            ),
          ],
          child: const MaterialApp(home: MainShell()),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Activities').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Settings').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home header wraps within 132px', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(
            create: (_) => NetworkHealthProvider(autoStart: false),
          ),
        ],
        child: const MaterialApp(home: HomeTab()),
      ),
    );
    final header = tester.widget<Column>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Column),
          )
          .at(1),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NetworkHealthProvider(autoStart: false),
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 132, child: header)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final chip = tester.getRect(find.byIcon(Icons.speed_rounded));
    final avatar = tester.getRect(find.byType(CircleAvatar));
    expect(avatar.top, greaterThan(chip.bottom));
  });

  testWidgets('Mesh Chat idle state fits a compact viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => MeshProvider()),
        ],
        child: const MaterialApp(home: MeshChatScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Network Diagnostic Dashboard renders with Unknown tier', (
    WidgetTester tester,
  ) async {
    // Give the test surface enough room for the full dashboard layout.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NetworkHealthProvider(autoStart: false),
        child: const MaterialApp(home: NetworkDiagnosticsDashboardScreen()),
      ),
    );

    // Title and controls are present.
    expect(find.text('Network Diagnostic Dashboard'), findsOneWidget);
    expect(find.text('Run Diagnostics'), findsOneWidget);
    expect(find.text('Connection Health'), findsOneWidget);

    // Idle / download / upload phase cards are present.
    expect(find.text('Idle Ping'), findsOneWidget);
    expect(find.text('Download Bandwidth'), findsOneWidget);
    expect(find.text('Upload Bandwidth'), findsOneWidget);

    // Exercise the actual toolbar with narrow title space and a back button.
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    tester.view.physicalSize = const Size(391.2, 800);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: appBar.title,
            actions: appBar.actions,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Network Diagnostic Dashboard'), findsOneWidget);
  });
}
