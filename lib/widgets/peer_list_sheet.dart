import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart' as nc;
import 'package:provider/provider.dart';

import '../models/peer.dart';
import '../providers/mesh_provider.dart';

/// Bottom sheet listing all discovered and connected peers.
class PeerListSheet extends StatelessWidget {
  final String localUserName;

  const PeerListSheet({super.key, required this.localUserName});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded,
                    color: Color(0xFF3B6FE8), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Nearby Peers',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                _CountBadge(count: mesh.peers.length),
              ],
            ),
          ),
          Divider(color: dividerColor, height: 1),

          // Empty state
          if (mesh.peers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.wifi_tethering_off_rounded,
                      size: 48,
                      color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No peers found yet.\nAsk someone nearby to open Mesh Chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, height: 1.5),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: mesh.peers.length,
                separatorBuilder: (_, _) => Divider(
                    color: dividerColor, height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, i) {
                  final peer = mesh.peers[i];
                  return _PeerTile(
                    peer: peer,
                    index: i,
                    localUserName: localUserName,
                    textPrimary: textPrimary,
                    onConnect: () => mesh.connectTo(peer.endpointId, localUserName),
                    onDisconnect: () =>
                        nc.Nearby().disconnectFromEndpoint(peer.endpointId),
                  );
                },
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PeerTile extends StatelessWidget {
  final Peer peer;
  final int index;
  final String localUserName;
  final Color textPrimary;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _PeerTile({
    required this.peer,
    required this.index,
    required this.localUserName,
    required this.textPrimary,
    required this.onConnect,
    required this.onDisconnect,
  });

  Color get _avatarColor {
    const colors = [
      Color(0xFF3B6FE8),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _avatarColor.withValues(alpha: 0.2),
        child: Text(
          peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: _avatarColor),
        ),
      ),
      title: Text(peer.name,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: textPrimary)),
      subtitle: _StatusBadge(status: peer.status),
      trailing: _ActionButton(
          status: peer.status,
          onConnect: onConnect,
          onDisconnect: onDisconnect),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PeerStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PeerStatus.connected => ('Connected', const Color(0xFF10B981)),
      PeerStatus.connecting => ('Connecting…', const Color(0xFFF59E0B)),
      PeerStatus.discovered => ('Discovered', const Color(0xFF6B7280)),
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PeerStatus status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ActionButton({
    required this.status,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      PeerStatus.discovered => TextButton(
          onPressed: onConnect,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3B6FE8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: const Text('Connect',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      PeerStatus.connecting => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFF59E0B)),
        ),
      PeerStatus.connected => TextButton(
          onPressed: onDisconnect,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: const Text('Disconnect',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
    };
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B6FE8).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF3B6FE8)),
      ),
    );
  }
}
