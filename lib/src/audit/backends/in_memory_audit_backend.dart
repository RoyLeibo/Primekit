import '../audit_backend.dart';
import '../audit_event.dart';
import '../audit_query.dart';

/// In-memory implementation of [AuditBackend] for testing.
///
/// All events are stored in a plain list in memory and lost when the
/// process exits. Use this in unit tests to verify that [AuditLogService]
/// receives the expected events.
///
/// ```dart
/// final backend = InMemoryAuditBackend();
/// AuditLogService.instance.configure(backend, appId: 'test');
///
/// // Trigger the code under test...
/// await sut.submitGuess(guess);
///
/// // Assert
/// expect(
///   backend.events.where((e) => e.eventType == 'guess_submitted'),
///   hasLength(1),
/// );
/// ```
class InMemoryAuditBackend implements AuditBackend {
  final List<AuditEvent> _events = [];

  /// All events written so far, in insertion order.
  List<AuditEvent> get events => List.unmodifiable(_events);

  /// Clears all stored events.
  void clear() => _events.clear();

  @override
  Future<void> write(AuditEvent event) async => _events.add(event);

  @override
  Future<List<AuditEvent>> query(AuditQuery q) async =>
      _applyQuery(q, _events);

  @override
  Stream<List<AuditEvent>> watch(AuditQuery q) =>
      Stream.value(_applyQuery(q, _events));

  // ---------------------------------------------------------------------------
  // Query logic (mirrors FirestoreAuditBackend filters)
  // ---------------------------------------------------------------------------

  List<AuditEvent> _applyQuery(AuditQuery q, List<AuditEvent> source) {
    var results = source.where((e) {
      if (q.userId != null && e.userId != q.userId) return false;
      if (q.appId != null && e.appId != q.appId) return false;
      if (q.eventType != null && e.eventType != q.eventType) return false;
      if (q.resourceId != null && e.resourceId != q.resourceId) return false;
      if (q.resourceType != null && e.resourceType != q.resourceType) {
        return false;
      }
      if (q.from != null && e.timestamp.isBefore(q.from!)) return false;
      if (q.to != null && e.timestamp.isAfter(q.to!)) return false;
      return true;
    }).toList();

    results.sort(
      (a, b) => q.orderDescending
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp),
    );

    return results.take(q.limit).toList();
  }
}
