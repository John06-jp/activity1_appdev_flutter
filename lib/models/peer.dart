/// Represents a discovered or connected Nearby endpoint.
class Peer {
  final String endpointId;
  final String name;
  final PeerStatus status;

  const Peer({
    required this.endpointId,
    required this.name,
    required this.status,
  });

  Peer copyWith({PeerStatus? status}) => Peer(
        endpointId: endpointId,
        name: name,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      other is Peer && other.endpointId == endpointId;

  @override
  int get hashCode => endpointId.hashCode;
}

enum PeerStatus {
  /// Discovered but not yet connected.
  discovered,

  /// Connection is being negotiated.
  connecting,

  /// Fully connected and ready to exchange messages.
  connected,
}
