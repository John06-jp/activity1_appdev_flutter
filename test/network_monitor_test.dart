import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_activity1_appdev/providers/connectivity_provider.dart';
import 'package:flutter_activity1_appdev/providers/request_queue_service.dart';
import 'package:flutter_activity1_appdev/screens/activities/network_monitor_screen.dart';

class _Connection extends ConnectivityProvider {
  _Connection() : super(autoStart: false);
  NetStatus current = NetStatus.offline;
  int changes = 0;
  @override
  NetStatus get status => current;
  @override
  int get revision => changes;
  void switchTo(NetStatus value) {
    current = value;
    changes++;
    RequestQueueService.instance.updateConnection(value != NetStatus.offline);
    notifyListeners();
  }
}

void main() {
  testWidgets('Offline requests wait and retry after reconnection', (
    tester,
  ) async {
    final queue = RequestQueueService();
    addTearDown(queue.dispose);
    var attempts = 0;
    await queue.enqueue(
      QueuedRequest('offline', () async {
        attempts++;
      }),
    );
    expect(queue.queueLength, 1);
    expect(attempts, 0);
    queue.updateConnection(true);
    await tester.pump(const Duration(seconds: 1));
    expect(attempts, 1);
    expect(queue.queueLength, 0);
  });

  testWidgets('Failure after reconnection still retries without overlapping', (
    tester,
  ) async {
    final queue = RequestQueueService();
    addTearDown(queue.dispose);
    queue.updateConnection(true);
    final transfer = Completer<void>();
    var attempts = 0;
    final pending = queue.enqueue(
      QueuedRequest('handover', () async {
        attempts++;
        if (attempts == 1) await transfer.future;
      }),
    );
    queue.updateConnection(false);
    queue.updateConnection(true);
    transfer.completeError(StateError('Old IP connection failed'));
    await pending;
    expect(queue.queueLength, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(attempts, 2);
    expect(queue.queueLength, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(attempts, 2);
  });

  testWidgets('Activity 2 navigates, queues a handover, and resumes progress', (
    tester,
  ) async {
    final connection = _Connection()..switchTo(NetStatus.wifi);
    final queue = RequestQueueService.instance;
    addTearDown(() {
      queue.clearQueue();
      queue.updateConnection(false);
      connection.dispose();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connection,
        child: const MaterialApp(
          home: Scaffold(body: ActivityTwoFeatureCard()),
        ),
      ),
    );
    await tester.tap(find.text('Network Monitor'));
    await tester.pumpAndSettle();
    expect(find.text('Wi-Fi Connected'), findsOneWidget);
    await tester.tap(find.text('Simulate Large Fetch'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Dataset transfer: 5%'), findsOneWidget);
    connection.switchTo(NetStatus.cellular);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Cellular Connected'), findsOneWidget);
    expect(queue.queueLength, 1);
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < 19; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.textContaining('Dataset transfer: 100%'), findsOneWidget);
    expect(queue.queueLength, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [240.0, 375.0, 1024.0]) {
    testWidgets('Monitor fits $width px with large text', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(autoStart: false),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const NetworkMonitorScreen(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
