/// A single scheduled time slot with its completion status.
///
/// Immutable value type used by [ScheduleCalculator] to represent
/// individual occurrences within a recurrence schedule.
class ScheduleSlot {
  /// The date and time this slot is scheduled for.
  final DateTime scheduledTime;

  /// Whether this slot has been completed/fulfilled.
  final bool isCompleted;

  const ScheduleSlot({
    required this.scheduledTime,
    required this.isCompleted,
  });

  /// Canonical key for this slot in a completion log map.
  ///
  /// Format: ISO 8601 truncated to minute precision ("2026-03-14T08:00").
  String get slotKey => scheduledTime.toIso8601String().substring(0, 16);

  /// Returns a copy with the given fields replaced.
  ScheduleSlot copyWith({
    DateTime? scheduledTime,
    bool? isCompleted,
  }) {
    return ScheduleSlot(
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleSlot &&
          scheduledTime == other.scheduledTime &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(scheduledTime, isCompleted);

  @override
  String toString() =>
      'ScheduleSlot(scheduledTime: $scheduledTime, isCompleted: $isCompleted)';
}
