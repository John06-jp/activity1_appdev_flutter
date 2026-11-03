import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'request_queue_service.dart';

enum NetStatus { wifi, cellular, offline }

class ConnectivityProvider extends ChangeNotifier {
  NetStatus _status = NetStatus.offline;
  NetStatus get status => _status;
  int _revision = 0;
  int get revision => _revision;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _disposed = false;

  ConnectivityProvider({bool autoStart = true}) {
    if (autoStart) _init();
  }

  Future<void> _init() async {
    _sub = Connectivity().onConnectivityChanged.listen(
      _update,
      onError: (Object error) => _update([ConnectivityResult.none]),
    );
    final revision = _revision;
    try {
      final initial = await Connectivity().checkConnectivity();
      if (!_disposed && revision == _revision) _update(initial);
    } catch (_) {
      if (!_disposed && revision == _revision) {
        _update([ConnectivityResult.none]);
      }
    }
  }

  void _update(List<ConnectivityResult> results) {
    if (_disposed) return;
    final prevStatus = _status;

    if (results.contains(ConnectivityResult.wifi)) {
      _status = NetStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _status = NetStatus.cellular;
    } else {
      _status = NetStatus.offline;
    }

    if (prevStatus != _status) _revision++;
    RequestQueueService.instance.updateConnection(_status != NetStatus.offline);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
