import 'package:flutter_test/flutter_test.dart';

import 'package:primekit/src/i18n/currency_formatter.dart';

void main() {
  group('PkCurrencyFormatter.format', () {
    test('formats USD amount correctly', () {
      final result = PkCurrencyFormatter.format(9.99, 'USD', locale: 'en_US');
      expect(result, contains('9.99'));
      expect(result, contains(r'$'));
    });

    test('formats zero amount', () {
      final result = PkCurrencyFormatter.format(0, 'USD', locale: 'en_US');
      expect(result, contains('0'));
    });

    test('formats negative amount', () {
      final result = PkCurrencyFormatter.format(-5.5, 'USD', locale: 'en_US');
      expect(result, contains('5.5'));
      // Negative formatting varies by locale, but should contain the digits.
    });

    test('formats large amount with thousands separator', () {
      final result =
          PkCurrencyFormatter.format(1234567.89, 'USD', locale: 'en_US');
      expect(result, contains('1,234,567'));
    });

    test('formats EUR with de_DE locale', () {
      final result = PkCurrencyFormatter.format(9.99, 'EUR', locale: 'de_DE');
      // German locale uses comma as decimal separator.
      expect(result, contains('9,99'));
      expect(result, contains('€'));
    });

    test('unknown currency code falls back to code as symbol', () {
      // Should not throw; uses code as symbol fallback.
      final result =
          PkCurrencyFormatter.format(10.0, 'XYZ', locale: 'en_US');
      expect(result, isNotEmpty);
    });
  });

  group('PkCurrencyFormatter.compact', () {
    test('formats amount below 1000 as full format', () {
      final result = PkCurrencyFormatter.compact(500, 'USD', locale: 'en_US');
      expect(result, contains('500'));
      expect(result, isNot(contains('K')));
    });

    test('formats thousands as K', () {
      final result = PkCurrencyFormatter.compact(9900, 'USD', locale: 'en_US');
      expect(result, contains('K'));
      expect(result, contains('9.9'));
    });

    test('formats exact 1000 as 1K', () {
      final result = PkCurrencyFormatter.compact(1000, 'USD', locale: 'en_US');
      expect(result, contains('1K'));
    });

    test('trims trailing .0 for whole K values', () {
      final result = PkCurrencyFormatter.compact(2000, 'USD', locale: 'en_US');
      expect(result, contains('2K'));
      expect(result, isNot(contains('2.0K')));
    });

    test('formats millions as M', () {
      final result =
          PkCurrencyFormatter.compact(1200000, 'USD', locale: 'en_US');
      expect(result, contains('1.2M'));
    });

    test('formats exact 1 million as 1M', () {
      final result =
          PkCurrencyFormatter.compact(1000000, 'USD', locale: 'en_US');
      expect(result, contains('1M'));
    });

    test('formats billions as B', () {
      final result =
          PkCurrencyFormatter.compact(2500000000, 'USD', locale: 'en_US');
      expect(result, contains('2.5B'));
    });

    test('formats exact 1 billion as 1B', () {
      final result =
          PkCurrencyFormatter.compact(1000000000, 'USD', locale: 'en_US');
      expect(result, contains('1B'));
    });

    test('handles negative thousands', () {
      final result =
          PkCurrencyFormatter.compact(-5000, 'USD', locale: 'en_US');
      expect(result, contains('-'));
      expect(result, contains('K'));
    });

    test('handles negative millions', () {
      final result =
          PkCurrencyFormatter.compact(-2000000, 'USD', locale: 'en_US');
      expect(result, contains('-'));
      expect(result, contains('M'));
    });

    test('formats zero', () {
      final result = PkCurrencyFormatter.compact(0, 'USD', locale: 'en_US');
      expect(result, contains('0'));
    });
  });

  group('PkCurrencyFormatter.formatRange', () {
    test('formats a range with en-dash separator', () {
      final result =
          PkCurrencyFormatter.formatRange(5, 20, 'USD', locale: 'en_US');
      // Contains en-dash (U+2013).
      expect(result, contains('\u2013'));
    });

    test('range contains both formatted values', () {
      final result =
          PkCurrencyFormatter.formatRange(5, 20, 'USD', locale: 'en_US');
      expect(result, contains('5'));
      expect(result, contains('20'));
    });

    test('formats range with equal min and max', () {
      final result =
          PkCurrencyFormatter.formatRange(10, 10, 'USD', locale: 'en_US');
      expect(result, contains('10'));
    });

    test('formats range with zero min', () {
      final result =
          PkCurrencyFormatter.formatRange(0, 100, 'USD', locale: 'en_US');
      expect(result, contains('0'));
      expect(result, contains('100'));
    });
  });
}
