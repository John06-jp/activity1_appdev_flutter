import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/request_queue_service.dart';
import '../../widgets/connection_status_chip.dart';
import '../../widgets/dashboard_feature_card.dart';

class ActivityTwoFeatureCard extends StatelessWidget {
  const ActivityTwoFeatureCard({super.key});

  @override
  Widget build(BuildContext context) => DashboardFeatureCard(
    title: 'Network Monitor',
    subtitle: 'Activity 2',
    description:
        'Monitor Wi-Fi and Cellular handovers with automatic request recovery.',
    icon: Icons.network_check_rounded,
    gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/activity-2/network-monitor'),
        builder: (_) => const NetworkMonitorScreen(),
      ),
    ),
  );
}

class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({super.key});

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  final List<LogEntry> _log = [];
  late final StreamSubscription<LogEntry> _logSub;
  bool _isFetching = false;
  final _queue = RequestQueueService.instance;

  @override
  void initState() {
    super.initState();
    _logSub = _queue.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _log.insert(0, entry);
          if (_log.length > 200) _log.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _logSub.cancel();
    super.dispose();
  }

  Future<void> _startFetch() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);
    final connection = context.read<ConnectivityProvider>();
    _queue.updateConnection(connection.status != NetStatus.offline);
    final id = 'dataset-${DateTime.now().microsecondsSinceEpoch}';
    // Captured by the queued task, so progress survives leaving this screen.
    var chunks = 0;
    await _queue.enqueue(
      QueuedRequest(id, () async {
        final revision = connection.revision;
        while (chunks < 20) {
          if (connection.status == NetStatus.offline) {
            throw StateError(
              'Connection lost; dataset saved at ${chunks * 5}%',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (connection.status == NetStatus.offline ||
              connection.revision != revision) {
            throw StateError(
              'Network changed; dataset saved at ${chunks * 5}%',
            );
          }
          chunks++;
          if (mounted) {
            setState(() {
              _log.insert(
                0,
                LogEntry(message: 'Dataset transfer: ${chunks * 5}%'),
              );
              if (_log.length > 200) _log.removeLast();
            });
          }
        }
      }),
    );
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectivityProvider>();
    final theme = Theme.of(context);
    final status = switch (connection.status) {
      NetStatus.wifi => 'Wi-Fi',
      NetStatus.cellular => 'Cellular',
      NetStatus.offline => 'Offline',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Network Monitor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Activity 2', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ConnectionStatusChip(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Active interface: $status',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Watch network changes live. Pending dataset requests wait while offline and retry automatically after reconnection.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text('${_queue.queueLength} queued requests'),
                      ),
                      if (_isFetching)
                        const Chip(label: Text('Transferring dataset')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isFetching ? null : _startFetch,
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text('Simulate Large Fetch'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _queue.queueLength == 0
                        ? null
                        : _queue.clearQueue,
                    child: const Text('Clear Queue'),
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Try it: start a simulated dataset fetch, then switch Wi-Fi off or enable Airplane Mode. Restore Wi-Fi or Cellular to resume from the last completed chunk. Network interface availability does not guarantee internet access.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Activity Log', style: theme.textTheme.titleMedium),
                      TextButton(
                        onPressed: _log.isEmpty
                            ? null
                            : () => setState(_log.clear),
                        child: const Text('Clear log'),
                      ),
                    ],
                  ),
                  if (_log.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No activity yet. Tap "Simulate Large Fetch" to begin.',
                      ),
                    ),
                  for (final entry in _log)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${entry.timestamp.toLocal().toString().substring(11, 19)}  ${entry.message}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
