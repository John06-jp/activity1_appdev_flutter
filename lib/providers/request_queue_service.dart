import 'dart:async';

/// Represents a single queued request with a unique ID and an async task.
class QueuedRequest {
  final String id;
  final Future<void> Function() task;
  int retryCount = 0;

  QueuedRequest(this.id, this.task);
}

/// Log entry with timestamp for the network monitor UI.
class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry({required this.message}) : timestamp = DateTime.now();
}

/// Singleton service that enqueues failed requests and retries them
/// when connectivity is restored.
class RequestQueueService {
  RequestQueueService();
  static final RequestQueueService instance = RequestQueueService();

  bool _online = false;
  bool _retrying = false;
  bool _disposed = false;
  Timer? _retryTimer;
  int _generation = 0;

  /// Wait for the interface to settle before starting/retrying requests.
  void updateConnection(bool online) {
    _online = online;
    _retryTimer?.cancel();
    if (online) _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed || !_online || _queue.isEmpty) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 1), retryQueued);
  }

  final List<QueuedRequest> _queue = [];
  final _logController = StreamController<LogEntry>.broadcast();

  /// Stream of log entries for the UI to display in real time.
  Stream<LogEntry> get logStream => _logController.stream;

  /// How many requests are currently queued (pending retry).
  int get queueLength => _queue.length;

  /// Attempt to run [request] immediately. On failure, queue it for retry.
  Future<void> enqueue(QueuedRequest request) async {
    final generation = _generation;
    try {
      if (!_online) throw StateError('Waiting for Wi-Fi or Cellular');
      _emit('🚀 Starting "${request.id}"…');
      await request.task();
      _emit('✅ "${request.id}" completed successfully.');
    } catch (e) {
      _emit('⚠️ "${request.id}" failed — queued for retry.\n   Reason: $e');
      if (!_disposed &&
          generation == _generation &&
          !_queue.contains(request)) {
        _queue.add(request);
        _scheduleRetry();
      }
    }
  }

  /// Called automatically by [ConnectivityProvider] when going offline → online.
  Future<void> retryQueued() async {
    if (_disposed || !_online || _retrying) return;
    _retrying = true;
    try {
      if (_queue.isEmpty) {
        _emit('🔍 Reconnected — no pending requests to retry.');
        return;
      }

      _emit(
        '📶 Connection restored — retrying ${_queue.length} queued request(s)…',
      );
      final pending = List<QueuedRequest>.from(_queue);

      for (final req in pending) {
        if (!_online || !_queue.remove(req)) break;
        req.retryCount++;
        _emit('🔄 Retrying "${req.id}" (attempt #${req.retryCount})…');
        await enqueue(req); // re-queues again if it fails a second time
      }
    } finally {
      _retrying = false;
      _scheduleRetry();
    }
  }

  /// Clear all queued requests.
  void clearQueue() {
    _generation++;
    _retryTimer?.cancel();
    _queue.clear();
    _emit('🗑️ Queue cleared.');
  }

  void _emit(String message) {
    if (!_logController.isClosed) {
      _logController.add(LogEntry(message: message));
    }
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _logController.close();
  }
}
