/// Unit of time for notification scheduling.
enum NotificationTimeUnit {
  /// Minutes before the target time.
  minutes,

  /// Hours before the target time.
  hours,

  /// Days before the target time.
  days,

  /// Weeks before the target time.
  weeks,
}

/// A rule that defines when a notification should fire relative to a target time.
///
/// Each rule specifies "X [timeUnit] before" the target date/time.
/// Immutable — use [copyWith] for updates.
///
/// ```dart
/// const rule = NotificationRule(
///   id: 'reminder_1h',
///   value: 1,
///   timeUnit: NotificationTimeUnit.hours,
/// );
/// final fireAt = rule.calculateNotificationTime(dueDate);
/// ```
final class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.value,
    required this.timeUnit,
    this.isEnabled = true,
    this.hasFired = false,
  });

  /// Unique identifier for this rule.
  final String id;

  /// Numeric value (e.g. 10 minutes, 2 weeks).
  final int value;

  /// The unit for [value].
  final NotificationTimeUnit timeUnit;

  /// Whether this rule is active.
  final bool isEnabled;

  /// Whether this rule has already fired for the current target.
  final bool hasFired;

  /// Convert to [Duration] for scheduling calculations.
  Duration get duration {
    return switch (timeUnit) {
      NotificationTimeUnit.minutes => Duration(minutes: value),
      NotificationTimeUnit.hours => Duration(hours: value),
      NotificationTimeUnit.days => Duration(days: value),
      NotificationTimeUnit.weeks => Duration(days: value * 7),
    };
  }

  /// Calculate when this notification should fire relative to [targetTime].
  DateTime calculateNotificationTime(DateTime targetTime) {
    return targetTime.subtract(duration);
  }

  /// Human-readable label, e.g. "10 minutes before" or "1 day before".
  String get displayText {
    final unitText = switch (timeUnit) {
      NotificationTimeUnit.minutes => value == 1 ? 'minute' : 'minutes',
      NotificationTimeUnit.hours => value == 1 ? 'hour' : 'hours',
      NotificationTimeUnit.days => value == 1 ? 'day' : 'days',
      NotificationTimeUnit.weeks => value == 1 ? 'week' : 'weeks',
    };
    return '$value $unitText before';
  }

  /// Returns a new [NotificationRule] with the given fields replaced.
  NotificationRule copyWith({
    String? id,
    int? value,
    NotificationTimeUnit? timeUnit,
    bool? isEnabled,
    bool? hasFired,
  }) {
    return NotificationRule(
      id: id ?? this.id,
      value: value ?? this.value,
      timeUnit: timeUnit ?? this.timeUnit,
      isEnabled: isEnabled ?? this.isEnabled,
      hasFired: hasFired ?? this.hasFired,
    );
  }

  /// Serialize to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'timeUnit': timeUnit.name,
      'isEnabled': isEnabled,
      'hasFired': hasFired,
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    final timeUnit = NotificationTimeUnit.values.firstWhere(
      (e) => e.name == json['timeUnit'],
      orElse: () => NotificationTimeUnit.minutes,
    );

    return NotificationRule(
      id: json['id'] as String? ?? '',
      value: json['value'] as int? ?? 0,
      timeUnit: timeUnit,
      isEnabled: json['isEnabled'] as bool? ?? true,
      hasFired: json['hasFired'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationRule &&
        other.id == id &&
        other.value == value &&
        other.timeUnit == timeUnit &&
        other.isEnabled == isEnabled &&
        other.hasFired == hasFired;
  }

  @override
  int get hashCode => Object.hash(id, value, timeUnit, isEnabled, hasFired);

  @override
  String toString() =>
      'NotificationRule(id: $id, $value ${timeUnit.name}, '
      'enabled: $isEnabled, fired: $hasFired)';
}
