/// Filter parameters for querying [AuditEvent] records.
///
/// All fields are optional — omitting a field means "no filter on that field".
///
/// ```dart
/// // All guess events for a specific user, last 7 days
/// final query = AuditQuery(
///   userId: 'user-abc',
///   eventType: 'guess_submitted',
///   from: DateTime.now().subtract(const Duration(days: 7)),
///   limit: 100,
/// );
///
/// // Everything that happened to a specific match
/// final query = AuditQuery(
///   resourceId: 'match-123',
///   resourceType: 'match',
/// );
/// ```
class AuditQuery {
  const AuditQuery({
    this.userId,
    this.appId,
    this.eventType,
    this.resourceId,
    this.resourceType,
    this.from,
    this.to,
    this.limit = 50,
    this.orderDescending = true,
  });

  /// Filter to a specific user.
  final String? userId;

  /// Filter to a specific app, e.g. `bullseye`.
  final String? appId;

  /// Filter to a specific event type, e.g. `guess_submitted`.
  final String? eventType;

  /// Filter to events on a specific resource ID.
  final String? resourceId;

  /// Filter to events on a specific resource type.
  final String? resourceType;

  /// Return only events at or after this UTC timestamp.
  final DateTime? from;

  /// Return only events at or before this UTC timestamp.
  final DateTime? to;

  /// Maximum number of events to return. Defaults to 50.
  final int limit;

  /// When true (default), events are returned newest-first.
  final bool orderDescending;
}
