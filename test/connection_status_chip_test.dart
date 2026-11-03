import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_activity1_appdev/providers/connectivity_provider.dart';
import 'package:flutter_activity1_appdev/widgets/connection_status_chip.dart';

class _Connection extends ConnectivityProvider {
  _Connection() : super(autoStart: false);
  NetStatus current = NetStatus.offline;
  @override
  NetStatus get status => current;
  void changeTo(NetStatus value) {
    current = value;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Connection indicator follows Wi-Fi, cellular and offline changes',
    (tester) async {
      final connection = _Connection();
      await tester.pumpWidget(
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => connection,
          child: const MaterialApp(
            home: Scaffold(body: ConnectionStatusChip()),
          ),
        ),
      );
      expect(find.text('Offline'), findsOneWidget);
      connection.changeTo(NetStatus.wifi);
      await tester.pump();
      expect(find.text('Wi-Fi Connected'), findsOneWidget);
      connection.changeTo(NetStatus.cellular);
      await tester.pump();
      expect(find.text('Cellular Connected'), findsOneWidget);
      expect(find.text('Wi-Fi Connected'), findsNothing);
      connection.changeTo(NetStatus.offline);
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
    },
  );
}
