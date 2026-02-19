import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date and time formatting utilities.
///
/// All methods accept an optional `locale` parameter. When omitted, the
/// method falls back to the default locale or the system locale.
///
/// ```dart
/// PkDateFormatter.shortDate(DateTime.now())             // '2/19/2026'
/// PkDateFormatter.longDate(DateTime.now())              // 'February 19, 2026'
/// PkDateFormatter.time(DateTime.now())                  // '3:45 PM'
/// PkDateFormatter.time(DateTime.now(), use24h: true)    // '15:45'
/// PkDateFormatter.dateTime(DateTime.now())              // 'Feb 19, 3:45 PM'
/// PkDateFormatter.relative(DateTime.now()
///     .subtract(const Duration(hours: 2)))              // '2 hours ago'
/// PkDateFormatter.monthYear(DateTime.now())             // 'February 2026'
/// ```
class PkDateFormatter {
  PkDateFormatter._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Formats [date] as a short numeric date: `12/25/2024`.
  static String shortDate(DateTime date, {Locale? locale}) =>
      DateFormat.yMd(_localeString(locale)).format(date);

  /// Formats [date] as a long human-readable date: `December 25, 2024`.
  static String longDate(DateTime date, {Locale? locale}) =>
      DateFormat.yMMMMd(_localeString(locale)).format(date);

  /// Formats the time portion of [date].
  ///
  /// When [use24h] is `true` a 24-hour clock is used (`15:45`);
  /// otherwise a 12-hour clock is used (`3:45 PM`).
  static String time(
    DateTime date, {
    Locale? locale,
    bool use24h = false,
  }) {
    final localeStr = _localeString(locale);
    final pattern =
        use24h ? DateFormat.Hm(localeStr) : DateFormat.jm(localeStr);
    return pattern.format(date);
  }

  /// Formats [date] as a compact date-and-time string: `Dec 25, 2:30 PM`.
  static String dateTime(DateTime date, {Locale? locale}) =>
      DateFormat.MMMd(_localeString(locale)).add_jm().format(date);

  /// Formats [date] as a relative human-readable string.
  ///
  /// Examples: `'just now'`, `'2 hours ago'`, `'in 3 days'`.
  ///
  /// Falls back to [longDate] for differences greater than 365 days.
  static String relative(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);
    final absDiff = diff.abs();
    final isPast = !diff.isNegative;

    if (absDiff.inSeconds < 60) {
      return 'just now';
    } else if (absDiff.inMinutes < 60) {
      final n = absDiff.inMinutes;
      final label = '$n ${_plural(n, 'minute')}';
      return isPast ? '$label ago' : 'in $label';
    } else if (absDiff.inHours < 24) {
      final n = absDiff.inHours;
      final label = '$n ${_plural(n, 'hour')}';
      return isPast ? '$label ago' : 'in $label';
    } else if (absDiff.inDays < 7) {
      final n = absDiff.inDays;
      final label = '$n ${_plural(n, 'day')}';
      return isPast ? '$label ago' : 'in $label';
    } else if (absDiff.inDays < 30) {
      final n = (absDiff.inDays / 7).floor();
      final label = '$n ${_plural(n, 'week')}';
      return isPast ? '$label ago' : 'in $label';
    } else if (absDiff.inDays < 365) {
      final n = (absDiff.inDays / 30).floor();
      final label = '$n ${_plural(n, 'month')}';
      return isPast ? '$label ago' : 'in $label';
    } else {
      return longDate(date);
    }
  }

  /// Formats [date] as month and year only: `December 2024`.
  static String monthYear(DateTime date, {Locale? locale}) =>
      DateFormat.yMMMM(_localeString(locale)).format(date);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static String? _localeString(Locale? locale) => locale?.toLanguageTag();

  static String _plural(int count, String word) =>
      count == 1 ? word : '${word}s';
}
