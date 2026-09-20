import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// Operational health tiers for the network connection.
///
/// These match the assignment spec:
///   • Excellent — download bandwidth >  10 Mbps
///   • Fair      — download bandwidth    2 – 10 Mbps
///   • Poor      — download bandwidth   <  2 Mbps
///   • Degraded  — heavy packet loss (≥ 10%) or extreme latency (≥ 500 ms)
/// ─────────────────────────────────────────────────────────────────────────────
enum NetworkHealthTier {
  excellent('Excellent', '> 10 Mbps download', 0xFF10B981),
  fair('Fair', '2 – 10 Mbps download', 0xFFF59E0B),
  poor('Poor', '< 2 Mbps download', 0xFFEF4444),
  degraded('Degraded', 'Heavy packet loss / extreme latency', 0xFF8B5CF6),
  unknown('Unknown', 'No measurements available yet', 0xFF94A3B8);

  const NetworkHealthTier(this.label, this.description, this.colorValue);

  final String label;
  final String description;
  final int colorValue;

  int get level => switch (this) {
        NetworkHealthTier.excellent => 5,
        NetworkHealthTier.fair => 4,
        NetworkHealthTier.poor => 3,
        NetworkHealthTier.degraded => 2,
        NetworkHealthTier.unknown => 1,
      };

  /// Readable color for UI widgets.
  static Color fromValue(int value) => Color(value | 0xFF000000);
}

/// The three phases of a diagnostic run.
enum DiagnosticPhase {
  idlePing('Idle Ping', 'Baseline latency while the link is idle'),
  download('Download Bandwidth', 'Bandwidth + ping under download load'),
  upload('Upload Bandwidth', 'Bandwidth + ping under upload load');

  const DiagnosticPhase(this.label, this.description);

  final String label;
  final String description;
}

/// Aggregated ping statistics for one phase.
class PingStats {
  PingStats({
    required this.samples,
    required this.min,
    required this.avg,
    required this.max,
    required this.packetLossPercent,
  });

  factory PingStats.empty() =>
      PingStats(samples: [], min: 0, avg: 0, max: 0, packetLossPercent: 100);

  /// Successful round-trip samples (milliseconds).
  final List<int> samples;

  final int min;
  final int avg;
  final int max;
  final double packetLossPercent;

  bool get hasData => samples.isNotEmpty;
}

/// Results for the download phase.
class DownloadResult {
  DownloadResult({
    required this.megabitsPerSecond,
    required this.bytesTransferred,
    required this.durationMs,
    required this.concurrentPing,
  });

  final double megabitsPerSecond;
  final int bytesTransferred;
  final int durationMs;
  final PingStats concurrentPing;
}

/// Results for the upload phase.
class UploadResult {
  UploadResult({
    required this.megabitsPerSecond,
    required this.bytesTransferred,
    required this.durationMs,
    required this.uploadPing,
  });

  final double megabitsPerSecond;
  final int bytesTransferred;
  final int durationMs;
  final PingStats uploadPing;
}

/// Complete snapshot of one diagnostic run.
class NetworkTestResults {
  NetworkTestResults({
    required this.startedAt,
    this.idlePing,
    this.download,
    this.upload,
    this.notes = const [],
  });

  final DateTime startedAt;
  final PingStats? idlePing;
  final DownloadResult? download;
  final UploadResult? upload;
  final List<String> notes;

  NetworkHealthTier get tier => NetworkDiagnosticsService.classify(this);

  Duration get totalDuration =>
      DateTime.now().difference(startedAt).isNegative
          ? Duration.zero
          : DateTime.now().difference(startedAt);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// The diagnostic tool.
///
/// Runs a three-phase network test in sequence:
///   1. [measureIdlePing]   – baseline "idle ping" (latency in a quiet link).
///   2. [measureDownload]   – stream a large payload while concurrently firing
///                            ping probes to capture download ping.
///   3. [measureUpload]     – stream a payload to the server while
///                            simultaneously tracking the upload ping.
///
/// Measurements are HTTP-based so they work on every supported platform
/// without extra native privileges (no raw ICMP sockets needed).
///
/// The default target is Cloudflare's public speed-test service
/// (https://speed.cloudflare.com), which powers the official Cloudflare
/// speed test and exposes lightweight download/upload endpoints.
/// ─────────────────────────────────────────────────────────────────────────────
class NetworkDiagnosticsService {
  NetworkDiagnosticsService({
    String baseUrl = 'https://speed.cloudflare.com',
    this.pingProbes = 5,
    this.pingProbeInterval = const Duration(milliseconds: 250),
    this.downloadBytes = 10 * 1024 * 1024, // 10 MB
    this.uploadBytes = 2 * 1024 * 1024, // 2 MB
    this.pingTimeout = const Duration(seconds: 5),
    this.transferTimeout = const Duration(seconds: 45),
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final int pingProbes;
  final Duration pingProbeInterval;
  final int downloadBytes;
  final int uploadBytes;
  final Duration pingTimeout;
  final Duration transferTimeout;

  /// Emitted continuously while a run is in progress so the UI can show
  /// live progress and a textual log.
  final _progress = StreamController<DiagnosticLogEntry>.broadcast();

  Stream<DiagnosticLogEntry> get progressStream => _progress.stream;

  bool _pingInFlight = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Run the full diagnostic sequence and return the aggregated results.
  Future<NetworkTestResults> runDiagnostics({
    void Function(DiagnosticPhase phase)? onPhaseStarted,
  }) async {
    final startedAt = DateTime.now();
    final notes = <String>[];

    // ── Phase 1: baseline idle ping ────────────────────────────────────────
    onPhaseStarted?.call(DiagnosticPhase.idlePing);
    _emit('📡 Phase 1/3 — Measuring idle ping ($pingProbes probes)…');
    final idlePing = await measureIdlePing();

    // ── Phase 2: download bandwidth + concurrent ping ──────────────────────
    onPhaseStarted?.call(DiagnosticPhase.download);
    _emit(
        '⬇️ Phase 2/3 — Downloading ${_formatBytes(downloadBytes)} while measuring ping…');
    DownloadResult? download;
    try {
      download = await measureDownload();
      _emit(
          '⬇️ Download finished: ${download.megabitsPerSecond.toStringAsFixed(1)} Mbps '
          '(avg ping ${download.concurrentPing.avg} ms).');
    } catch (e) {
      notes.add('Download test failed: $e');
      _emit('⚠️ Download test failed: $e');
    }

    // ── Phase 3: upload bandwidth + upload ping ─────────────────────────────
    onPhaseStarted?.call(DiagnosticPhase.upload);
    _emit(
        '⬆️ Phase 3/3 — Uploading ${_formatBytes(uploadBytes)} while tracking upload ping…');
    UploadResult? upload;
    try {
      upload = await measureUpload();
      _emit(
          '⬆️ Upload finished: ${upload.megabitsPerSecond.toStringAsFixed(1)} Mbps '
          '(upload ping ${upload.uploadPing.avg} ms).');
    } catch (e) {
      notes.add('Upload test failed: $e');
      _emit('⚠️ Upload test failed: $e');
    }

    final results = NetworkTestResults(
      startedAt: startedAt,
      idlePing: idlePing,
      download: download,
      upload: upload,
      notes: notes,
    );

    final tier = results.tier;
    _emit('🏷️ Connection health: $tier.label — $tier.description.');

    return results;
  }

  /// Phase 1: measure baseline latency in the idle link.
  Future<PingStats> measureIdlePing() => _probePings(
        count: pingProbes,
        interval: pingProbeInterval,
        label: 'idle ping',
      );

  /// Phase 2: stream a large download while concurrently probing ping.
  Future<DownloadResult> measureDownload() async {
    final uri = Uri.parse('$_baseUrl/__down?bytes=$downloadBytes');
    final request = http.Request('GET', uri);
    final stopwatch = Stopwatch()..start();
    var received = 0;

    final concurrentPing = <PingStats>[];
    late Timer probeTimer;
    probeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_fireProbe(concurrentPing));
    });

    http.StreamedResponse response;
    try {
      final streamed = await _client.send(request).timeout(transferTimeout);
      response = streamed;
      if (response.statusCode != 200) {
        throw Exception('Download HTTP ${response.statusCode}');
      }
      await response.stream.forEach((chunk) {
        received += chunk.length;
      });
    } finally {
      probeTimer.cancel();
      stopwatch.stop();
    }

    final ping = _mergeProbeResults(concurrentPing);
    final megabits = (received * 8) / (stopwatch.elapsedMilliseconds / 1000) / 1e6;

    return DownloadResult(
      megabitsPerSecond: megabits,
      bytesTransferred: received,
      durationMs: stopwatch.elapsedMilliseconds,
      concurrentPing: ping,
    );
  }

  /// Phase 3: stream an upload while simultaneously tracking upload ping.
  Future<UploadResult> measureUpload() async {
    final uri = Uri.parse('$_baseUrl/__up');
    final request = http.StreamedRequest('POST', uri);
    request.headers['content-type'] = 'application/octet-stream';

    // Stream a realistic upload payload from repeated 256 KB chunks instead
    // of allocating the entire body in memory.
    const chunkSize = 256 * 1024;
    final chunkCount = (uploadBytes / chunkSize).ceil();
    final rng = Random();
    Uint8List nextChunk() {
      final bytes = Uint8List(chunkSize);
      for (var i = 0; i < chunkSize; i++) {
        bytes[i] = rng.nextInt(256);
      }
      return bytes;
    }

    request.sink
        .addStream(
          Stream.fromIterable(List.generate(chunkCount, (_) => nextChunk())),
        )
        .then((_) => request.sink.close());

    final stopwatch = Stopwatch()..start();
    final uploadPing = <PingStats>[];
    late Timer probeTimer;
    probeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_fireProbe(uploadPing));
    });

    try {
      final response = await _client.send(request).timeout(transferTimeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Upload HTTP ${response.statusCode}');
      }
      await response.stream.drain<void>();
    } finally {
      probeTimer.cancel();
      stopwatch.stop();
    }

    final ping = _mergeProbeResults(uploadPing);
    final megabits =
        (uploadBytes * 8) / (stopwatch.elapsedMilliseconds / 1000) / 1e6;

    return UploadResult(
      megabitsPerSecond: megabits,
      bytesTransferred: uploadBytes,
      durationMs: stopwatch.elapsedMilliseconds,
      uploadPing: ping,
    );
  }

  /// Close the underlying HTTP client.
  void dispose() {
    _client.close();
    _progress.close();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Fire a single ping probe and append its stats to [collector].
  /// Guards against overlapping probes.
  Future<void> _fireProbe(List<PingStats> collector) async {
    if (_pingInFlight) return;
    _pingInFlight = true;
    try {
      final stats = await _probePings(
        count: 1,
        interval: Duration.zero,
        label: 'concurrent ping',
      );
      collector.add(stats);
    } finally {
      _pingInFlight = false;
    }
  }

  /// Send [count] ping probes (HTTP GET round trips) and compute stats.
  Future<PingStats> _probePings({
    required int count,
    required Duration interval,
    required String label,
  }) async {
    final rtts = <int>[];
    var lost = 0;

    for (var i = 0; i < count; i++) {
      final rtt = await _singlePing();
      if (rtt == null) {
        lost++;
      } else {
        rtts.add(rtt);
      }
      if (i < count - 1 && interval > Duration.zero) {
        await Future<void>.delayed(interval);
      }
    }

    final total = count;
    final avg = rtts.isEmpty
        ? 0
        : (rtts.reduce((a, b) => a + b) / rtts.length).round();

    return PingStats(
      samples: rtts,
      min: rtts.isEmpty ? 0 : rtts.reduce(min),
      avg: avg,
      max: rtts.isEmpty ? 0 : rtts.reduce(max),
      packetLossPercent: (lost / total) * 100,
    );
  }

  /// One ping probe — returns RTT in ms, or null on failure/timeout (loss).
  Future<int?> _singlePing() async {
    final uri = Uri.parse('$_baseUrl/__down?bytes=1');
    final sw = Stopwatch()..start();
    try {
      final response =
          await _client.get(uri).timeout(pingTimeout);
      sw.stop();
      if (response.statusCode != 200) return null;
      return sw.elapsedMilliseconds;
    } catch (_) {
      sw.stop();
      return null;
    }
  }

  /// Combine repeated single-probe results into one PingStats.
  PingStats _mergeProbeResults(List<PingStats> probes) {
    final samples = <int>[];
    for (final p in probes) {
      samples.addAll(p.samples);
    }
    // A probe entry without samples counts as a lost packet.
    final lost = probes.where((p) => p.samples.isEmpty).length;

    return PingStats(
      samples: samples,
      min: samples.isEmpty ? 0 : samples.reduce(min),
      avg: samples.isEmpty
          ? 0
          : (samples.reduce((a, b) => a + b) / samples.length).round(),
      max: samples.isEmpty ? 0 : samples.reduce(max),
      packetLossPercent: probes.isEmpty ? 0 : (lost / probes.length) * 100,
    );
  }

  void _emit(String message) {
    if (!_progress.isClosed) {
      _progress.add(DiagnosticLogEntry(message: message));
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  /// ── Threshold logic ──────────────────────────────────────────────────────
  /// Analyze [results] and group the connection into an operational tier.
  static NetworkHealthTier classify(NetworkTestResults results) {
    final idle = results.idlePing;
    final hasIdle = idle != null;
    // Only treat measured loss/latency as degradation signals. When there is
    // no idle-ping data at all (e.g. the ping phase never ran), we fall back
    // to the transfer results instead of assuming the worst.
    final loss = idle?.packetLossPercent ?? 0;
    final avgPing = idle?.avg ?? 0;
    final maxPing = idle?.max ?? 0;

    final degradedByLoss = hasIdle && loss >= 10;
    final degradedByLatency = hasIdle && (avgPing >= 500 || maxPing >= 1000);
    // A fully failed run (e.g. offline) reports 100% loss → Degraded.
    if (degradedByLoss || degradedByLatency) {
      return NetworkHealthTier.degraded;
    }

    // If idle ping was unreachable but phases succeeded, fall back to transfer.
    final down = results.download?.megabitsPerSecond;

    if (down != null) {
      if (down > 10) return NetworkHealthTier.excellent;
      if (down >= 2) return NetworkHealthTier.fair;
      return NetworkHealthTier.poor;
    }

    // No download data; use upload as a secondary signal.
    final up = results.upload?.megabitsPerSecond;
    if (up != null) {
      if (up > 10) return NetworkHealthTier.excellent;
      if (up >= 2) return NetworkHealthTier.fair;
      return NetworkHealthTier.poor;
    }

    return NetworkHealthTier.unknown;
  }
}

/// A timestamped log line for the live diagnostic console.
class DiagnosticLogEntry {
  DiagnosticLogEntry({required this.message}) : timestamp = DateTime.now();

  final DateTime timestamp;
  final String message;
}