import 'package:flutter/foundation.dart';

/// Abstract interface every realtime backend must implement.
///
/// Implementations include `PkWebSocketChannel` (raw WebSocket) and
/// `FirebaseRtdbChannel` (Firebase Realtime Database).
abstract interface class RealtimeChannel {
  /// The unique identifier for this channel.
  String get channelId;

  /// Stream of messages received on this channel.
  Stream<RealtimeMessage> get messages;

  /// Stream of connection status changes.
  Stream<ChannelStatus> get status;

  /// Establishes the connection to the backend.
  Future<void> connect();

  /// Gracefully closes the connection.
  Future<void> disconnect();

  /// Sends [payload] to the channel.
  ///
  /// If the channel is disconnected, implementations should buffer the message
  /// and send it once reconnected.
  Future<void> send(Map<String, dynamic> payload, {String? type});

  /// Whether the channel is currently connected.
  bool get isConnected;
}

/// The lifecycle states a [RealtimeChannel] can be in.
enum ChannelStatus {
  /// Attempting to establish the initial connection.
  connecting,

  /// Connection is active and ready to send/receive messages.
  connected,

  /// In the process of gracefully closing the connection.
  disconnecting,

  /// Connection is closed; not attempting to reconnect.
  disconnected,

  /// Connection was lost and is being re-established automatically.
  reconnecting,

  /// An unrecoverable error has occurred.
  error,
}

/// An immutable message received on a [RealtimeChannel].
@immutable
final class RealtimeMessage {
  /// Creates a [RealtimeMessage].
  const RealtimeMessage({
    required this.id,
    required this.payload,
    required this.receivedAt,
    this.type,
    this.senderId,
  });

  /// Unique message identifier.
  final String id;

  /// Optional message type (e.g. `'chat'`, `'presence'`).
  final String? type;

  /// Arbitrary message payload.
  final Map<String, dynamic> payload;

  /// When this message was received locally.
  final DateTime receivedAt;

  /// Optional identifier of the message sender.
  final String? senderId;

  @override
  String toString() =>
      'RealtimeMessage(id: $id, type: $type, receivedAt: $receivedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtimeMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
