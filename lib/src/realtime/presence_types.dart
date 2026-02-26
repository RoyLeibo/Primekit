import 'package:flutter/foundation.dart';

/// An immutable snapshot of a user's presence state.
@immutable
final class PresenceRecord {
  /// Creates a [PresenceRecord].
  const PresenceRecord({
    required this.userId,
    required this.lastSeen,
    required this.isOnline,
    this.displayName,
    this.metadata,
  });

  /// Deserialises a [PresenceRecord] from a JSON map.
  factory PresenceRecord.fromJson(String userId, Map<String, dynamic> json) =>
      PresenceRecord(
        userId: userId,
        displayName: json['displayName'] as String?,
        lastSeen: json['lastSeen'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
            : DateTime.now(),
        isOnline: json['isOnline'] as bool? ?? false,
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(
                json['metadata'] as Map<Object?, Object?>,
              )
            : null,
      );

  /// The user's identifier.
  final String userId;

  /// Optional display name.
  final String? displayName;

  /// When this record was last updated.
  final DateTime lastSeen;

  /// Whether the user is currently online.
  final bool isOnline;

  /// Arbitrary extra metadata attached to the presence record.
  final Map<String, dynamic>? metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresenceRecord &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          isOnline == other.isOnline;

  @override
  int get hashCode => Object.hash(userId, isOnline);

  @override
  String toString() =>
      'PresenceRecord('
      'userId: $userId, isOnline: $isOnline, lastSeen: $lastSeen)';
}

/// Tracks which users are currently online in a realtime channel.
///
/// See `FirebasePresenceService` for the Firebase RTDB-backed implementation.
abstract class PresenceService {
  /// Marks [userId] as online in the given channel.
  Future<void> connect({
    required String userId,
    required String channelId,
    Map<String, dynamic>? metadata,
    String? displayName,
  });

  /// Marks [userId] as offline in the given channel.
  Future<void> disconnect({required String userId, required String channelId});

  /// Emits the list of currently online users whenever it changes.
  Stream<List<PresenceRecord>> watchPresence({required String channelId});

  /// Returns the current list of online users (one-time fetch).
  Future<List<PresenceRecord>> getOnlineUsers({required String channelId});
}
