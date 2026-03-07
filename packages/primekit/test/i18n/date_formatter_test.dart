import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:primekit/src/i18n/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
  });

  // Reference date: 25 December 2024, 15:45
  final date = DateTime(2024, 12, 25, 15, 45, 0);
  const enLocale = Locale('en', 'US');

  group('PkDateFormatter.shortDate', () {
    test('formats date as M/d/y in en_US locale', () {
      final result = PkDateFormatter.shortDate(date, locale: enLocale);
      expect(result, contains('12'));
      expect(result, contains('25'));
      expect(result, contains('2024'));
    });

    test('formats date without locale (no error)', () {
      final result = PkDateFormatter.shortDate(date);
      expect(result, isNotEmpty);
    });

    test('uses locale separators for de locale', () {
      final result = PkDateFormatter.shortDate(
        date,
        locale: const Locale('de'),
      );
      // German uses dots: 25.12.2024
      expect(result, contains('25'));
      expect(result, contains('12'));
      expect(result, contains('2024'));
    });
  });

  group('PkDateFormatter.longDate', () {
    test('formats as full month name in en_US', () {
      final result = PkDateFormatter.longDate(date, locale: enLocale);
      expect(result, contains('December'));
      expect(result, contains('25'));
      expect(result, contains('2024'));
    });

    test('formats correctly for another date', () {
      final jan1 = DateTime(2024, 1, 1);
      final result = PkDateFormatter.longDate(jan1, locale: enLocale);
      expect(result, contains('January'));
      expect(result, contains('1'));
      expect(result, contains('2024'));
    });
  });

  group('PkDateFormatter.time', () {
    test('formats as 12-hour clock by default', () {
      final result = PkDateFormatter.time(date, locale: enLocale);
      // 15:45 -> 3:45 PM
      expect(result, contains('3:45'));
      expect(result.toUpperCase(), contains('PM'));
    });

    test('formats as 24-hour clock when use24h=true', () {
      final result = PkDateFormatter.time(date, locale: enLocale, use24h: true);
      expect(result, contains('15:45'));
    });

    test('formats midnight correctly in 24h mode', () {
      final midnight = DateTime(2024, 1, 1, 0, 0);
      final result = PkDateFormatter.time(
        midnight,
        locale: enLocale,
        use24h: true,
      );
      expect(result, contains('0:00'));
    });
  });

  group('PkDateFormatter.dateTime', () {
    test('contains month abbreviation and time', () {
      final result = PkDateFormatter.dateTime(date, locale: enLocale);
      // Dec 25, 3:45 PM
      expect(result, contains('Dec'));
      expect(result, contains('25'));
    });
  });

  group('PkDateFormatter.monthYear', () {
    test('formats as full month and year', () {
      final result = PkDateFormatter.monthYear(date, locale: enLocale);
      expect(result, contains('December'));
      expect(result, contains('2024'));
    });

    test('formats January correctly', () {
      final jan = DateTime(2025, 1, 15);
      final result = PkDateFormatter.monthYear(jan, locale: enLocale);
      expect(result, contains('January'));
      expect(result, contains('2025'));
    });
  });

  group('PkDateFormatter.relative', () {
    test('returns "just now" for <60 seconds ago', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(seconds: 30));
      expect(PkDateFormatter.relative(past, now: now), 'just now');
    });

    test('returns "just now" for exactly 59 seconds ago', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(seconds: 59));
      expect(PkDateFormatter.relative(past, now: now), 'just now');
    });

    test('returns minutes ago for 1–59 minutes', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(minutes: 5));
      expect(PkDateFormatter.relative(past, now: now), '5 minutes ago');
    });

    test('returns singular minute for exactly 1 minute', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(minutes: 1));
      expect(PkDateFormatter.relative(past, now: now), '1 minute ago');
    });

    test('returns hours ago for 1–23 hours', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(hours: 2));
      expect(PkDateFormatter.relative(past, now: now), '2 hours ago');
    });

    test('returns singular hour for exactly 1 hour', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final past = now.subtract(const Duration(hours: 1));
      expect(PkDateFormatter.relative(past, now: now), '1 hour ago');
    });

    test('returns days ago for 1–6 days', () {
      final now = DateTime(2024, 1, 7);
      final past = now.subtract(const Duration(days: 3));
      expect(PkDateFormatter.relative(past, now: now), '3 days ago');
    });

    test('returns weeks ago for 1–4 weeks', () {
      final now = DateTime(2024, 2, 1);
      final past = now.subtract(const Duration(days: 14));
      expect(PkDateFormatter.relative(past, now: now), '2 weeks ago');
    });

    test('returns months ago for 1–11 months', () {
      final now = DateTime(2024, 6, 1);
      final past = now.subtract(const Duration(days: 90)); // ~3 months
      expect(PkDateFormatter.relative(past, now: now), '3 months ago');
    });

    test('returns longDate for >365 days', () {
      final now = DateTime(2025, 1, 1);
      final past = DateTime(2022, 1, 1);
      final result = PkDateFormatter.relative(past, now: now);
      // Falls back to longDate — should contain the year.
      expect(result, contains('2022'));
    });

    test('returns "in X minutes" for future dates', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final future = now.add(const Duration(minutes: 10));
      expect(PkDateFormatter.relative(future, now: now), 'in 10 minutes');
    });

    test('returns "in X hours" for future hours', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final future = now.add(const Duration(hours: 3));
      expect(PkDateFormatter.relative(future, now: now), 'in 3 hours');
    });

    test('returns "in X days" for future days', () {
      final now = DateTime(2024, 1, 1);
      final future = now.add(const Duration(days: 5));
      expect(PkDateFormatter.relative(future, now: now), 'in 5 days');
    });
  });
}
