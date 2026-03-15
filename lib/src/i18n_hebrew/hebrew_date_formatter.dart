import 'package:kosher_dart/kosher_dart.dart';

/// Formats Gregorian [DateTime] values as Hebrew calendar date strings.
///
/// Uses `kosher_dart` internally for accurate Hebrew calendar conversion.
///
/// ```dart
/// PkHebrewDateFormatter.format(DateTime(2026, 3, 15))
///   // => "ט״ו אדר תשפ״ו"
///
/// PkHebrewDateFormatter.formatShort(DateTime(2026, 3, 15))
///   // => "ט״ו אדר"
///
/// PkHebrewDateFormatter.hebrewYear(DateTime(2026, 3, 15))
///   // => 5786
/// ```
abstract final class PkHebrewDateFormatter {
  /// Formats [date] as a full Hebrew date string with geresh/gershayim.
  ///
  /// Example output: `"כ״ה טבת תשפ״ד"`.
  /// Returns an empty string if the conversion fails.
  static String format(DateTime date) {
    try {
      final jewishDate = JewishDate.fromDateTime(date);
      final formatter = HebrewDateFormatter()
        ..hebrewFormat = true
        ..useGershGershayim = true;
      return formatter.format(jewishDate, pattern: 'dd MM yy');
    } catch (_) {
      return '';
    }
  }

  /// Formats [date] as a short Hebrew date (day and month only).
  ///
  /// Example output: `"כ״ה טבת"`.
  /// Returns an empty string if the conversion fails.
  static String formatShort(DateTime date) {
    try {
      final jewishDate = JewishDate.fromDateTime(date);
      final formatter = HebrewDateFormatter()
        ..hebrewFormat = true
        ..useGershGershayim = true;
      return formatter.format(jewishDate, pattern: 'dd MM');
    } catch (_) {
      return '';
    }
  }

  /// Returns the Hebrew year for the given Gregorian [date].
  ///
  /// Example: `DateTime(2026, 3, 15)` => `5786`.
  /// Returns `0` if the conversion fails.
  static int hebrewYear(DateTime date) {
    try {
      final jewishDate = JewishDate.fromDateTime(date);
      return jewishDate.getJewishYear();
    } catch (_) {
      return 0;
    }
  }

  /// Returns the Hebrew month name for the given Gregorian [date].
  ///
  /// Example: `DateTime(2026, 3, 15)` => `"אדר"`.
  /// Returns an empty string if the conversion fails.
  static String hebrewMonth(DateTime date) {
    try {
      final jewishDate = JewishDate.fromDateTime(date);
      final formatter = HebrewDateFormatter()..hebrewFormat = true;
      return formatter.format(jewishDate, pattern: 'MM');
    } catch (_) {
      return '';
    }
  }
}
