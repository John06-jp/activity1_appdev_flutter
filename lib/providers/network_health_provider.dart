import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/network_diagnostics_service.dart';

/// Global application state for network health.
///
/// Injected once at the root of the widget tree (see `main.dart`) so the
/// categorized connection health is broadcast across the entire app.
/// Any widget can `context.watch<NetworkHealthProvider>()` and rebuild when
/// the tier changes.
///
/// The provider owns the background [NetworkDiagnosticsService] and
/// re-runs the full (idle ping → download → upload) sequence periodically
/// so the app is always aware of the current operational tier.
class NetworkHealthProvider extends ChangeNotifier {
  NetworkHealthProvider({
    Duration monitorInterval = const Duration(minutes: 5),
    bool autoStart = true,
    NetworkDiagnosticsService? service,
  })  : _monitorInterval = monitorInterval,
        _service = service ?? NetworkDiagnosticsService() {
    if (autoStart) {
      startMonitoring();
    }
  }

  final NetworkDiagnosticsService _service;
  final Duration _monitorInterval;

  final List<DiagnosticLogEntry> _log = [];
  Timer? _timer;
  StreamSubscription<DiagnosticLogEntry>? _progressSub;
  int _runCounter = 0;

  NetworkHealthTier _tier = NetworkHealthTier.unknown;
  NetworkTestResults? _latest;
  bool _isRunning = false;
  DiagnosticPhase? _activePhase;

  // ── Getters (read by widgets across the app) ─────────────────────────────

  /// The current operational tier broadcast app-wide.
  NetworkHealthTier get tier => _latest?.tier ?? _tier;

  /// Latest completed run (null until the first run finishes).
  NetworkTestResults? get latest => _latest;

  /// True while a diagnostic run is executing.
  bool get isRunning => _isRunning;

  /// The phase currently being executed, when [isRunning] is true.
  DiagnosticPhase? get activePhase => _activePhase;

  /// How many completed diagnostic runs so far.
  int get runCount => _runCounter;

  /// Interval between automatic background runs.
  Duration get monitorInterval => _monitorInterval;

  /// Rolling log of diagnostic events/measurements.
  List<DiagnosticLogEntry> get log => List.unmodifiable(_log);

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start the background loop: run once shortly after startup, then repeat.
  void startMonitoring() {
    _progressSub ??= _service.progressStream.listen((entry) {
      _log.insert(0, entry);
      if (_log.length > 100) _log.removeRange(100, _log.length);
      _notify();
    });

    _timer?.cancel();
    _timer = Timer.periodic(_monitorInterval, (_) {
      unawaited(runDiagnosticsNow(background: true));
    });
    // Kick off an initial measurement shortly after launch.
    Timer(const Duration(seconds: 2), () {
      if (!_isRunning) {
        unawaited(runDiagnosticsNow(background: true));
      }
    });
  }

  /// Trigger a full diagnostic run (manual or background).
  Future<NetworkTestResults?> runDiagnosticsNow({bool background = false}) async {
    if (_isRunning) return _latest;

    _isRunning = true;
    _activePhase = null;
    _notify();

    if (!background) {
      _log.insert(0, DiagnosticLogEntry(message: '▶️ Manual diagnostic started…'));
    }

    final results = await _service.runDiagnostics(
      onPhaseStarted: (phase) {
        _activePhase = phase;
        _notify();
      },
    );

    _runCounter++;
    _latest = results;
    _tier = results.tier;
    _isRunning = false;
    _activePhase = null;

    _log.insert(
      0,
      DiagnosticLogEntry(
        message:
            '✅ Run #$_runCounter complete — tier: ${results.tier.label} '
            '(idle ${results.idlePing?.avg ?? '—'} ms, '
            'down ${results.download?.megabitsPerSecond.toStringAsFixed(1) ?? '—'} Mbps, '
            'up ${results.upload?.megabitsPerSecond.toStringAsFixed(1) ?? '—'} Mbps).',
      ),
    );
    if (_log.length > 100) _log.removeRange(100, _log.length);

    _notify();
    return results;
  }

  /// Clear the rolling log.
  void clearLog() {
    _log.clear();
    _notify();
  }

  void _notify() => notifyListeners();

  @override
  void dispose() {
    _timer?.cancel();
    _progressSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}