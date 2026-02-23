import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
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
/// See [FirebasePresenceService] for the Firebase RTDB-backed implementation.
abstract class PresenceService {
  /// Marks [userId] as online in the given channel.
  ///
  /// Implementations should register an `onDisconnect` handler so the record
  /// is automatically cleaned up when the user loses connectivity.
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

/// Firebase RTDB-backed [PresenceService].
///
/// Presence records are stored at `presence/{channelId}/{userId}`.
/// An `onDisconnect` hook ensures the record is marked offline even when the
/// client closes abnormally (app crash, network loss, etc.).
class FirebasePresenceService extends PresenceService {
  /// Creates a [FirebasePresenceService].
  FirebasePresenceService({FirebaseDatabase? database})
    : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  // ---------------------------------------------------------------------------
  // PresenceService interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> connect({
    required String userId,
    required String channelId,
    Map<String, dynamic>? metadata,
    String? displayName,
  }) async {
    final ref = _presenceRef(channelId, userId);

    final onlineRecord = <String, dynamic>{
      'userId': userId,
      'displayName': ?displayName,
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
      'metadata': ?metadata,
    };

    final offlineRecord = <String, dynamic>{
      'userId': userId,
      'displayName': ?displayName,
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
      'metadata': ?metadata,
    };

    // Register the offline state to be applied automatically on disconnection.
    await ref.onDisconnect().set(offlineRecord);
    await ref.set(onlineRecord);
  }

  @override
  Future<void> disconnect({
    required String userId,
    required String channelId,
  }) async {
    final ref = _presenceRef(channelId, userId);
    // Cancel the onDisconnect hook and write offline state immediately.
    await ref.onDisconnect().cancel();
    await ref.update({'isOnline': false, 'lastSeen': ServerValue.timestamp});
  }

  @override
  Stream<List<PresenceRecord>> watchPresence({required String channelId}) {
    final ref = _db.ref('presence/$channelId');
    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) {
        return <PresenceRecord>[];
      }
      return _parseRecords(
        raw as Map<Object?, Object?>,
      ).where((r) => r.isOnline).toList();
    });
  }

  @override
  Future<List<PresenceRecord>> getOnlineUsers({
    required String channelId,
  }) async {
    final ref = _db.ref('presence/$channelId');
    final snapshot = await ref.get();
    final raw = snapshot.value;
    if (raw is! Map) {
      return [];
    }
    return _parseRecords(
      raw as Map<Object?, Object?>,
    ).where((r) => r.isOnline).toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DatabaseReference _presenceRef(String channelId, String userId) =>
      _db.ref('presence/$channelId/$userId');

  List<PresenceRecord> _parseRecords(Map<Object?, Object?> raw) => raw.entries
      .map((e) {
        final userId = e.key as String?;
        final value = e.value;
        if (userId == null || value is! Map) {
          return null;
        }
        return PresenceRecord.fromJson(
          userId,
          Map<String, dynamic>.from(value as Map<Object?, Object?>),
        );
      })
      .whereType<PresenceRecord>()
      .toList();
}
