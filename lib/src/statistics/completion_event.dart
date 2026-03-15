/// Generic completion event for tracking productivity.
///
/// Domain-agnostic: can represent a todo completion, habit check-off,
/// reminder dismissal, or any app-specific action.
class PkCompletionEvent {
  final String entityId;
  final String entityType;
  final DateTime timestamp;
  final DateTime? dueDate;
  final bool? wasOnTime;
  final String? priority;
  final List<String> tags;
  final int? estimatedDurationMinutes;
  final Map<String, dynamic> metadata;

  const PkCompletionEvent({
    required this.entityId,
    required this.entityType,
    required this.timestamp,
    this.dueDate,
    this.wasOnTime,
    this.priority,
    this.tags = const [],
    this.estimatedDurationMinutes,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'entityType': entityType,
        'timestamp': timestamp.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'wasOnTime': wasOnTime,
        'priority': priority,
        'tags': tags,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'metadata': metadata,
      };

  factory PkCompletionEvent.fromJson(Map<String, dynamic> json) {
    return PkCompletionEvent(
      entityId: json['entityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      wasOnTime: json['wasOnTime'] as bool?,
      priority: json['priority'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Generic creation event for tracking item creation rates.
class PkCreationEvent {
  final String entityId;
  final String entityType;
  final DateTime timestamp;
  final String? priority;
  final List<String> tags;
  final int? estimatedDurationMinutes;

  const PkCreationEvent({
    required this.entityId,
    required this.entityType,
    required this.timestamp,
    this.priority,
    this.tags = const [],
    this.estimatedDurationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'entityType': entityType,
        'timestamp': timestamp.toIso8601String(),
        'priority': priority,
        'tags': tags,
        'estimatedDurationMinutes': estimatedDurationMinutes,
      };

  factory PkCreationEvent.fromJson(Map<String, dynamic> json) {
    return PkCreationEvent(
      entityId: json['entityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: json['priority'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
    );
  }
}
