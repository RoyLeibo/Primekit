import 'recurrence_rule.dart';
import 'schedule_slot.dart';

/// Pure-function schedule calculator for recurring events.
///
/// All methods are static, side-effect free, and compute results solely
/// from their inputs. No state, no I/O, no framework dependencies.
///
/// Generalized from PawTrack's `MedicationSchedule` to support any
/// domain that needs recurring schedule computation (medications,
/// tasks, habits, reminders, etc.).
class ScheduleCalculator {
  ScheduleCalculator._();

  /// Generate all [ScheduleSlot]s within [from]..[to] for the given [rule],
  /// starting from [courseStart].
  ///
  /// If [courseDays] is set, stops generating after that many days from
  /// [courseStart]. The [completionLog] maps slot keys (ISO minute strings)
  /// to completion booleans.
  static List<ScheduleSlot> generateSlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    Map<String, bool> completionLog = const {},
  }) {
    return switch (rule.mode) {
      RecurrenceMode.daily => _generateDailySlots(
          rule: rule,
          courseStart: courseStart,
          from: from,
          to: to,
          courseDays: courseDays,
          completionLog: completionLog,
        ),
      RecurrenceMode.interval => _generateIntervalSlots(
          rule: rule,
          courseStart: courseStart,
          from: from,
          to: to,
          courseDays: courseDays,
          completionLog: completionLog,
        ),
      RecurrenceMode.weekly => _generateWeeklySlots(
          rule: rule,
          courseStart: courseStart,
          from: from,
          to: to,
          courseDays: courseDays,
          completionLog: completionLog,
        ),
      RecurrenceMode.monthly => _generateMonthlySlots(
          rule: rule,
          courseStart: courseStart,
          from: from,
          to: to,
          courseDays: courseDays,
          completionLog: completionLog,
        ),
    };
  }

  /// Find the first unfilled slot from the generated slots.
  ///
  /// Returns `null` if all slots are completed or no slots exist.
  static ScheduleSlot? nextUnfilledSlot({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    Map<String, bool> completionLog = const {},
  }) {
    final slots = generateSlots(
      rule: rule,
      courseStart: courseStart,
      from: from,
      to: to,
      courseDays: courseDays,
      completionLog: completionLog,
    );

    for (final slot in slots) {
      if (!slot.isCompleted) return slot;
    }
    return null;
  }

  /// Compute the next due [DateTime] after [lastCompleted] for a given [rule].
  ///
  /// For interval rules, adds [intervalDays] to [lastCompleted].
  /// For daily rules, scans ahead up to 2 days for the next unfilled slot.
  /// Returns `null` if no next date can be determined.
  static DateTime? computeNextDueDate({
    required RecurrenceRule rule,
    required DateTime courseStart,
    DateTime? lastCompleted,
    int? courseDays,
    Map<String, bool> completionLog = const {},
  }) {
    if (rule.mode == RecurrenceMode.interval) {
      if (lastCompleted == null) return null;
      return lastCompleted.add(Duration(days: rule.intervalDays));
    }

    // For daily/weekly/monthly: scan ahead for the next unfilled slot
    final now = DateTime.now();
    final slot = nextUnfilledSlot(
      rule: rule,
      courseStart: courseStart,
      from: now.subtract(const Duration(hours: 1)),
      to: now.add(const Duration(days: 2)),
      courseDays: courseDays,
      completionLog: completionLog,
    );
    return slot?.scheduledTime;
  }

  /// Get today's slots with completion status.
  ///
  /// Returns an empty list if the rule mode does not produce intra-day slots.
  static List<ScheduleSlot> todaysSlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    int? courseDays,
    Map<String, bool> completionLog = const {},
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return generateSlots(
      rule: rule,
      courseStart: courseStart,
      from: startOfDay,
      to: endOfDay,
      courseDays: courseDays,
      completionLog: completionLog,
    );
  }

  /// Check if a course is complete (all slots filled through [courseDays]).
  ///
  /// Returns `false` if [courseDays] is `null`, if the course end date
  /// has not been reached, or if any slot remains unfilled.
  static bool isCourseComplete({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required int? courseDays,
    Map<String, bool> completionLog = const {},
  }) {
    if (courseDays == null) return false;

    final courseEnd = DateTime(
      courseStart.year,
      courseStart.month,
      courseStart.day + courseDays,
    );

    if (DateTime.now().isBefore(courseEnd)) return false;

    final allSlots = generateSlots(
      rule: rule,
      courseStart: courseStart,
      from: courseStart,
      to: courseEnd,
      courseDays: courseDays,
      completionLog: completionLog,
    );

    return allSlots.every((slot) => slot.isCompleted);
  }

  /// Get the current day number in a course (1-based).
  ///
  /// Returns `null` if [courseDays] is `null`. Clamps to [1, courseDays].
  static int? courseDayNumber({
    required DateTime courseStart,
    required int? courseDays,
  }) {
    if (courseDays == null) return null;

    final startDay = _dateOnly(courseStart);
    final today = _dateOnly(DateTime.now());
    final dayNum = today.difference(startDay).inDays + 1;

    return dayNum.clamp(1, courseDays);
  }

  /// Format a human-readable description of the schedule.
  ///
  /// Examples:
  /// - "3x daily (08:00, 14:00, 20:00)"
  /// - "Every 30 days"
  /// - "Weekly on Mon, Wed, Fri"
  /// - "Monthly on day 15"
  static String formatSchedule(RecurrenceRule rule) {
    return switch (rule.mode) {
      RecurrenceMode.daily => _formatDaily(rule),
      RecurrenceMode.interval => _formatInterval(rule),
      RecurrenceMode.weekly => _formatWeekly(rule),
      RecurrenceMode.monthly => 'Monthly on day ${rule.dayOfMonth}',
    };
  }

  // ── Private: daily slot generation ──

  static List<ScheduleSlot> _generateDailySlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    required Map<String, bool> completionLog,
  }) {
    if (rule.dailyTimes.isEmpty) return const [];

    final sorted = List.of(rule.dailyTimes)..sort();
    final slots = <ScheduleSlot>[];

    final courseEnd = courseDays != null
        ? DateTime(courseStart.year, courseStart.month, courseStart.day + courseDays)
        : null;

    final startDay = _dateOnly(
      courseStart.isAfter(from) ? courseStart : from,
    );
    final endDay = _dateOnly(to);

    for (var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))) {
      if (courseEnd != null && !day.isBefore(courseEnd)) break;

      for (final time in sorted) {
        final slot = DateTime(day.year, day.month, day.day, time.hour, time.minute);
        if (slot.isBefore(courseStart) || slot.isBefore(from) || slot.isAfter(to)) {
          continue;
        }

        final key = slot.toIso8601String().substring(0, 16);
        slots.add(ScheduleSlot(
          scheduledTime: slot,
          isCompleted: completionLog[key] == true,
        ));
      }
    }

    return slots;
  }

  // ── Private: interval slot generation ──

  static List<ScheduleSlot> _generateIntervalSlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    required Map<String, bool> completionLog,
  }) {
    final slots = <ScheduleSlot>[];
    final courseEnd = courseDays != null
        ? courseStart.add(Duration(days: courseDays))
        : null;

    var current = courseStart;
    while (!current.isAfter(to)) {
      if (courseEnd != null && current.isAfter(courseEnd)) break;

      if (!current.isBefore(from)) {
        final key = current.toIso8601String().substring(0, 16);
        slots.add(ScheduleSlot(
          scheduledTime: current,
          isCompleted: completionLog[key] == true,
        ));
      }

      current = current.add(Duration(days: rule.intervalDays));
    }

    return slots;
  }

  // ── Private: weekly slot generation ──

  static List<ScheduleSlot> _generateWeeklySlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    required Map<String, bool> completionLog,
  }) {
    if (rule.daysOfWeek.isEmpty) return const [];

    final slots = <ScheduleSlot>[];
    final courseEnd = courseDays != null
        ? courseStart.add(Duration(days: courseDays))
        : null;

    final startDay = _dateOnly(
      courseStart.isAfter(from) ? courseStart : from,
    );
    final endDay = _dateOnly(to);

    for (var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))) {
      if (courseEnd != null && day.isAfter(courseEnd)) break;

      if (rule.daysOfWeek.contains(day.weekday)) {
        final key = day.toIso8601String().substring(0, 16);
        slots.add(ScheduleSlot(
          scheduledTime: day,
          isCompleted: completionLog[key] == true,
        ));
      }
    }

    return slots;
  }

  // ── Private: monthly slot generation ──

  static List<ScheduleSlot> _generateMonthlySlots({
    required RecurrenceRule rule,
    required DateTime courseStart,
    required DateTime from,
    required DateTime to,
    int? courseDays,
    required Map<String, bool> completionLog,
  }) {
    final slots = <ScheduleSlot>[];
    final courseEnd = courseDays != null
        ? courseStart.add(Duration(days: courseDays))
        : null;

    final startMonth = _dateOnly(
      courseStart.isAfter(from) ? courseStart : from,
    );

    var current = DateTime(startMonth.year, startMonth.month, rule.dayOfMonth);
    if (current.isBefore(startMonth)) {
      current = DateTime(current.year, current.month + 1, rule.dayOfMonth);
    }

    while (!current.isAfter(to)) {
      if (courseEnd != null && current.isAfter(courseEnd)) break;

      if (!current.isBefore(from)) {
        final key = current.toIso8601String().substring(0, 16);
        slots.add(ScheduleSlot(
          scheduledTime: current,
          isCompleted: completionLog[key] == true,
        ));
      }

      current = DateTime(current.year, current.month + 1, rule.dayOfMonth);
    }

    return slots;
  }

  // ── Private: formatting helpers ──

  static String _formatDaily(RecurrenceRule rule) {
    if (rule.dailyTimes.isEmpty) return '';
    final sorted = List.of(rule.dailyTimes)..sort();
    final count = sorted.length;
    final times = sorted.map((t) => t.formatted).join(', ');
    return '${count}x daily ($times)';
  }

  static String _formatInterval(RecurrenceRule rule) {
    return 'Every ${rule.intervalDays} days';
  }

  static String _formatWeekly(RecurrenceRule rule) {
    if (rule.daysOfWeek.isEmpty) return '';
    const dayNames = {
      1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu',
      5: 'Fri', 6: 'Sat', 7: 'Sun',
    };
    final names = rule.daysOfWeek.map((d) => dayNames[d] ?? '?').join(', ');
    return 'Weekly on $names';
  }

  // ── Private: date utility ──

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
