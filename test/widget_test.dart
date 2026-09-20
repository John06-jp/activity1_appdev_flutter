import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_activity1_appdev/providers/network_health_provider.dart';
import 'package:flutter_activity1_appdev/screens/activities/network_diagnostics_dashboard_screen.dart';

void main() {
  testWidgets('Network Diagnostic Dashboard renders with Unknown tier',
      (WidgetTester tester) async {
    // Give the test surface enough room for the full dashboard layout.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NetworkHealthProvider(autoStart: false),
        child: const MaterialApp(
          home: NetworkDiagnosticsDashboardScreen(),
        ),
      ),
    );

    // Title and controls are present.
    expect(
      find.text('Network Diagnostic Dashboard'),
      findsOneWidget,
    );
    expect(find.text('Run Diagnostics'), findsOneWidget);
    expect(find.text('Connection Health'), findsOneWidget);

    // Idle / download / upload phase cards are present.
    expect(find.text('Idle Ping'), findsOneWidget);
    expect(find.text('Download Bandwidth'), findsOneWidget);
    expect(find.text('Upload Bandwidth'), findsOneWidget);
  });
}