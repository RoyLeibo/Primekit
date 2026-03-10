import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// An immutable record of a single user action within an app.
///
/// Each event captures who did what, on which resource, and when —
/// along with an arbitrary [payload] for event-specific context.
///
/// ```dart
/// AuditEvent(
///   eventType: 'guess_submitted',
///   userId: user.id,
///   appId: 'bullseye',
///   resourceId: match.id,
///   resourceType: 'match',
///   payload: {
///     'predictedHome': 2,
///     'predictedAway': 1,
///     'tournamentId': tournament.id,
///   },
/// )
/// ```
class AuditEvent {
  AuditEvent({
    required this.eventType,
    required this.userId,
    required this.appId,
    this.resourceId,
    this.resourceType,
    this.payload = const {},
    this.metadata = const {},
    DateTime? timestamp,
    String? id,
  }) : id = id ?? _uuid.v4(),
       timestamp = timestamp ?? DateTime.now().toUtc();

  /// Auto-generated UUID, unique per event.
  final String id;

  /// The action that occurred, e.g. `guess_submitted`, `expense_created`.
  ///
  /// Use `noun_verb` snake_case convention for consistency.
  final String eventType;

  /// The user who performed the action.
  final String userId;

  /// Identifier of the app that emitted the event, e.g. `bullseye`, `splitly`.
  final String appId;

  /// Optional: the primary resource this event relates to, e.g. a match ID.
  final String? resourceId;

  /// Optional: the type of [resourceId], e.g. `match`, `expense`, `group`.
  final String? resourceType;

  /// Event-specific structured data, e.g. old/new values, amounts, labels.
  final Map<String, dynamic> payload;

  /// Optional ambient context: app version, platform, session ID, etc.
  final Map<String, dynamic> metadata;

  /// UTC timestamp of when the event occurred.
  final DateTime timestamp;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventType': eventType,
    'userId': userId,
    'appId': appId,
    if (resourceId != null) 'resourceId': resourceId,
    if (resourceType != null) 'resourceType': resourceType,
    'payload': payload,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'] as String,
    eventType: json['eventType'] as String,
    userId: json['userId'] as String,
    appId: json['appId'] as String,
    resourceId: json['resourceId'] as String?,
    resourceType: json['resourceType'] as String?,
    payload: Map<String, dynamic>.from(
      (json['payload'] as Map<String, dynamic>?) ?? {},
    ),
    metadata: Map<String, dynamic>.from(
      (json['metadata'] as Map<String, dynamic>?) ?? {},
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  String toString() =>
      'AuditEvent(type: $eventType, user: $userId, app: $appId, '
      'resource: ${resourceType ?? '-'}/${resourceId ?? '-'}, '
      'at: $timestamp)';
}
