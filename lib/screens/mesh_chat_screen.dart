import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/mesh_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/peer_list_sheet.dart';

/// Local Mesh Chat screen.
/// Uses [StatefulWidget] only for the [TextEditingController] and
/// [ScrollController]; all business state lives in [MeshProvider].
class MeshChatScreen extends StatefulWidget {
  const MeshChatScreen({super.key});

  @override
  State<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends State<MeshChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Verify connection dialog ───────────────────────────────────────────────
  Future<void> _showVerifyDialog(MeshProvider mesh) async {
    if (!mesh.hasPending) return;
    final token = mesh.pendingToken ?? '';
    final name = mesh.pendingEndpointName ?? 'Unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary =
            isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

        return AlertDialog(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: Color(0xFF3B6FE8), size: 42),
              const SizedBox(height: 10),
              Text('Verify Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$name wants to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text('Does the other device show the same code?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              // Token display
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B6FE8), Color(0xFF6B8FF8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  token,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await mesh.acceptPending();
    } else {
      await mesh.rejectPending();
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  void _send(MeshProvider mesh, String userId, String userName) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    mesh.send(text, userId, userName);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDarkMode;
    final userName = appProvider.userName;
    // Use studentId as a stable local sender ID
    final userId = appProvider.studentId;

    final mesh = context.watch<MeshProvider>();

    // Show verify dialog whenever a pending connection arrives
    if (mesh.hasPending) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showVerifyDialog(mesh));
    }

    // Scroll to bottom when messages change
    if (mesh.messages.isNotEmpty) _scrollToBottom();

    final bgColor =
        isDark ? const Color(0xFF0B0F19) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);

    final connectedCount =
        mesh.peers.where((p) => p.status.name == 'connected').length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local Mesh Chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              _statusLabel(mesh, connectedCount),
              style: TextStyle(
                fontSize: 11,
                color: _statusColor(mesh),
              ),
            ),
          ],
        ),
        actions: [
          // Peers button
          if (mesh.status == MeshStatus.active)
            IconButton(
              tooltip: 'Nearby peers',
              icon: Badge(
                isLabelVisible: mesh.peers.isNotEmpty,
                label: Text('${mesh.peers.length}'),
                child: const Icon(Icons.sensors_rounded),
              ),
              color: const Color(0xFF3B6FE8),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: mesh,
                    child: PeerListSheet(localUserName: userName),
                  ),
                );
              },
            ),
          // Start / Stop toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StartStopButton(mesh: mesh, userName: userName),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: dividerColor, height: 1),
        ),
      ),

      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────────────
          Expanded(child: _buildBody(mesh, bgColor, textPrimary, textSecondary)),

          // ── Input row ──────────────────────────────────────────────────
          _InputRow(
            controller: _controller,
            cardBg: cardBg,
            dividerColor: dividerColor,
            textSecondary: textSecondary,
            enabled: mesh.hasConnected,
            onSend: () => _send(mesh, userId, userName),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    MeshProvider mesh,
    Color bgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Error state
    if (mesh.status == MeshStatus.error) {
      return _ErrorState(
        message: mesh.errorMessage,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    // Idle state
    if (mesh.status == MeshStatus.idle) {
      return _IdleState(textPrimary: textPrimary, textSecondary: textSecondary);
    }

    // Starting
    if (mesh.status == MeshStatus.starting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF3B6FE8)),
            SizedBox(height: 16),
            Text('Starting mesh…',
                style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    // Active — no messages yet
    if (mesh.messages.isEmpty) {
      return _NoMessagesState(
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        hasConnected: mesh.hasConnected,
      );
    }

    // Active — messages present
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: mesh.messages.length,
      itemBuilder: (_, i) {
        final msg = mesh.messages[i];
        final prevMsg = i > 0 ? mesh.messages[i - 1] : null;
        final showName = prevMsg == null ||
            prevMsg.senderId != msg.senderId ||
            msg.ts.difference(prevMsg.ts).inMinutes > 2;
        return MessageBubble(message: msg, showSenderName: showName);
      },
    );
  }

  String _statusLabel(MeshProvider mesh, int connectedCount) {
    return switch (mesh.status) {
      MeshStatus.idle => 'Tap ▶ to start',
      MeshStatus.starting => 'Starting…',
      MeshStatus.active => connectedCount > 0
          ? '$connectedCount connected · Scanning'
          : 'Scanning for peers…',
      MeshStatus.error => 'Error',
    };
  }

  Color _statusColor(MeshProvider mesh) {
    return switch (mesh.status) {
      MeshStatus.idle => const Color(0xFF6B7280),
      MeshStatus.starting => const Color(0xFFF59E0B),
      MeshStatus.active => const Color(0xFF10B981),
      MeshStatus.error => const Color(0xFFEF4444),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StartStopButton extends StatelessWidget {
  final MeshProvider mesh;
  final String userName;

  const _StartStopButton({required this.mesh, required this.userName});

  @override
  Widget build(BuildContext context) {
    final isActive = mesh.status == MeshStatus.active;
    final isStarting = mesh.status == MeshStatus.starting;

    return GestureDetector(
      onTap: isStarting
          ? null
          : () {
              if (isActive) {
                mesh.stop();
              } else {
                mesh.start(userName);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
              : const LinearGradient(
                  colors: [Color(0xFF3B6FE8), Color(0xFF6B8FF8)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'Stop' : 'Start',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final Color cardBg;
  final Color dividerColor;
  final Color textSecondary;
  final bool enabled;
  final VoidCallback onSend;

  const _InputRow({
    required this.controller,
    required this.cardBg,
    required this.dividerColor,
    required this.textSecondary,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardBg,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Message…'
                    : 'Connect to a peer first',
                hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFF1F3F8),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: enabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B6FE8), Color(0xFF6B8FF8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  const _IdleState({required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return _ScrollableCentered(
      padding: const EdgeInsets.all(40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B6FE8), Color(0xFF6B8FF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Local Mesh Chat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connect with nearby devices without internet.\nTap Start to begin advertising and discovering.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.android_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Android only · Requires two or more physical devices',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF10B981)),
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

class _NoMessagesState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final bool hasConnected;
  const _NoMessagesState({
    required this.textPrimary,
    required this.textSecondary,
    required this.hasConnected,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollableCentered(
      padding: const EdgeInsets.all(40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasConnected
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.sensors_rounded,
              size: 56,
              color: textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasConnected
                  ? 'Say hello to the mesh!'
                  : 'No peers connected yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasConnected
                  ? 'Type a message below to send it to all connected peers.'
                  : 'Ask a nearby device to open Mesh Chat,\nthen tap the sensor icon to connect.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, height: 1.5, fontSize: 13),
            ),
          ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Color textPrimary;
  final Color textSecondary;
  const _ErrorState({
    required this.message,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollableCentered(
      padding: const EdgeInsets.all(40),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Open App Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
      ),
    );
  }
}

class _ScrollableCentered extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const _ScrollableCentered({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}
