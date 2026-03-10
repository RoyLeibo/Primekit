import 'audit_event.dart';
import 'audit_query.dart';

/// Abstract storage backend for [AuditLogService].
///
/// Implement this interface to add a new storage target (Firestore, SQL,
/// REST endpoint, in-memory, etc.). Then configure the service:
///
/// ```dart
/// AuditLogService.instance.configure(
///   FirestoreAuditBackend(firestore: FirebaseFirestore.instance),
///   appId: 'bullseye',
/// );
/// ```
abstract class AuditBackend {
  /// Persists [event] to the backend.
  ///
  /// Should be fire-and-forget: implementations must not throw in normal
  /// operation; use logging for non-critical write failures.
  Future<void> write(AuditEvent event);

  /// Returns events matching [query], ordered by timestamp.
  ///
  /// Returns an empty list if no events match or on non-fatal errors.
  Future<List<AuditEvent>> query(AuditQuery query);

  /// Optional: returns a live stream of events matching [query].
  ///
  /// Backends that don't support real-time streaming can return
  /// `Stream.fromFuture(query(query))` as a one-shot stream.
  Stream<List<AuditEvent>> watch(AuditQuery query) =>
      Stream.fromFuture(this.query(query));
}
