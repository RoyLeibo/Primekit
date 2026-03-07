import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/billing.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PricingInfo _monthly({
  double amount = 9.99,
  String currency = 'USD',
  Duration? trial,
}) => PricingInfo(
  amount: amount,
  currency: currency,
  period: BillingPeriod.monthly,
  trialPeriod: trial,
);

PricingInfo _yearly({double amount = 99.99, String currency = 'USD'}) =>
    PricingInfo(
      amount: amount,
      currency: currency,
      period: BillingPeriod.yearly,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // format
  // -------------------------------------------------------------------------

  group('PricingFormatter.format()', () {
    test('formats USD amount with dollar sign', () {
      final result = PricingFormatter.format(9.99, 'USD', locale: 'en_US');
      expect(result, contains('9.99'));
      expect(result, contains(r'$'));
    });

    test('formats zero amount', () {
      final result = PricingFormatter.format(0.0, 'USD', locale: 'en_US');
      expect(result, contains('0'));
    });

    test('formats large amount', () {
      final result = PricingFormatter.format(1999.99, 'USD', locale: 'en_US');
      expect(result, contains('1,999.99'));
    });

    test('falls back gracefully for unrecognised locale', () {
      // Should not throw; fallback returns plain concatenation.
      final result = PricingFormatter.format(9.99, 'USD', locale: 'xx_INVALID');
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });

    test('JPY uses zero decimal digits', () {
      final result = PricingFormatter.format(1000, 'JPY', locale: 'ja_JP');
      // JPY should not have decimal separator for .00
      expect(result, isNot(contains('.')));
    });

    test('formats EUR amount', () {
      final result = PricingFormatter.format(9.99, 'EUR', locale: 'en_US');
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // formatPeriod
  // -------------------------------------------------------------------------

  group('PricingFormatter.formatPeriod()', () {
    test('monthly pricing includes /month suffix', () {
      final result = PricingFormatter.formatPeriod(_monthly(), locale: 'en_US');
      expect(result, contains('/month'));
    });

    test('yearly pricing includes /year suffix', () {
      final result = PricingFormatter.formatPeriod(_yearly(), locale: 'en_US');
      expect(result, contains('/year'));
    });

    test('weekly pricing includes /week suffix', () {
      final pricing = PricingInfo(
        amount: 2.99,
        currency: 'USD',
        period: BillingPeriod.weekly,
      );
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('/week'));
    });

    test('quarterly pricing includes /3 months suffix', () {
      final pricing = PricingInfo(
        amount: 24.99,
        currency: 'USD',
        period: BillingPeriod.quarterly,
      );
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('/3 months'));
    });

    test('lifetime pricing includes one-time label', () {
      final pricing = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('one-time'));
    });

    test('null period produces no period label', () {
      final pricing = PricingInfo(amount: 9.99, currency: 'USD');
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, isNot(contains('/')));
      expect(result, isNot(contains('one-time')));
    });

    test('includes trial prefix when trial period is set — days', () {
      final pricing = _monthly(trial: const Duration(days: 7));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('Free trial'));
      expect(result, contains('7 days'));
      expect(result, contains('then'));
    });

    test('includes trial prefix — 1 day singular', () {
      final pricing = _monthly(trial: const Duration(days: 1));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('1 day'));
    });

    test('includes trial prefix — weeks', () {
      final pricing = _monthly(trial: const Duration(days: 14));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('2 weeks'));
    });

    test('includes trial prefix — 1 week singular', () {
      final pricing = _monthly(trial: const Duration(days: 7));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('1 week'));
    });

    test('includes trial prefix — months', () {
      final pricing = _monthly(trial: const Duration(days: 30));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('1 month'));
    });

    test('includes trial prefix — years', () {
      final pricing = _monthly(trial: const Duration(days: 365));
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, contains('1 year'));
    });

    test('zero trial period shows no trial prefix', () {
      final pricing = _monthly(trial: Duration.zero);
      final result = PricingFormatter.formatPeriod(pricing, locale: 'en_US');
      expect(result, isNot(contains('Free trial')));
    });
  });

  // -------------------------------------------------------------------------
  // formatSavings
  // -------------------------------------------------------------------------

  group('PricingFormatter.formatSavings()', () {
    test('returns Save X% string for standard monthly vs annual', () {
      // Monthly: $9.99/month -> $9.99/month
      // Annual:  $99.99/year -> $8.33/month
      // Saving ~ 17%
      final result = PricingFormatter.formatSavings(_monthly(), _yearly());
      expect(result, isNotNull);
      expect(result, startsWith('Save '));
      expect(result, contains('%'));
    });

    test('returns null when monthly has no perMonthPrice', () {
      final lifetimePlan = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      final result = PricingFormatter.formatSavings(lifetimePlan, _yearly());
      expect(result, isNull);
    });

    test('returns null when annual has no perMonthPrice', () {
      final lifetimePlan = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      expect(PricingFormatter.formatSavings(_monthly(), lifetimePlan), isNull);
    });

    test('returns null when annual is more expensive than monthly', () {
      final expensiveYearly = PricingInfo(
        amount: 200.00,
        currency: 'USD',
        period: BillingPeriod.yearly,
      );
      final result = PricingFormatter.formatSavings(
        _monthly(),
        expensiveYearly,
      );
      expect(result, isNull);
    });

    test('savings percentage is rounded to nearest integer', () {
      final result = PricingFormatter.formatSavings(_monthly(), _yearly());
      // Result is like 'Save 17%' — the number should be parseable.
      final match = RegExp(r'Save (\d+)%').firstMatch(result!);
      expect(match, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // savingsRatio
  // -------------------------------------------------------------------------

  group('PricingFormatter.savingsRatio()', () {
    test('returns a value between 0 and 1 for valid inputs', () {
      final ratio = PricingFormatter.savingsRatio(_monthly(), _yearly());
      expect(ratio, isNotNull);
      expect(ratio!, greaterThan(0));
      expect(ratio, lessThan(1));
    });

    test('returns null for lifetime monthly plan', () {
      final lifetimePlan = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      expect(PricingFormatter.savingsRatio(lifetimePlan, _yearly()), isNull);
    });

    test('returns null when annual costs more per month', () {
      final expensiveYearly = PricingInfo(
        amount: 500.0,
        currency: 'USD',
        period: BillingPeriod.yearly,
      );
      expect(
        PricingFormatter.savingsRatio(_monthly(), expensiveYearly),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  // PricingInfo — perMonthPrice
  // -------------------------------------------------------------------------

  group('PricingInfo.perMonthPrice', () {
    test('monthly returns amount directly', () {
      expect(_monthly(amount: 9.99).perMonthPrice, 9.99);
    });

    test('yearly divides by 12', () {
      expect(_yearly(amount: 120.0).perMonthPrice, closeTo(10.0, 0.01));
    });

    test('quarterly divides by 3', () {
      final quarterly = PricingInfo(
        amount: 29.97,
        currency: 'USD',
        period: BillingPeriod.quarterly,
      );
      expect(quarterly.perMonthPrice, closeTo(9.99, 0.01));
    });

    test('weekly multiplies by 52/12', () {
      final weekly = PricingInfo(
        amount: 2.31,
        currency: 'USD',
        period: BillingPeriod.weekly,
      );
      expect(weekly.perMonthPrice, closeTo(2.31 * 52 / 12, 0.01));
    });

    test('lifetime returns null', () {
      final lifetime = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      expect(lifetime.perMonthPrice, isNull);
    });

    test('null period returns amount', () {
      final oneTime = PricingInfo(amount: 9.99, currency: 'USD');
      expect(oneTime.perMonthPrice, 9.99);
    });
  });

  // -------------------------------------------------------------------------
  // PricingInfo — perYearPrice
  // -------------------------------------------------------------------------

  group('PricingInfo.perYearPrice', () {
    test('monthly multiplies by 12', () {
      expect(_monthly(amount: 9.99).perYearPrice, closeTo(119.88, 0.01));
    });

    test('yearly returns amount directly', () {
      expect(_yearly(amount: 99.99).perYearPrice, 99.99);
    });

    test('lifetime returns null', () {
      final lifetime = PricingInfo(
        amount: 49.99,
        currency: 'USD',
        period: BillingPeriod.lifetime,
      );
      expect(lifetime.perYearPrice, isNull);
    });
  });
}
