import 'dart:math' as math;

class LocalSpot {
  LocalSpot.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      description = json['description'] as String,
      barangay = json['barangay'] as String,
      latitude = (json['latitude'] as num?)?.toDouble(),
      longitude = (json['longitude'] as num?)?.toDouble(),
      radius = (json['radiusMeters'] as num).toDouble(),
      verified = json['verified'] == true;

  final String id, name, description, barangay;
  final double? latitude, longitude;
  final double radius;
  final bool verified;
  bool get ready =>
      verified &&
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180 &&
      radius.isFinite &&
      radius > 0;
}

enum FenceState { unknown, inside, outside }

/// Foreground fence detection. Initial readings establish a baseline silently.
class FenceTracker {
  final Map<String, FenceState> states = {};
  final Map<String, double> distances = {};
  final Map<String, FenceState> _candidates = {};
  final Map<String, int> _counts = {};
  DateTime? _lastTimestamp;

  void reset() {
    states.clear();
    distances.clear();
    _candidates.clear();
    _counts.clear();
    _lastTimestamp = null;
  }

  void rejectReading() {
    _candidates.clear();
    _counts.clear();
  }

  List<Map<String, dynamic>> update(
    List<LocalSpot> spots, {
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    required DateTime now,
  }) {
    final age = now.difference(timestamp);
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        !accuracy.isFinite ||
        accuracy < 0 ||
        age > const Duration(seconds: 15) ||
        age.isNegative ||
        (_lastTimestamp != null && !timestamp.isAfter(_lastTimestamp!))) {
      rejectReading();
      return [];
    }
    _lastTimestamp = timestamp;
    final events = <Map<String, dynamic>>[];
    for (final spot in spots.where((s) => s.ready)) {
      final distance = distanceMeters(
        latitude,
        longitude,
        spot.latitude!,
        spot.longitude!,
      );
      distances[spot.id] = distance;
      if (accuracy > math.min(25, spot.radius / 2) ||
          (distance - spot.radius).abs() <= accuracy) {
        _counts.remove(spot.id);
        _candidates.remove(spot.id);
        continue;
      }
      final next = distance <= spot.radius
          ? FenceState.inside
          : FenceState.outside;
      final previous = states[spot.id] ?? FenceState.unknown;
      if (previous == FenceState.unknown) {
        states[spot.id] = next;
      } else if (previous != next) {
        _counts[spot.id] = _candidates[spot.id] == next
            ? (_counts[spot.id] ?? 0) + 1
            : 1;
        _candidates[spot.id] = next;
        if (_counts[spot.id]! >= 3) {
          states[spot.id] = next;
          _counts.remove(spot.id);
          _candidates.remove(spot.id);
          events.add({
            'locationId': spot.id,
            'locationName': spot.name,
            'eventType': next == FenceState.inside ? 'entry' : 'exit',
            'timestamp': timestamp.toUtc().toIso8601String(),
          });
        }
      } else {
        _counts.remove(spot.id);
        _candidates.remove(spot.id);
      }
    }
    return events;
  }

  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double rad(double value) => value * math.pi / 180;
    final a =
        math.pow(math.sin(rad(lat2 - lat1) / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(rad(lon2 - lon1) / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}
