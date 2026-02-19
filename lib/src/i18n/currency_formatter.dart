import 'package:intl/intl.dart';

/// Locale-aware currency formatting utilities.
///
/// ```dart
/// PkCurrencyFormatter.format(9.99, 'USD')                // '$9.99'
/// PkCurrencyFormatter.format(9.99, 'EUR', locale: 'de_DE') // '9,99 €'
/// PkCurrencyFormatter.compact(9900, 'USD')               // '$9.9K'
/// PkCurrencyFormatter.compact(1200000, 'USD')            // '$1.2M'
/// PkCurrencyFormatter.formatRange(5, 20, 'USD')          // '$5–$20'
/// ```
class PkCurrencyFormatter {
  PkCurrencyFormatter._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Formats [amount] using the symbol and conventions for [currencyCode].
  ///
  /// [locale] controls number grouping and decimal separator conventions.
  /// When omitted, [Intl.defaultLocale] (or the system locale) is used.
  ///
  /// Examples:
  /// - `format(9.99, 'USD')` → `'$9.99'`
  /// - `format(9.99, 'EUR', locale: 'de_DE')` → `'9,99 €'`
  /// - `format(999, 'JPY')` → `'¥999'`
  static String format(
    double amount,
    String currencyCode, {
    String? locale,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: _symbolFor(currencyCode, locale),
    );
    return formatter.format(amount);
  }

  /// Formats [amount] in a compact, human-readable form.
  ///
  /// - `compact(9900, 'USD')` → `'$9.9K'`
  /// - `compact(1200000, 'USD')` → `'$1.2M'`
  /// - `compact(500, 'USD')` → `'$500'` (falls back to [format])
  static String compact(
    double amount,
    String currencyCode, {
    String? locale,
  }) {
    final symbol = _symbolFor(currencyCode, locale);
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';

    if (absAmount >= 1e9) {
      final value = absAmount / 1e9;
      return '$sign$symbol${_trimTrailingZero(value.toStringAsFixed(1))}B';
    } else if (absAmount >= 1e6) {
      final value = absAmount / 1e6;
      return '$sign$symbol${_trimTrailingZero(value.toStringAsFixed(1))}M';
    } else if (absAmount >= 1e3) {
      final value = absAmount / 1e3;
      return '$sign$symbol${_trimTrailingZero(value.toStringAsFixed(1))}K';
    } else {
      return format(amount, currencyCode, locale: locale);
    }
  }

  /// Formats a price range as `$5–$20`.
  ///
  /// The separator is an en-dash (U+2013) with no surrounding spaces,
  /// matching common typographic conventions for ranges.
  static String formatRange(
    double min,
    double max,
    String currencyCode, {
    String? locale,
  }) {
    final minStr = format(min, currencyCode, locale: locale);
    final maxStr = format(max, currencyCode, locale: locale);
    return '$minStr\u2013$maxStr';
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the currency symbol for [currencyCode].
  static String _symbolFor(String currencyCode, String? locale) {
    try {
      return NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      ).currencySymbol;
    } on Exception {
      return currencyCode;
    }
  }

  static String _trimTrailingZero(String value) =>
      value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
}
