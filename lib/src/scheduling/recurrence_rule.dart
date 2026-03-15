/// Recurrence mode for scheduled items.
enum RecurrenceMode {
  /// Repeat every N days from the last completion date.
  interval,

  /// Fixed times each day (e.g., 08:00, 14:00, 20:00).
  daily,

  /// Specific days of the week (e.g., Mon, Wed, Fri).
  weekly,

  /// Specific day of each month (e.g., 1st, 15th).
  monthly,
}

/// A time-of-day value (hour + minute) for daily schedules.
///
/// Intentionally decoupled from Flutter's [TimeOfDay] so the scheduling
/// module stays framework-agnostic.
class ScheduleTimeOfDay implements Comparable<ScheduleTimeOfDay> {
  /// The hour component (0-23).
  final int hour;

  /// The minute component (0-59).
  final int minute;

  const ScheduleTimeOfDay({required this.hour, this.minute = 0});

  /// Total minutes since midnight, useful for comparisons.
  int get totalMinutes => hour * 60 + minute;

  /// Formatted as "HH:mm" (zero-padded).
  String get formatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  int compareTo(ScheduleTimeOfDay other) =>
      totalMinutes.compareTo(other.totalMinutes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleTimeOfDay &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ScheduleTimeOfDay($formatted)';
}

/// An immutable recurrence rule describing when scheduled events occur.
///
/// Use one of the named constructors for clarity:
/// ```dart
/// RecurrenceRule.everyNDays(30)
/// RecurrenceRule.dailyAt([ScheduleTimeOfDay(hour: 8), ScheduleTimeOfDay(hour: 20)])
/// RecurrenceRule.weeklyOn([DateTime.monday, DateTime.wednesday])
/// RecurrenceRule.monthlyOnDay(15)
/// ```
class RecurrenceRule {
  /// The recurrence mode.
  final RecurrenceMode mode;

  /// Number of days between occurrences (used when [mode] is [RecurrenceMode.interval]).
  final int intervalDays;

  /// Fixed times of day (used when [mode] is [RecurrenceMode.daily]).
  final List<ScheduleTimeOfDay> dailyTimes;

  /// Days of week (1=Monday..7=Sunday, per [DateTime.monday] etc.).
  /// Used when [mode] is [RecurrenceMode.weekly].
  final List<int> daysOfWeek;

  /// Day of month (1-31). Used when [mode] is [RecurrenceMode.monthly].
  final int dayOfMonth;

  const RecurrenceRule({
    required this.mode,
    this.intervalDays = 1,
    this.dailyTimes = const [],
    this.daysOfWeek = const [],
    this.dayOfMonth = 1,
  });

  /// Create an interval rule that repeats every [days] days.
  const RecurrenceRule.everyNDays(int days)
      : mode = RecurrenceMode.interval,
        intervalDays = days,
        dailyTimes = const [],
        daysOfWeek = const [],
        dayOfMonth = 1;

  /// Create a daily rule with fixed times of day.
  const RecurrenceRule.dailyAt(List<ScheduleTimeOfDay> times)
      : mode = RecurrenceMode.daily,
        intervalDays = 1,
        dailyTimes = times,
        daysOfWeek = const [],
        dayOfMonth = 1;

  /// Create a weekly rule on specific days.
  const RecurrenceRule.weeklyOn(List<int> days)
      : mode = RecurrenceMode.weekly,
        intervalDays = 1,
        dailyTimes = const [],
        daysOfWeek = days,
        dayOfMonth = 1;

  /// Create a monthly rule on a specific day of the month.
  const RecurrenceRule.monthlyOnDay(int day)
      : mode = RecurrenceMode.monthly,
        intervalDays = 1,
        dailyTimes = const [],
        daysOfWeek = const [],
        dayOfMonth = day;

  /// Returns a copy with the given fields replaced.
  RecurrenceRule copyWith({
    RecurrenceMode? mode,
    int? intervalDays,
    List<ScheduleTimeOfDay>? dailyTimes,
    List<int>? daysOfWeek,
    int? dayOfMonth,
  }) {
    return RecurrenceRule(
      mode: mode ?? this.mode,
      intervalDays: intervalDays ?? this.intervalDays,
      dailyTimes: dailyTimes ?? this.dailyTimes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRule &&
          mode == other.mode &&
          intervalDays == other.intervalDays &&
          _listEquals(dailyTimes, other.dailyTimes) &&
          _listEquals(daysOfWeek, other.daysOfWeek) &&
          dayOfMonth == other.dayOfMonth;

  @override
  int get hashCode => Object.hash(
        mode,
        intervalDays,
        Object.hashAll(dailyTimes),
        Object.hashAll(daysOfWeek),
        dayOfMonth,
      );

  @override
  String toString() => 'RecurrenceRule(mode: $mode, intervalDays: $intervalDays, '
      'dailyTimes: $dailyTimes, daysOfWeek: $daysOfWeek, dayOfMonth: $dayOfMonth)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
