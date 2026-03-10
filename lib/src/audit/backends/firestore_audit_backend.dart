import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core.dart';
import '../audit_backend.dart';
import '../audit_event.dart';
import '../audit_query.dart';

/// Firestore implementation of [AuditBackend].
///
/// Events are written to `{collectionPath}/{eventId}` and indexed by
/// `userId`, `eventType`, `resourceId`, `resourceType`, and `timestamp`.
///
/// **Recommended Firestore indexes** (create in Firebase Console):
/// - `userId ASC + timestamp DESC`
/// - `appId ASC + eventType ASC + timestamp DESC`
/// - `resourceType ASC + resourceId ASC + timestamp DESC`
///
/// ```dart
/// AuditLogService.instance.configure(
///   FirestoreAuditBackend(
///     firestore: FirebaseFirestore.instance,
///     collectionPath: 'audit_logs', // or 'groups/{id}/audit_logs'
///   ),
///   appId: 'bullseye',
/// );
/// ```
class FirestoreAuditBackend implements AuditBackend {
  FirestoreAuditBackend({
    required FirebaseFirestore firestore,
    String collectionPath = 'audit_logs',
  }) : _firestore = firestore,
       _collectionPath = collectionPath;

  final FirebaseFirestore _firestore;
  final String _collectionPath;

  static const String _tag = 'FirestoreAuditBackend';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<void> write(AuditEvent event) async {
    try {
      await _collection.doc(event.id).set(event.toJson());
      PrimekitLogger.verbose(
        'Wrote audit event "${event.eventType}" (${event.id})',
        tag: _tag,
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to write audit event "${event.eventType}"',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      // Re-throw so AuditLogService._writeAsync can catch and log.
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  @override
  Future<List<AuditEvent>> query(AuditQuery q) async {
    try {
      final events = await _buildQuery(q).get();
      return events.docs.map((d) => AuditEvent.fromJson(d.data())).toList();
    } catch (e, st) {
      PrimekitLogger.error(
        'Audit query failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Watch (real-time)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<AuditEvent>> watch(AuditQuery q) {
    return _buildQuery(q).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((d) => AuditEvent.fromJson(d.data())).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Query<Map<String, dynamic>> _buildQuery(AuditQuery q) {
    Query<Map<String, dynamic>> ref = _collection;

    if (q.userId != null) ref = ref.where('userId', isEqualTo: q.userId);
    if (q.appId != null) ref = ref.where('appId', isEqualTo: q.appId);
    if (q.eventType != null) {
      ref = ref.where('eventType', isEqualTo: q.eventType);
    }
    if (q.resourceId != null) {
      ref = ref.where('resourceId', isEqualTo: q.resourceId);
    }
    if (q.resourceType != null) {
      ref = ref.where('resourceType', isEqualTo: q.resourceType);
    }
    if (q.from != null) {
      ref = ref.where(
        'timestamp',
        isGreaterThanOrEqualTo: q.from!.toUtc().toIso8601String(),
      );
    }
    if (q.to != null) {
      ref = ref.where(
        'timestamp',
        isLessThanOrEqualTo: q.to!.toUtc().toIso8601String(),
      );
    }

    ref = ref
        .orderBy('timestamp', descending: q.orderDescending)
        .limit(q.limit);

    return ref;
  }
}
