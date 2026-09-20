import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_activity1_appdev/services/network_diagnostics_service.dart';

/// Build a results object for classification tests.
NetworkTestResults _results({
  PingStats? idlePing,
  double? downloadMbps,
  double? uploadMbps,
}) {
  return NetworkTestResults(
    startedAt: DateTime.now(),
    idlePing: idlePing,
    download: downloadMbps == null
        ? null
        : DownloadResult(
            megabitsPerSecond: downloadMbps,
            bytesTransferred: 10 * 1024 * 1024,
            durationMs: 1000,
            concurrentPing: PingStats.empty(),
          ),
    upload: uploadMbps == null
        ? null
        : UploadResult(
            megabitsPerSecond: uploadMbps,
            bytesTransferred: 2 * 1024 * 1024,
            durationMs: 1000,
            uploadPing: PingStats.empty(),
          ),
  );
}

PingStats _ping({int avg = 25, double loss = 0}) => PingStats(
      samples: [avg, avg + 5, avg - 3],
      min: avg - 3,
      avg: avg,
      max: avg + 5,
      packetLossPercent: loss,
    );

void main() {
  group('NetworkDiagnosticsService.classify', () {
    test('Excellent when download > 10 Mbps', () {
      final r = _results(idlePing: _ping(), downloadMbps: 42.5);
      expect(NetworkDiagnosticsService.classify(r),
          NetworkHealthTier.excellent);
    });

    test('Fair when download is 2 – 10 Mbps', () {
      for (final speed in [2.0, 3.7, 9.9, 10.0]) {
        final r = _results(idlePing: _ping(), downloadMbps: speed);
        expect(NetworkDiagnosticsService.classify(r), NetworkHealthTier.fair,
            reason: 'speed $speed should be Fair');
      }
    });

    test('Poor when download < 2 Mbps', () {
      final r = _results(idlePing: _ping(), downloadMbps: 1.2);
      expect(
          NetworkDiagnosticsService.classify(r), NetworkHealthTier.poor);
    });

    test('Degraded on heavy packet loss even with fast download', () {
      final r = _results(
        idlePing: _ping(loss: 25),
        downloadMbps: 88.0,
      );
      expect(NetworkDiagnosticsService.classify(r),
          NetworkHealthTier.degraded);
    });

    test('Degraded on extreme latency even with fast download', () {
      final r = _results(idlePing: _ping(avg: 850), downloadMbps: 88.0);
      expect(NetworkDiagnosticsService.classify(r),
          NetworkHealthTier.degraded);
    });

    test('Degraded when totally offline (100% loss, no phases)', () {
      final r = _results(idlePing: _ping(loss: 100));
      expect(NetworkDiagnosticsService.classify(r),
          NetworkHealthTier.degraded);
    });

    test('Falls back to upload speed when download is unavailable', () {
      final r = _results(idlePing: _ping(), uploadMbps: 14.0);
      expect(NetworkDiagnosticsService.classify(r),
          NetworkHealthTier.excellent);
    });

    test('Unknown when there are no measurements', () {
      final r = _results();
      expect(
          NetworkDiagnosticsService.classify(r), NetworkHealthTier.unknown);
    });
  });
}