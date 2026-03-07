import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import 'presence_types.dart';

export 'presence_types.dart';

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

    await ref.onDisconnect().set(offlineRecord);
    await ref.set(onlineRecord);
  }

  @override
  Future<void> disconnect({
    required String userId,
    required String channelId,
  }) async {
    final ref = _presenceRef(channelId, userId);
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
