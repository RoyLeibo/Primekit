import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An immutable snapshot of a buffered outgoing message.
@immutable
final class BufferedMessage {
  /// Creates a [BufferedMessage].
  const BufferedMessage({
    required this.id,
    required this.payload,
    required this.queuedAt,
    this.type,
  });

  /// Deserialises a [BufferedMessage] from a JSON map.
  factory BufferedMessage.fromJson(Map<String, dynamic> json) =>
      BufferedMessage(
        id: json['id'] as String,
        type: json['type'] as String?,
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );

  /// Unique identifier for this buffered message.
  final String id;

  /// Optional message type.
  final String? type;

  /// The outgoing payload.
  final Map<String, dynamic> payload;

  /// When this message was enqueued.
  final DateTime queuedAt;

  /// Serialises this message to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
      };
}

/// Buffers outgoing messages when a `RealtimeChannel` is disconnected.
///
/// Messages are persisted via `SharedPreferences` so they survive app restarts.
/// The buffer operates as a FIFO queue with a configurable [maxSize]; once the
/// limit is reached the oldest message is evicted to make room for the new one.
///
/// ```dart
/// final buffer = MessageBuffer(channelId: 'room1');
///
/// // Enqueue while offline
/// await buffer.enqueue({'text': 'hello'}, type: 'chat');
///
/// // Drain on reconnect
/// final pending = await buffer.dequeueAll();
/// for (final msg in pending) {
///   await channel.send(msg.payload, type: msg.type);
/// }
/// ```
class MessageBuffer {
  /// Creates a [MessageBuffer] for [channelId].
  ///
  /// [maxSize] caps the number of messages retained. Defaults to 100.
  MessageBuffer({required String channelId, this.maxSize = 100})
      : _prefsKey = '_pk_msg_buf_$channelId';

  /// The maximum number of messages held in the buffer.
  final int maxSize;

  final String _prefsKey;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Appends a message to the end of the buffer.
  ///
  /// If [maxSize] has been reached the oldest message is dropped first.
  Future<void> enqueue(Map<String, dynamic> payload, {String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = _decode(prefs.getStringList(_prefsKey) ?? []);
    final message = BufferedMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      payload: Map<String, dynamic>.unmodifiable(payload),
      queuedAt: DateTime.now(),
    );

    final updated = [...current, message];
    final overflow = updated.length - maxSize;
    final capped = overflow > 0 ? updated.sublist(overflow) : updated;

    await prefs.setStringList(
      _prefsKey,
      capped.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  /// Returns all buffered messages in FIFO order and clears the buffer.
  Future<List<BufferedMessage>> dequeueAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (raw.isEmpty) {
      return [];
    }
    await prefs.remove(_prefsKey);
    return _decode(raw);
  }

  /// The current number of buffered messages.
  Future<int> get size async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefsKey) ?? []).length;
  }

  /// Discards all buffered messages without sending them.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<BufferedMessage> _decode(List<String> raw) => raw
      .map(
        (s) => BufferedMessage.fromJson(
          jsonDecode(s) as Map<String, dynamic>,
        ),
      )
      .toList();
}
