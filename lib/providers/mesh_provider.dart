import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mesh_message.dart';
import '../models/peer.dart';
import '../services/mesh_service.dart';

enum MeshStatus { idle, starting, active, error }

/// Holds the complete UI state for the Local Mesh Chat screen.
/// Wires [MeshService] callbacks to state mutations and [notifyListeners].
class MeshProvider extends ChangeNotifier {
  final MeshService _service = MeshService();

  MeshStatus status = MeshStatus.idle;
  String errorMessage = '';

  final List<Peer> peers = [];
  final List<MeshMessage> messages = [];

  /// Endpoint that is pending verification (waiting for user to confirm token).
  String? _pendingEndpointId;
  String? _pendingEndpointName;
  String? _pendingToken;

  bool get hasPending => _pendingEndpointId != null;
  String? get pendingToken => _pendingToken;
  String? get pendingEndpointName => _pendingEndpointName;

  bool get hasConnected => peers.any((p) => p.status == PeerStatus.connected);

  MeshProvider() {
    _service.onPeerFound = _onPeerFound;
    _service.onPeerLost = _onPeerLost;
    _service.onVerify = _onVerify;
    _service.onConnected = _onConnected;
    _service.onDisconnected = _onDisconnected;
    _service.onMessage = _onMessage;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start(String userName) async {
    status = MeshStatus.starting;
    errorMessage = '';
    notifyListeners();

    final granted = await _requestPermissions();
    if (!granted) {
      status = MeshStatus.error;
      errorMessage = 'Permissions denied. Tap the button below to open settings.';
      notifyListeners();
      return;
    }

    try {
      await _service.start(userName);
      status = MeshStatus.active;
    } catch (e) {
      status = MeshStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    peers.clear();
    status = MeshStatus.idle;
    notifyListeners();
  }

  // ── Connection flow ───────────────────────────────────────────────────────

  Future<void> connectTo(String endpointId, String userName) async {
    _updatePeer(endpointId, PeerStatus.connecting);
    try {
      await _service.requestConnection(endpointId, userName);
    } catch (e) {
      _updatePeer(endpointId, PeerStatus.discovered);
    }
  }

  Future<void> acceptPending() async {
    final id = _pendingEndpointId;
    if (id == null) return;
    _clearPending();
    await _service.acceptConnection(id);
  }

  Future<void> rejectPending() async {
    final id = _pendingEndpointId;
    if (id == null) return;
    _clearPending();
    await _service.rejectConnection(id);
    _updatePeer(id, PeerStatus.discovered);
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  Future<void> send(String text, String senderId, String senderName) async {
    if (!hasConnected) return;
    await _service.send(text, senderId, senderName);
  }

  // ── Service callbacks ─────────────────────────────────────────────────────

  void _onPeerFound(String id, String name) {
    if (peers.any((p) => p.endpointId == id)) return;
    peers.add(Peer(endpointId: id, name: name, status: PeerStatus.discovered));
    notifyListeners();
  }

  void _onPeerLost(String id) {
    peers.removeWhere((p) => p.endpointId == id && p.status == PeerStatus.discovered);
    notifyListeners();
  }

  void _onVerify(String id, String name, String token) {
    _pendingEndpointId = id;
    _pendingEndpointName = name;
    _pendingToken = token;
    // Ensure the peer is in the list (may arrive before onPeerFound on the
    // receiving side)
    if (!peers.any((p) => p.endpointId == id)) {
      peers.add(Peer(endpointId: id, name: name, status: PeerStatus.connecting));
    }
    notifyListeners();
  }

  void _onConnected(String id) {
    _updatePeer(id, PeerStatus.connected);
  }

  void _onDisconnected(String id) {
    final peer = peers.firstWhere(
      (p) => p.endpointId == id,
      orElse: () => Peer(endpointId: id, name: 'Unknown', status: PeerStatus.connected),
    );
    peers.removeWhere((p) => p.endpointId == id);
    // Insert a system message
    messages.add(MeshMessage(
      id: 'sys_$id',
      senderId: 'system',
      senderName: 'System',
      text: '${peer.name} left the chat.',
      ts: DateTime.now(),
      ttl: 0,
      mine: false,
    ));
    messages.sort((a, b) => a.ts.compareTo(b.ts));
    notifyListeners();
  }

  void _onMessage(MeshMessage msg) {
    messages.add(msg);
    messages.sort((a, b) => a.ts.compareTo(b.ts));
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updatePeer(String id, PeerStatus newStatus) {
    final idx = peers.indexWhere((p) => p.endpointId == id);
    if (idx != -1) {
      peers[idx] = peers[idx].copyWith(status: newStatus);
    }
    notifyListeners();
  }

  void _clearPending() {
    _pendingEndpointId = null;
    _pendingEndpointName = null;
    _pendingToken = null;
  }

  /// Request all permissions required by Nearby Connections, branched by
  /// Android API level.
  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true; // iOS guard

    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    final permissions = <Permission>[
      if (sdkInt >= 31) ...[
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ],
      Permission.locationWhenInUse,
      if (sdkInt >= 33) Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();

    return statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}
