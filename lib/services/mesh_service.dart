import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';

import '../models/mesh_message.dart';

/// Wraps Google's Nearby Connections API.
/// All callbacks surface data upward through the four function fields;
/// the [MeshProvider] wires them in its constructor.
class MeshService {
  static const _serviceId = 'com.kk.meshchat';
  static const _defaultTtl = 4;
  static const _strategy = Strategy.P2P_CLUSTER;

  final _uuid = const Uuid();

  // ── Callbacks set by MeshProvider ────────────────────────────────────────
  late void Function(String endpointId, String name) onPeerFound;
  late void Function(String endpointId) onPeerLost;
  late void Function(String endpointId, String name, String token) onVerify;
  late void Function(String endpointId) onConnected;
  late void Function(String endpointId) onDisconnected;
  late void Function(MeshMessage msg) onMessage;

  // ── Internal state ────────────────────────────────────────────────────────
  final String _localEndpointId = '';
  final Set<String> _connected = {};
  final Set<String> _seen = {}; // deduplication set for incoming messages

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start advertising + discovering simultaneously with [userName].
  Future<void> start(String userName) async {
    _seen.clear();

    await Nearby().startAdvertising(
      userName,
      _strategy,
      onConnectionInitiated: _onInitiated,
      onConnectionResult: _onResult,
      onDisconnected: _onDisconnected,
      serviceId: _serviceId,
    );

    await Nearby().startDiscovery(
      userName,
      _strategy,
      onEndpointFound: (id, name, sid) => onPeerFound(id, name),
      onEndpointLost: (id) => onPeerLost(id ?? ''),
      serviceId: _serviceId,
    );
  }

  /// Stop everything and clear connection state.
  Future<void> stop() async {
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    _connected.clear();
  }

  // ── Connection handshake ─────────────────────────────────────────────────

  /// Ask the remote endpoint to connect; the user must then verify the token.
  Future<void> requestConnection(String endpointId, String userName) async {
    await Nearby().requestConnection(
      userName,
      endpointId,
      onConnectionInitiated: _onInitiated,
      onConnectionResult: _onResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onInitiated(String id, ConnectionInfo info) {
    onVerify(id, info.endpointName, info.authenticationToken);
  }

  void _onResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connected.add(id);
      onConnected(id);
    } else {
      _connected.remove(id);
    }
  }

  void _onDisconnected(String id) {
    _connected.remove(id);
    onDisconnected(id);
  }

  /// Accept a pending connection and register the payload listener.
  Future<void> acceptConnection(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (eid, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          _handleIncoming(eid, utf8.decode(payload.bytes!));
        }
      },
      onPayloadTransferUpdate: (_, _) {},
    );
  }

  /// Reject / ignore a pending connection.
  Future<void> rejectConnection(String endpointId) =>
      Nearby().rejectConnection(endpointId);

  // ── Messaging ─────────────────────────────────────────────────────────────

  /// Create and broadcast a new message to all connected peers.
  Future<void> send(String text, String senderId, String senderName) async {
    final msg = MeshMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      ts: DateTime.now(),
      ttl: _defaultTtl,
    );
    _seen.add(msg.id);
    onMessage(msg.copyWith(mine: true));

    final bytes = Uint8List.fromList(utf8.encode(msg.encode()));
    for (final id in List<String>.from(_connected)) {
      await Nearby().sendBytesPayload(id, bytes);
    }
  }

  void _handleIncoming(String fromEndpoint, String raw) {
    final MeshMessage msg;
    try {
      msg = MeshMessage.decode(raw);
    } catch (_) {
      return; // ignore malformed payloads
    }

    if (!_seen.add(msg.id)) return; // already seen — drop duplicate

    onMessage(msg);

    // Relay to every other connected peer if TTL allows
    if (msg.ttl > 0) {
      final forwarded = msg.copyWith(ttl: msg.ttl - 1).encode();
      final bytes = Uint8List.fromList(utf8.encode(forwarded));
      for (final id in List<String>.from(_connected)) {
        if (id != fromEndpoint) {
          Nearby().sendBytesPayload(id, bytes);
        }
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get hasConnected => _connected.isNotEmpty;
  Set<String> get connectedIds => Set.unmodifiable(_connected);
  String get localEndpointId => _localEndpointId;
}
