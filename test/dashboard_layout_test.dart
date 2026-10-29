import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_activity1_appdev/providers/network_health_provider.dart';
import 'package:flutter_activity1_appdev/services/network_diagnostics_service.dart';
import 'package:flutter_activity1_appdev/screens/activities/network_diagnostics_dashboard_screen.dart';

class _SnapshotHealth extends NetworkHealthProvider {
  _SnapshotHealth(this.running) : super(autoStart: false);
  final bool running;
  @override
  bool get isRunning => running;
  @override
  DiagnosticPhase get activePhase => DiagnosticPhase.download;
  @override
  NetworkTestResults get latest {
    final ping = PingStats(
      samples: [1234],
      min: 1234,
      avg: 1234,
      max: 1234,
      packetLossPercent: 25.5,
    );
    return NetworkTestResults(
      startedAt: DateTime.now(),
      idlePing: ping,
      download: DownloadResult(
        megabitsPerSecond: 123.4,
        bytesTransferred: 12345678,
        durationMs: 12345,
        concurrentPing: ping,
      ),
      upload: UploadResult(
        megabitsPerSecond: 12.3,
        bytesTransferred: 1234567,
        durationMs: 12345,
        uploadPing: ping,
      ),
    );
  }

  @override
  List<DiagnosticLogEntry> get log => [
    DiagnosticLogEntry(message: 'Download measurement with concurrent ping'),
  ];
}

void main() {
  for (final width in [272.0, 320.0, 400.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final running in [false, true]) {
        testWidgets('Dashboard $width px, scale $scale, running $running', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ChangeNotifierProvider<NetworkHealthProvider>(
              create: (_) => _SnapshotHealth(running),
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const NetworkDiagnosticsDashboardScreen(),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 14; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -400),
            );
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Diagnostic Console'), findsOneWidget);
        });
      }
    }
  }
}
