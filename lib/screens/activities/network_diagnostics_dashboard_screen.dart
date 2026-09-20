import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/network_health_provider.dart';
import '../../services/network_diagnostics_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Network Diagnostic Dashboard
///
/// Presents the app-wide network health (broadcast through
/// [NetworkHealthProvider]) and lets the user run the three-phase diagnostic:
/// idle ping → download (+concurrent ping) → upload (+upload ping).
/// ─────────────────────────────────────────────────────────────────────────────
class NetworkDiagnosticsDashboardScreen extends StatefulWidget {
  const NetworkDiagnosticsDashboardScreen({super.key});

  @override
  State<NetworkDiagnosticsDashboardScreen> createState() =>
      _NetworkDiagnosticsDashboardScreenState();
}

class _NetworkDiagnosticsDashboardScreenState
    extends State<NetworkDiagnosticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final health = context.watch<NetworkHealthProvider>();
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
              child: Icon(Icons.speed_rounded,
                  color: colorScheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Network Diagnostic Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.running_with_errors_rounded,
                color: colorScheme.primary),
            tooltip: 'Run full diagnostic now',
            onPressed: health.isRunning
                ? null
                : () =>
                    context.read<NetworkHealthProvider>().runDiagnosticsNow(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear log',
            onPressed: health.log.isEmpty ? null : () => context.read<NetworkHealthProvider>().clearLog(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overall health gauge card ─────────────────────────────────
            _HealthGaugeCard(health: health, isDark: isDark),

            const SizedBox(height: 14),

            // ── Phase cards ───────────────────────────────────────────────
            _PhaseCard(
              icon: Icons.multiple_stop_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Idle Ping',
              subtitle: 'Baseline latency on a quiet link',
              status: _idleStatus(health.latest),
              phase: DiagnosticPhase.idlePing,
              headerTrailing: _phaseBadge(health, DiagnosticPhase.idlePing),
              children: _idleRows(health.latest, theme),
            ),

            const SizedBox(height: 12),

            _PhaseCard(
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF10B981),
              title: 'Download Bandwidth',
              subtitle: 'Concurrent ping measured during the transfer',
              status: _downloadStatus(health.latest),
              phase: DiagnosticPhase.download,
              headerTrailing: _phaseBadge(health, DiagnosticPhase.download),
              children: _downloadRows(health.latest, theme),
            ),

            const SizedBox(height: 12),

            _PhaseCard(
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Upload Bandwidth',
              subtitle: 'Upload ping tracked simultaneously',
              status: _uploadStatus(health.latest),
              phase: DiagnosticPhase.upload,
              headerTrailing: _phaseBadge(health, DiagnosticPhase.upload),
              children: _uploadRows(health.latest, theme),
            ),

            const SizedBox(height: 14),

            // ── Run button ────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: health.isRunning
                  ? null
                  : () =>
                      context.read<NetworkHealthProvider>().runDiagnosticsNow(),
              icon: health.isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                health.isRunning
                    ? 'Running ${health.activePhase?.label ?? '…'}…'
                    : 'Run Diagnostics',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Console log ───────────────────────────────────────────────
            _ConsolePanel(
              entries: health.log,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers for status strings ────────────────────────────────────────────

  String? _idleStatus(NetworkTestResults? r) {
    if (r == null) return null;
    final ping = r.idlePing;
    if (ping == null || !ping.hasData) return '⚠️ No idle ping measurements';
    return 'avg ${ping.avg} ms · loss ${ping.packetLossPercent.toStringAsFixed(0)}%';
  }

  String? _downloadStatus(NetworkTestResults? r) {
    if (r == null) return null;
    final d = r.download;
    if (d == null) return '⚠️ Download test failed/offline';
    return '${d.megabitsPerSecond.toStringAsFixed(1)} Mbps';
  }

  String? _uploadStatus(NetworkTestResults? r) {
    if (r == null) return null;
    final u = r.upload;
    if (u == null) return '⚠️ Upload test failed/offline';
    return '${u.megabitsPerSecond.toStringAsFixed(1)} Mbps';
  }

  Widget _phaseBadge(NetworkHealthProvider health, DiagnosticPhase phase) {
    if (!health.isRunning) return const SizedBox.shrink();
    final active = health.activePhase == phase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF10B981)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            active ? 'RUNNING' : 'QUEUED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _idleRows(NetworkTestResults? r, ThemeData theme) {
    final ping = r?.idlePing;
    if (ping == null || !ping.hasData) {
      return [
        _mutedRow('No baseline idle ping yet.', theme),
      ];
    }
    return [
      _statRow('Average', '${ping.avg} ms', theme),
      _statRow('Minimum', '${ping.min} ms', theme),
      _statRow('Maximum', '${ping.max} ms', theme),
      _statRow('Packet loss', '${ping.packetLossPercent.toStringAsFixed(1)}%',
          theme,
          lossHighlight: true),
    ];
  }

  List<Widget> _downloadRows(NetworkTestResults? r, ThemeData theme) {
    final d = r?.download;
    if (d == null) {
      return [_mutedRow('None — run the diagnostic to measure download.', theme)];
    }
    return [
      _statRow('Download speed', '${d.megabitsPerSecond.toStringAsFixed(1)} Mbps',
          theme, bold: true),
      _statRow('Data transferred', '${(d.bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB', theme),
      _statRow('Duration', '${d.durationMs} ms', theme),
      _statRow('Concurrent ping (avg)', '${d.concurrentPing.avg} ms', theme),
      _statRow('Concurrent packet loss',
          '${d.concurrentPing.packetLossPercent.toStringAsFixed(1)}%', theme),
    ];
  }

  List<Widget> _uploadRows(NetworkTestResults? r, ThemeData theme) {
    final u = r?.upload;
    if (u == null) {
      return [_mutedRow('None — run the diagnostic to measure upload.', theme)];
    }
    return [
      _statRow('Upload speed', '${u.megabitsPerSecond.toStringAsFixed(1)} Mbps',
          theme, bold: true),
      _statRow('Data transferred', '${(u.bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB', theme),
      _statRow('Duration', '${u.durationMs} ms', theme),
      _statRow('Upload ping (avg)', '${u.uploadPing.avg} ms', theme),
      _statRow('Upload packet loss',
          '${u.uploadPing.packetLossPercent.toStringAsFixed(1)}%', theme),
    ];
  }

  Widget _statRow(String label, String value, ThemeData theme,
      {bool bold = false, bool lossHighlight = false}) {
    final valueColor = lossHighlight && value.startsWith('100')
        ? const Color(0xFFEF4444)
        : (bold ? const Color(0xFF3B6FE8) : theme.colorScheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: bold || lossHighlight ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutedRow(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health gauge card
// ─────────────────────────────────────────────────────────────────────────────
class _HealthGaugeCard extends StatelessWidget {
  final NetworkHealthProvider health;
  final bool isDark;

  const _HealthGaugeCard({required this.health, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tier = health.tier;
    final tierColor = NetworkHealthTier.fromValue(tier.colorValue);

    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ring gauge
              _RingGauge(
                progress: tier.level / 5,
                color: tierColor,
                size: 96,
              ),
              const SizedBox(width: 18),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Health',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.description,
                      style:
                          TextStyle(fontSize: 12.5, color: textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    if (health.isRunning)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Testing ${health.activePhase?.label ?? '…'}…',
                            style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF3B6FE8),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    else if (health.latest == null)
                      Text(
                        'Press "Run Diagnostics" to begin.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      )
                    else
                      Text(
                        'Last run ${_timeAgo(health.latest!.startedAt)} · '
                        'run #${health.runCount}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tier legend strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(
                color: const Color(0xFF10B981),
                label: 'Excellent >10',
              ),
              _LegendDot(
                color: const Color(0xFFF59E0B),
                label: 'Fair 2–10',
              ),
              _LegendDot(
                color: const Color(0xFFEF4444),
                label: 'Poor <2',
              ),
              _LegendDot(
                color: const Color(0xFF8B5CF6),
                label: 'Degraded',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

/// Animated ring gauge via CustomPainter.
class _RingGauge extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  const _RingGauge({
    required this.progress,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(progress: value, color: color),
          child: Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.15);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase card
// ─────────────────────────────────────────────────────────────────────────────
class _PhaseCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? status;
  final DiagnosticPhase phase;
  final Widget headerTrailing;
  final List<Widget> children;

  const _PhaseCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.phase,
    required this.headerTrailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              headerTrailing,
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Console log panel
// ─────────────────────────────────────────────────────────────────────────────
class _ConsolePanel extends StatelessWidget {
  final List<DiagnosticLogEntry> entries;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ConsolePanel({
    required this.entries,
    required this.isDark,
    required this.colorScheme,
  });

  Color _entryColor(String msg) {
    if (msg.startsWith('✅') || msg.startsWith('▶️')) {
      return const Color(0xFF10B981);
    }
    if (msg.startsWith('⚠️')) return const Color(0xFFEF4444);
    if (msg.startsWith('📡')) return const Color(0xFF3B82F6);
    if (msg.startsWith('⬇️')) return const Color(0xFF2E8B57);
    if (msg.startsWith('⬆️')) return const Color(0xFFF59E0B);
    if (msg.startsWith('🏷️')) return const Color(0xFF8B5CF6);
    return colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelBg =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9);
    final count = entries.length;

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded,
                    size: 15, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Diagnostic Console',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count entries',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No diagnostics run yet.\nTap "Run Diagnostics" to start.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.outlineVariant),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${entry.timestamp.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.message,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _entryColor(entry.message),
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
        ],
      ),
    );
  }
}