import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

/// Shows the network transport independently of measured internet quality.
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<ConnectivityProvider>().status;
    final (label, icon) = switch (status) {
      NetStatus.wifi => ('Wi-Fi Connected', Icons.wifi_rounded),
      NetStatus.cellular => (
        'Cellular Connected',
        Icons.signal_cellular_alt_rounded,
      ),
      NetStatus.offline => ('Offline', Icons.wifi_off_rounded),
    };
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
