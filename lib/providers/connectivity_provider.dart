import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'request_queue_service.dart';

enum NetStatus { wifi, cellular, offline }

class ConnectivityProvider extends ChangeNotifier {
  NetStatus _status = NetStatus.offline;
  NetStatus get status => _status;

  late StreamSubscription<List<ConnectivityResult>> _sub;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final initial = await Connectivity().checkConnectivity();
    _update(initial);
    _sub = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final prevStatus = _status;

    if (results.contains(ConnectivityResult.wifi)) {
      _status = NetStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _status = NetStatus.cellular;
    } else {
      _status = NetStatus.offline;
    }

    notifyListeners();

    // Trigger recovery when transitioning from offline → connected
    if (prevStatus == NetStatus.offline && _status != NetStatus.offline) {
      RequestQueueService.instance.retryQueued();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
