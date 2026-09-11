import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_activity1_appdev/main.dart';
import 'package:flutter_activity1_appdev/providers/app_provider.dart';

void main() {
  testWidgets('App loads home screen with portfolio title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const PortfolioMasterApp(),
      ),
    );

    // Verify that the dashboard title appears
    expect(find.text('Portfolio Dashboard'), findsOneWidget);
  });
}
