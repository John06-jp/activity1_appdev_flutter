import 'dart:convert';

/// A single message that travels the mesh via controlled flooding.
class MeshMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime ts;
  final int ttl;

  /// Set to `true` only on the originating device — never serialised.
  final bool mine;

  const MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.ts,
    required this.ttl,
    this.mine = false,
  });

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'ts': ts.millisecondsSinceEpoch,
        'ttl': ttl,
        // `mine` is intentionally omitted — it is local-only
      };

  factory MeshMessage.fromJson(Map<String, dynamic> j) => MeshMessage(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        senderName: j['senderName'] as String,
        text: j['text'] as String,
        ts: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        ttl: j['ttl'] as int,
      );

  /// Encode to a JSON string for Nearby Connections byte payload.
  String encode() => jsonEncode(toJson());

  /// Decode from a JSON string received via Nearby Connections.
  static MeshMessage decode(String raw) =>
      MeshMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  // ── Helpers ──────────────────────────────────────────────────────────────

  MeshMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? ts,
    int? ttl,
    bool? mine,
  }) =>
      MeshMessage(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        text: text ?? this.text,
        ts: ts ?? this.ts,
        ttl: ttl ?? this.ttl,
        mine: mine ?? this.mine,
      );
}
