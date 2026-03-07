/// DateTime extension methods.
extension PrimekitDateTimeExtensions on DateTime {
  // ---------------------------------------------------------------------------
  // Predicates
  // ---------------------------------------------------------------------------

  /// Returns `true` if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns `true` if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns `true` if this date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Returns `true` if this date is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Returns `true` if this date is within [duration] from now.
  bool isWithin(Duration duration) =>
      difference(DateTime.now()).abs() <= duration;

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  /// Formats as `YYYY-MM-DD`.
  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Returns a human-readable relative time string.
  ///
  /// `'2 hours ago'`, `'in 3 days'`, `'just now'`
  String get relative {
    final diff = DateTime.now().difference(this);
    final abs = diff.abs();
    final prefix = diff.isNegative ? 'in ' : '';
    final suffix = diff.isNegative ? '' : ' ago';

    if (abs.inSeconds < 60) return 'just now';
    if (abs.inMinutes < 60) {
      final m = abs.inMinutes;
      return '$prefix$m ${m == 1 ? 'minute' : 'minutes'}$suffix';
    }
    if (abs.inHours < 24) {
      final h = abs.inHours;
      return '$prefix$h ${h == 1 ? 'hour' : 'hours'}$suffix';
    }
    if (abs.inDays < 7) {
      final d = abs.inDays;
      return '$prefix$d ${d == 1 ? 'day' : 'days'}$suffix';
    }
    if (abs.inDays < 30) {
      final w = (abs.inDays / 7).floor();
      return '$prefix$w ${w == 1 ? 'week' : 'weeks'}$suffix';
    }
    if (abs.inDays < 365) {
      final mo = (abs.inDays / 30).floor();
      return '$prefix$mo ${mo == 1 ? 'month' : 'months'}$suffix';
    }
    final y = (abs.inDays / 365).floor();
    return '$prefix$y ${y == 1 ? 'year' : 'years'}$suffix';
  }

  // ---------------------------------------------------------------------------
  // Manipulation
  // ---------------------------------------------------------------------------

  /// Returns a copy of this date with time set to midnight (start of day).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a copy of this date with time set to 23:59:59.999.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a copy of this date with time set to the start of the month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns a copy of this date with time set to the end of the month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Adds [days] days.
  DateTime addDays(int days) => add(Duration(days: days));

  /// Subtracts [days] days.
  DateTime subtractDays(int days) => subtract(Duration(days: days));
}
