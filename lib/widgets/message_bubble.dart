import 'package:flutter/material.dart';

import '../models/mesh_message.dart';

/// A single chat bubble, aligned right for own messages and left for others.
class MessageBubble extends StatelessWidget {
  final MeshMessage message;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    this.showSenderName = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSystem = message.senderId == 'system';

    if (isSystem) return _SystemMessage(text: message.text, isDark: isDark);

    final mine = message.mine;
    final bubbleColor = mine
        ? const Color(0xFF3B6FE8)
        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F3F8));
    final textColor = mine ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    final timeColor = mine
        ? Colors.white.withValues(alpha: 0.65)
        : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: mine ? 60 : 12,
          right: mine ? 12 : 60,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (only for others)
            if (!mine && showSenderName)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _nameColor(message.senderId),
                  ),
                ),
              ),

            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(fontSize: 15, color: textColor, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.ts),
                    style: TextStyle(fontSize: 10, color: timeColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _nameColor(String senderId) {
    final h = senderId.codeUnits.fold(0, (a, b) => a + b) % 360;
    return HSLColor.fromAHSL(1, h.toDouble(), 0.65, 0.5).toColor();
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SystemMessage({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2D3748).withValues(alpha: 0.7)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
