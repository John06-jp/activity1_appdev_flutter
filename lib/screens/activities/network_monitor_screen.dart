import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/request_queue_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simulated large-dataset fetch that checks connectivity each chunk.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _simulateFetch(
  ConnectivityProvider conn, {
  required void Function(String) onProgress,
}) async {
  for (int i = 0; i <= 100; i += 10) {
    if (conn.status == NetStatus.offline) {
      throw Exception('Connection dropped mid-transfer at $i%');
    }
    onProgress('  ⏳ Transferring… $i%');
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({super.key});

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  final List<_LogRow> _log = [];
  late StreamSubscription<LogEntry> _logSub;
  final ScrollController _scrollController = ScrollController();
  bool _isFetching = false;
  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    _logSub = RequestQueueService.instance.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _log.add(_LogRow(entry: entry));
        });
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _logSub.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addLocalLog(String msg) {
    if (mounted) {
      setState(() {
        _log.add(_LogRow(entry: LogEntry(message: msg)));
      });
      _scrollToBottom();
    }
  }

  Future<void> _startFetch() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);
    _requestCounter++;
    final id = 'dataset-fetch-$_requestCounter';
    final conn = context.read<ConnectivityProvider>();

    await RequestQueueService.instance.enqueue(
      QueuedRequest(id, () => _simulateFetch(conn, onProgress: _addLocalLog)),
    );

    if (mounted) setState(() => _isFetching = false);
  }

  void _clearLog() => setState(() => _log.clear());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conn = context.watch<ConnectivityProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.network_check_rounded,
                  color: colorScheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Network Monitor'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear log',
            onPressed: _log.isEmpty ? null : _clearLog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Live Status Banner ──────────────────────────────────────────
            _StatusBanner(status: conn.status),

            // ── Quick stats row ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Queued',
                    value:
                        '${RequestQueueService.instance.queueLength}',
                    icon: Icons.hourglass_empty_rounded,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Log entries',
                    value: '${_log.length}',
                    icon: Icons.list_alt_rounded,
                    color: colorScheme.secondary,
                  ),
                  const Spacer(),
                  if (_isFetching)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Transferring…',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Action Buttons ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isFetching ? null : _startFetch,
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: const Text('Simulate Large Fetch'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      RequestQueueService.instance.clearQueue();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear Queue'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Connectivity how-to hint ────────────────────────────────────
            _HintCard(isDark: isDark),

            const SizedBox(height: 12),

            // ── Log Panel Title ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.terminal_rounded,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Activity Log',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Scrollable Log Panel ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _LogPanel(
                  log: _log,
                  scrollController: _scrollController,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final NetStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, label, icon, detail) = switch (status) {
      NetStatus.wifi => (
          const Color(0xFF10B981),
          'Wi-Fi Connected',
          Icons.wifi_rounded,
          'Stable high-speed connection'
        ),
      NetStatus.cellular => (
          const Color(0xFFF59E0B),
          'Cellular Connected',
          Icons.signal_cellular_alt_rounded,
          'Mobile data active'
        ),
      NetStatus.offline => (
          const Color(0xFFEF4444),
          'Offline',
          Icons.wifi_off_rounded,
          'No network connection detected'
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Pulsing icon
          _PulsingIcon(icon: icon, color: color, isActive: status != NetStatus.offline),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == NetStatus.offline
                      ? Icons.circle_outlined
                      : Icons.circle,
                  color: color,
                  size: 8,
                ),
                const SizedBox(width: 5),
                Text(
                  status == NetStatus.offline ? 'DOWN' : 'LIVE',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing icon animation
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isActive;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.isActive,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Icon(widget.icon, color: widget.color, size: 30);
    }
    return ScaleTransition(
      scale: _scaleAnim,
      child: Icon(widget.icon, color: widget.color, size: 30),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint card: instructions for how to demo the feature
// ─────────────────────────────────────────────────────────────────────────────
class _HintCard extends StatelessWidget {
  final bool isDark;
  const _HintCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates_rounded,
                size: 18, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Demo tip: Tap "Simulate Large Fetch," then toggle Airplane Mode mid-transfer to see failure & queue. '
                'Turn connectivity back on to watch auto-retry.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log panel
// ─────────────────────────────────────────────────────────────────────────────
class _LogRow {
  final LogEntry entry;
  _LogRow({required this.entry});
}

class _LogPanel extends StatelessWidget {
  final List<_LogRow> log;
  final ScrollController scrollController;
  final bool isDark;
  final ColorScheme colorScheme;

  const _LogPanel({
    required this.log,
    required this.scrollController,
    required this.isDark,
    required this.colorScheme,
  });

  Color _rowColor(String msg) {
    if (msg.startsWith('✅')) return const Color(0xFF10B981);
    if (msg.startsWith('⚠️')) return const Color(0xFFEF4444);
    if (msg.startsWith('🔄')) return const Color(0xFFF59E0B);
    if (msg.startsWith('📶')) return const Color(0xFF3B82F6);
    if (msg.startsWith('🗑️')) return const Color(0xFF94A3B8);
    if (msg.startsWith('🔍')) return const Color(0xFF94A3B8);
    if (msg.startsWith('🚀')) return const Color(0xFF818CF8);
    if (msg.startsWith('  ⏳')) return colorScheme.onSurfaceVariant;
    return colorScheme.onSurface;
  }

  String _timeLabel(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelBg = isDark
        ? const Color(0xFF0D1117)
        : const Color(0xFFF1F5F9);

    if (log.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded,
                  size: 36, color: colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Text(
                'No activity yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outlineVariant),
              ),
              Text(
                'Tap "Simulate Large Fetch" to begin.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outlineVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: log.length,
          itemBuilder: (context, index) {
            final row = log[index];
            final msgColor = _rowColor(row.entry.message);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeLabel(row.entry.timestamp),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.entry.message,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: msgColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
