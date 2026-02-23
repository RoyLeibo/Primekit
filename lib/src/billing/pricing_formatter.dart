import 'package:intl/intl.dart';

import 'product_catalog.dart';

/// Locale-aware utility for formatting [PricingInfo] values as human-readable
/// price strings.
///
/// All methods are static — no instance is needed:
///
/// ```dart
/// PricingFormatter.format(9.99, 'USD');
/// // → '$9.99'
///
/// PricingFormatter.formatPeriod(monthlyPricing, locale: 'de_DE');
/// // → '9,99 €/Monat'
///
/// PricingFormatter.formatSavings(monthlyPricing, annualPricing);
/// // → 'Save 17%'
/// ```
abstract final class PricingFormatter {
  // Private constructor — static-only class.
  PricingFormatter._();

  // ---------------------------------------------------------------------------
  // format
  // ---------------------------------------------------------------------------

  /// Returns a locale-aware price string, e.g. `'$9.99'`, `'€9,99'`, `'£9.99'`.
  ///
  /// [amount] is the price value. [currencyCode] is the ISO 4217 currency code
  /// (e.g. `'USD'`, `'EUR'`, `'GBP'`). [locale] defaults to the system locale
  /// when `null`.
  ///
  /// ```dart
  /// PricingFormatter.format(9.99, 'USD');                // '$9.99'
  /// PricingFormatter.format(9.99, 'EUR', locale: 'de'); // '9,99 €'
  /// PricingFormatter.format(9.99, 'GBP', locale: 'en_GB'); // '£9.99'
  /// ```
  static String format(double amount, String currencyCode, {String? locale}) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: _currencySymbol(currencyCode, locale),
        decimalDigits: _decimalDigits(currencyCode),
      );
      return formatter.format(amount);
    } on Exception {
      // Fallback: plain concatenation when the locale is unrecognised.
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }

  // ---------------------------------------------------------------------------
  // formatPeriod
  // ---------------------------------------------------------------------------

  /// Returns a human-readable price string including the billing period and
  /// optional trial information.
  ///
  /// Examples:
  /// - `'$9.99/month'`
  /// - `'$99.99/year'`
  /// - `'$4.99/week'`
  /// - `'$249.99 one-time'`
  /// - `'Free trial for 7 days, then $9.99/month'`
  ///
  /// [locale] defaults to the system locale when `null`.
  static String formatPeriod(PricingInfo pricing, {String? locale}) {
    final price = format(pricing.amount, pricing.currency, locale: locale);
    final trial = pricing.trialPeriod;
    final period = pricing.period;

    final periodLabel = switch (period) {
      null => '',
      BillingPeriod.weekly => '/week',
      BillingPeriod.monthly => '/month',
      BillingPeriod.quarterly => '/3 months',
      BillingPeriod.yearly => '/year',
      BillingPeriod.lifetime => ' one-time',
    };

    final priceWithPeriod = '$price$periodLabel';

    if (trial == null || trial == Duration.zero) return priceWithPeriod;

    final trialLabel = _formatTrialDuration(trial);
    return 'Free trial for $trialLabel, then $priceWithPeriod';
  }

  // ---------------------------------------------------------------------------
  // formatSavings
  // ---------------------------------------------------------------------------

  /// Computes and formats the percentage saved by choosing [annual] over
  /// [monthly] billing.
  ///
  /// Returns `null` if the savings cannot be computed (e.g. either price has
  /// no [PricingInfo.perMonthPrice]).
  ///
  /// ```dart
  /// // monthly = $9.99/month, annual = $99.99/year ($8.33/month)
  /// PricingFormatter.formatSavings(monthly, annual); // 'Save 17%'
  /// ```
  static String? formatSavings(PricingInfo monthly, PricingInfo annual) {
    final monthlyPerMonth = monthly.perMonthPrice;
    final annualPerMonth = annual.perMonthPrice;

    if (monthlyPerMonth == null ||
        annualPerMonth == null ||
        monthlyPerMonth <= 0) {
      return null;
    }

    final saving = (monthlyPerMonth - annualPerMonth) / monthlyPerMonth;
    if (saving <= 0) return null;

    final percent = (saving * 100).round();
    return 'Save $percent%';
  }

  /// Same as [formatSavings] but returns the raw decimal ratio (0.0–1.0).
  ///
  /// Returns `null` when savings cannot be computed.
  static double? savingsRatio(PricingInfo monthly, PricingInfo annual) {
    final monthlyPerMonth = monthly.perMonthPrice;
    final annualPerMonth = annual.perMonthPrice;

    if (monthlyPerMonth == null ||
        annualPerMonth == null ||
        monthlyPerMonth <= 0) {
      return null;
    }

    final saving = (monthlyPerMonth - annualPerMonth) / monthlyPerMonth;
    return saving > 0 ? saving : null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the currency symbol for [currencyCode], with locale awareness.
  static String _currencySymbol(String currencyCode, String? locale) {
    try {
      // NumberFormat can resolve the symbol for us.
      final nf = NumberFormat.currency(locale: locale, name: currencyCode);
      return nf.currencySymbol;
    } on Exception {
      return currencyCode;
    }
  }

  /// Most currencies use 2 decimal places; some have 0 (e.g. JPY).
  static int _decimalDigits(String currencyCode) {
    const zeroDecimal = {'JPY', 'KRW', 'VND', 'CLP', 'IDR', 'HUF'};
    return zeroDecimal.contains(currencyCode.toUpperCase()) ? 0 : 2;
  }

  /// Formats a trial [duration] as a human-readable string.
  ///
  /// Examples: `'7 days'`, `'1 month'`, `'2 weeks'`.
  static String _formatTrialDuration(Duration duration) {
    final days = duration.inDays;

    if (days == 0) {
      final hours = duration.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    if (days % 365 == 0) {
      final years = days ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'}';
    }

    if (days % 30 == 0) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'}';
    }

    if (days % 7 == 0) {
      final weeks = days ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }

    return '$days ${days == 1 ? 'day' : 'days'}';
  }
}
