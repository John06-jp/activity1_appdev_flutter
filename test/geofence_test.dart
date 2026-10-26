import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_activity1_appdev/models/local_spot.dart';

void main() {
  final spot = LocalSpot.fromJson({
    'id': 'test',
    'name': 'Test fence',
    'description': 'Synthetic test only',
    'barangay': 'Test',
    'latitude': 0,
    'longitude': 0,
    'radiusMeters': 50,
    'verified': true,
  });
  late FenceTracker tracker;
  late DateTime time;
  setUp(() {
    tracker = FenceTracker();
    time = DateTime.utc(2026, 1, 1);
  });
  List<Map<String, dynamic>> read(
    double lat, {
    double accuracy = 5,
    int age = 0,
  }) {
    time = time.add(const Duration(seconds: 1));
    return tracker.update(
      [spot],
      latitude: lat,
      longitude: 0,
      accuracy: accuracy,
      timestamp: time.subtract(Duration(seconds: age)),
      now: time,
    );
  }

  test(
    'initial reading is silent and transitions fire once after three confirmations',
    () {
      expect(read(0.002), isEmpty);
      expect(tracker.states['test'], FenceState.outside);
      expect(read(0), isEmpty);
      expect(read(0), isEmpty);
      expect(read(0).single['eventType'], 'entry');
      expect(read(0), isEmpty);
      expect(read(0.002), isEmpty);
      expect(read(0.002), isEmpty);
      expect(read(0.002).single['eventType'], 'exit');
    },
  );
  test('starting inside creates no fabricated entry', () {
    expect(read(0), isEmpty);
    expect(tracker.states['test'], FenceState.inside);
  });
  test('poor and stale readings interrupt transition confirmation', () {
    read(0.002);
    read(0);
    read(0, accuracy: 60);
    expect(read(0), isEmpty);
    read(0, age: 20);
    expect(read(0), isEmpty);
    expect(read(0), isEmpty);
    expect(read(0).single['eventType'], 'entry');
  });
  test('boundary uncertainty postpones a transition', () {
    read(0.002);
    for (var i = 0; i < 5; i++) {
      expect(read(0.00044, accuracy: 10), isEmpty);
    }
    expect(tracker.states['test'], FenceState.outside);
  });
  test('reset discards status and pending confirmations', () {
    read(0.002);
    read(0);
    read(0);
    tracker.reset();
    expect(read(0), isEmpty);
    expect(tracker.states['test'], FenceState.inside);
  });
  test('unverified locations are excluded', () {
    final pending = LocalSpot.fromJson({
      'id': 'pending',
      'name': 'Pending',
      'description': '',
      'barangay': 'Test',
      'latitude': null,
      'longitude': null,
      'radiusMeters': 50,
      'verified': false,
    });
    expect(pending.ready, isFalse);
  });
}
