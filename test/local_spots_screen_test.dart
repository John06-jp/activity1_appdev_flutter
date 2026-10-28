import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_activity1_appdev/screens/activities/local_spots_screen.dart';

void main() {
  for (final corruptHistory in [false, true]) {
    testWidgets('Five flags are visible with corrupt history: $corruptHistory',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        if (corruptHistory) 'local_spots_events': 'invalid saved history',
      });
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: LocalSpotsScreen(
            tileProvider: NetworkTileProvider(
              cachingProvider: const DisabledMapCachingProvider(),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(find.text('Pending verification'), findsNothing);
      expect(find.text('Verified sample location'), findsNWidgets(5));
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers, hasLength(5));
      expect(markerLayer.markers.first.point.latitude, 8.7160);
      expect(markerLayer.markers.first.point.longitude, 125.7470);

      final mapRect = tester.getRect(find.byType(FlutterMap));
      for (final name in [
        'My Home',
        'Friend’s Home',
        'Family Garden',
        'Neighborhood Rest Spot',
        'Local Scenic Spot',
      ]) {
        final flag = find.byTooltip(name);
        expect(flag, findsOneWidget);
        final flagRect = tester.getRect(flag);
        expect(mapRect.contains(flagRect.topLeft), isTrue, reason: name);
        expect(mapRect.contains(flagRect.bottomRight), isTrue, reason: name);
      }
      await tester.tap(find.byTooltip('My Home'));
      await tester.pumpAndSettle();
      expect(find.text('Focus on map'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
