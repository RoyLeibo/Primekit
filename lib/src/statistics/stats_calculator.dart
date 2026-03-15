import 'completion_event.dart';

/// Pure-function productivity statistics calculator.
///
/// All methods are static, side-effect free, and compute results solely
/// from their inputs. No state, no I/O, no framework dependencies.
class PkStatsCalculator {
  PkStatsCalculator._();

  /// Completion rate as a fraction (0.0 - 1.0) since [since].
  ///
  /// Rate is computed as events-per-day since the given date.
  /// A rate of 1.0 means one completion per day on average.
  /// Values above 1.0 are possible (clamped to 1.0).
  static double completionRate(
    List<PkCompletionEvent> events,
    DateTime since,
  ) {
    if (events.isEmpty) return 0.0;

    final now = DateTime.now();
    final daysSince = now.difference(since).inDays + 1;
    if (daysSince <= 0) return 0.0;

    final inRange = events
        .where((e) => !e.timestamp.isBefore(since) && !e.timestamp.isAfter(now))
        .length;

    return (inRange / daysSince).clamp(0.0, 1.0);
  }

  /// Completions per day for the last [daysBack] days.
  ///
  /// Keys are dates normalized to midnight.
  static Map<DateTime, int> trendsPerDay(
    List<PkCompletionEvent> events,
    int daysBack,
  ) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));
    final result = <DateTime, int>{};

    for (final event in events) {
      final normalized = _normalizeDate(event.timestamp);
      if (normalized.isBefore(cutoff)) continue;
      result[normalized] = (result[normalized] ?? 0) + 1;
    }

    return result;
  }

  /// Completions per ISO week for the last [weeksBack] weeks.
  ///
  /// Keys are ISO week numbers (year * 100 + week).
  static Map<int, int> trendsPerWeek(
    List<PkCompletionEvent> events,
    int weeksBack,
  ) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: weeksBack * 7));
    final result = <int, int>{};

    for (final event in events) {
      if (event.timestamp.isBefore(cutoff)) continue;
      final week = _isoWeekNumber(event.timestamp);
      result[week] = (result[week] ?? 0) + 1;
    }

    return result;
  }

  /// Hour-of-day distribution (0-23).
  static Map<int, int> hourDistribution(List<PkCompletionEvent> events) {
    final result = <int, int>{};
    for (final event in events) {
      final hour = event.timestamp.hour;
      result[hour] = (result[hour] ?? 0) + 1;
    }
    return result;
  }

  /// Current consecutive-day streak ending at today or yesterday.
  static int currentStreak(List<PkCompletionEvent> events) {
    if (events.isEmpty) return 0;

    final uniqueDays = _uniqueSortedDayKeys(events);
    final today = _dateKey(DateTime.now());
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    if (!uniqueDays.contains(today) && !uniqueDays.contains(yesterday)) {
      return 0;
    }

    var streak = 0;
    var checkDate = DateTime.now();
    if (!uniqueDays.contains(today)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (uniqueDays.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Longest consecutive-day streak ever.
  static int longestStreak(List<PkCompletionEvent> events) {
    if (events.isEmpty) return 0;

    final sortedDays = _uniqueSortedDayKeys(events);
    var longest = 1;
    var current = 1;

    for (var i = 1; i < sortedDays.length; i++) {
      final prevDate = DateTime.parse(sortedDays[i - 1]);
      final currDate = DateTime.parse(sortedDays[i]);
      final diff = currDate.difference(prevDate).inDays;

      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  /// Productivity score (0.0 - 1.0) since [since].
  ///
  /// Computed as a weighted combination of:
  /// - Completion rate (40%)
  /// - Streak bonus (30%) — current streak / days in range
  /// - On-time rate (30%) — fraction of events completed before due date
  static double productivityScore(
    List<PkCompletionEvent> events,
    DateTime since,
  ) {
    if (events.isEmpty) return 0.0;

    final now = DateTime.now();
    final inRange = events
        .where((e) => !e.timestamp.isBefore(since) && !e.timestamp.isAfter(now))
        .toList();

    if (inRange.isEmpty) return 0.0;

    final rate = completionRate(inRange, since);
    final daysSince = now.difference(since).inDays + 1;
    final streak = currentStreak(inRange);
    final streakBonus = (streak / daysSince).clamp(0.0, 1.0);

    final withDueDate = inRange.where((e) => e.wasOnTime != null);
    final onTimeRate = withDueDate.isEmpty
        ? 1.0
        : withDueDate.where((e) => e.wasOnTime == true).length /
            withDueDate.length;

    return (rate * 0.4 + streakBonus * 0.3 + onTimeRate * 0.3).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<String> _uniqueSortedDayKeys(List<PkCompletionEvent> events) {
    final keys = <String>{};
    for (final event in events) {
      keys.add(_dateKey(event.timestamp));
    }
    return keys.toList()..sort();
  }

  static int _isoWeekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays + 1;
    return date.year * 100 + ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
