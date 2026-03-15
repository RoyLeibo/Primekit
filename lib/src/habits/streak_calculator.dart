import 'habit.dart';

/// Pure-function streak and completion-rate calculator for habits.
///
/// All methods are static, side-effect free, and compute results solely
/// from their inputs. No state, no I/O, no framework dependencies.
class StreakCalculator {
  StreakCalculator._();

  /// Current consecutive-period streak ending at today (or yesterday).
  ///
  /// For [PkHabitFrequency.daily], counts consecutive days.
  /// For [PkHabitFrequency.weekly], counts consecutive weeks.
  /// For [PkHabitFrequency.monthly], counts consecutive months.
  static int currentStreak(
    List<DateTime> completionDates, {
    PkHabitFrequency frequency = PkHabitFrequency.daily,
  }) {
    if (completionDates.isEmpty) return 0;

    return switch (frequency) {
      PkHabitFrequency.daily => _currentDailyStreak(completionDates),
      PkHabitFrequency.weekly => _currentWeeklyStreak(completionDates),
      PkHabitFrequency.monthly => _currentMonthlyStreak(completionDates),
      PkHabitFrequency.custom => _currentDailyStreak(completionDates),
    };
  }

  /// Longest consecutive-period streak ever achieved.
  static int longestStreak(
    List<DateTime> completionDates, {
    PkHabitFrequency frequency = PkHabitFrequency.daily,
  }) {
    if (completionDates.isEmpty) return 0;

    return switch (frequency) {
      PkHabitFrequency.daily => _longestDailyStreak(completionDates),
      PkHabitFrequency.weekly => _longestWeeklyStreak(completionDates),
      PkHabitFrequency.monthly => _longestMonthlyStreak(completionDates),
      PkHabitFrequency.custom => _longestDailyStreak(completionDates),
    };
  }

  /// Completion rate as a fraction (0.0 - 1.0) since [since].
  static double completionRate(
    List<DateTime> completionDates,
    DateTime since, {
    PkHabitFrequency frequency = PkHabitFrequency.daily,
  }) {
    if (completionDates.isEmpty) return 0.0;

    final now = DateTime.now();
    final daysSince = now.difference(since).inDays + 1;
    if (daysSince <= 0) return 0.0;

    final inRange = completionDates
        .where((d) => !d.isBefore(since) && !d.isAfter(now))
        .length;

    final periods = switch (frequency) {
      PkHabitFrequency.daily => daysSince,
      PkHabitFrequency.weekly => (daysSince / 7).ceil(),
      PkHabitFrequency.monthly =>
        (now.year - since.year) * 12 + now.month - since.month + 1,
      PkHabitFrequency.custom => daysSince,
    };

    if (periods <= 0) return 0.0;
    return (inRange / periods).clamp(0.0, 1.0);
  }

  /// GitHub-style heatmap data: normalized date -> completion count.
  ///
  /// Returns a map where keys are dates stripped to midnight and values
  /// are the number of completions on that day.
  static Map<DateTime, int> heatmapData(
    List<DateTime> completionDates, {
    int daysBack = 365,
  }) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));
    final result = <DateTime, int>{};

    for (final d in completionDates) {
      final normalized = DateTime(d.year, d.month, d.day);
      if (normalized.isBefore(cutoff)) continue;
      result[normalized] = (result[normalized] ?? 0) + 1;
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Daily streak helpers
  // ---------------------------------------------------------------------------

  static int _currentDailyStreak(List<DateTime> dates) {
    final sorted = _sortedNormalized(dates, ascending: false);
    final today = _normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (!_containsDate(sorted, today) && !_containsDate(sorted, yesterday)) {
      return 0;
    }

    var streak = 0;
    var check = today;
    while (_containsDate(sorted, check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _longestDailyStreak(List<DateTime> dates) {
    final sorted = _sortedNormalized(dates, ascending: true);
    var longest = 0;
    var current = 0;
    DateTime? last;

    for (final d in sorted) {
      if (last == null) {
        current = 1;
      } else {
        final diff = d.difference(last).inDays;
        if (diff == 1) {
          current++;
        } else if (diff > 1) {
          longest = current > longest ? current : longest;
          current = 1;
        }
        // diff == 0: same day duplicate, skip
      }
      last = d;
    }

    return current > longest ? current : longest;
  }

  // ---------------------------------------------------------------------------
  // Weekly streak helpers
  // ---------------------------------------------------------------------------

  static int _currentWeeklyStreak(List<DateTime> dates) {
    final now = DateTime.now();
    final thisWeekStart = _mondayOf(now);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    if (!_hasCompletionInWeek(dates, thisWeekStart) &&
        !_hasCompletionInWeek(dates, lastWeekStart)) {
      return 0;
    }

    var streak = 0;
    var checkWeek = thisWeekStart;
    while (_hasCompletionInWeek(dates, checkWeek)) {
      streak++;
      checkWeek = checkWeek.subtract(const Duration(days: 7));
    }
    return streak;
  }

  static int _longestWeeklyStreak(List<DateTime> dates) {
    final weekNumbers = dates
        .map(_weekNumber)
        .toSet()
        .toList()
      ..sort();

    var longest = 0;
    var current = 1;

    for (var i = 1; i < weekNumbers.length; i++) {
      if (weekNumbers[i] == weekNumbers[i - 1] + 1) {
        current++;
      } else {
        longest = current > longest ? current : longest;
        current = 1;
      }
    }

    return current > longest ? current : longest;
  }

  // ---------------------------------------------------------------------------
  // Monthly streak helpers
  // ---------------------------------------------------------------------------

  static int _currentMonthlyStreak(List<DateTime> dates) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    if (!_hasCompletionInMonth(dates, thisMonth) &&
        !_hasCompletionInMonth(dates, lastMonth)) {
      return 0;
    }

    var streak = 0;
    var checkMonth = thisMonth;
    while (_hasCompletionInMonth(dates, checkMonth)) {
      streak++;
      checkMonth = DateTime(checkMonth.year, checkMonth.month - 1);
    }
    return streak;
  }

  static int _longestMonthlyStreak(List<DateTime> dates) {
    final monthNumbers = dates
        .map((d) => d.year * 12 + d.month)
        .toSet()
        .toList()
      ..sort();

    var longest = 0;
    var current = 1;

    for (var i = 1; i < monthNumbers.length; i++) {
      if (monthNumbers[i] == monthNumbers[i - 1] + 1) {
        current++;
      } else {
        longest = current > longest ? current : longest;
        current = 1;
      }
    }

    return current > longest ? current : longest;
  }

  // ---------------------------------------------------------------------------
  // Shared utilities
  // ---------------------------------------------------------------------------

  static DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DateTime> _sortedNormalized(
    List<DateTime> dates, {
    required bool ascending,
  }) {
    final normalized = dates.map(_normalizeDate).toSet().toList();
    normalized.sort(
      ascending ? (a, b) => a.compareTo(b) : (a, b) => b.compareTo(a),
    );
    return normalized;
  }

  static bool _containsDate(List<DateTime> sorted, DateTime date) {
    return sorted.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  static DateTime _mondayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));

  static bool _hasCompletionInWeek(List<DateTime> dates, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return dates.any((d) {
      final normalized = _normalizeDate(d);
      return !normalized.isBefore(weekStart) && !normalized.isAfter(weekEnd);
    });
  }

  static bool _hasCompletionInMonth(List<DateTime> dates, DateTime month) {
    return dates.any((d) => d.year == month.year && d.month == month.month);
  }

  static int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays + 1;
    return date.year * 100 + ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
