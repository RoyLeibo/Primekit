import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/core/extensions/string_extensions.dart';
import 'package:primekit/src/core/extensions/datetime_extensions.dart';
import 'package:primekit/src/core/extensions/list_extensions.dart';
import 'package:primekit/src/core/extensions/map_extensions.dart';

void main() {
  // ─── String Extensions ────────────────────────────────────────────────────
  group('PrimekitStringExtensions', () {
    group('isEmail', () {
      test('returns true for valid emails', () {
        expect('user@example.com'.isEmail, isTrue);
        expect('user+tag@sub.domain.co.uk'.isEmail, isTrue);
      });

      test('returns false for invalid emails', () {
        expect('notanemail'.isEmail, isFalse);
        expect('@example.com'.isEmail, isFalse);
        expect('user@'.isEmail, isFalse);
        expect(''.isEmail, isFalse);
      });
    });

    group('isUrl', () {
      test('returns true for valid URLs', () {
        expect('https://example.com'.isUrl, isTrue);
        expect('http://sub.domain.com/path?q=1'.isUrl, isTrue);
      });

      test('returns false for non-URLs', () {
        expect('not-a-url'.isUrl, isFalse);
        expect('ftp://example.com'.isUrl, isFalse);
      });
    });

    group('isNumeric', () {
      test('returns true for digit strings', () {
        expect('12345'.isNumeric, isTrue);
        expect('0'.isNumeric, isTrue);
      });
      test('returns false for non-digit strings', () {
        expect('12.3'.isNumeric, isFalse);
        expect('12a'.isNumeric, isFalse);
      });
    });

    group('capitalized', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalized, equals('Hello'));
        expect('world'.capitalized, equals('World'));
        expect(''.capitalized, equals(''));
      });
    });

    group('titleCase', () {
      test('capitalizes all words', () {
        expect('hello world'.titleCase, equals('Hello World'));
        expect('the quick brown fox'.titleCase, equals('The Quick Brown Fox'));
      });
    });

    group('snakeCase', () {
      test('converts camelCase to snake_case', () {
        expect('helloWorld'.snakeCase, equals('hello_world'));
        expect('camelCaseString'.snakeCase, equals('camel_case_string'));
      });
    });

    group('slugified', () {
      test('converts to URL-safe slug', () {
        expect('Hello World!'.slugified, equals('hello-world'));
        expect('My Post Title'.slugified, equals('my-post-title'));
      });
    });

    group('truncate', () {
      test('truncates long strings', () {
        expect('Hello World'.truncate(8), equals('Hello W…'));
        expect('Hi'.truncate(10), equals('Hi'));
      });
    });

    group('nullIfEmpty', () {
      test('returns null for empty string', () => expect(''.nullIfEmpty, isNull));
      test('returns string for non-empty', () => expect('hi'.nullIfEmpty, equals('hi')));
    });

    group('masked', () {
      test('masks middle characters', () {
        expect('secretkey'.masked(visibleStart: 2), equals('se*******'));
        expect('ab'.masked(visibleStart: 2), equals('ab'));
      });
    });
  });

  group('PrimekitNullableStringExtensions', () {
    test('isNullOrEmpty returns true for null', () {
      const String? s = null;
      expect(s.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty string', () {
      expect(''.isNullOrEmpty, isTrue);
    });

    test('orDefault returns fallback when null', () {
      const String? s = null;
      expect(s.orDefault('default'), equals('default'));
    });
  });

  // ─── DateTime Extensions ──────────────────────────────────────────────────
  group('PrimekitDateTimeExtensions', () {
    test('isToday returns true for today', () {
      expect(DateTime.now().isToday, isTrue);
    });

    test('isToday returns false for yesterday', () {
      expect(
        DateTime.now().subtract(const Duration(days: 1)).isToday,
        isFalse,
      );
    });

    test('isYesterday returns true for yesterday', () {
      expect(
        DateTime.now().subtract(const Duration(days: 1)).isYesterday,
        isTrue,
      );
    });

    test('isFuture returns true for future dates', () {
      expect(DateTime.now().add(const Duration(days: 1)).isFuture, isTrue);
    });

    test('isPast returns true for past dates', () {
      expect(DateTime.now().subtract(const Duration(days: 1)).isPast, isTrue);
    });

    test('startOfDay sets time to midnight', () {
      final d = DateTime(2024, 6, 15, 14, 30, 45);
      expect(d.startOfDay, equals(DateTime(2024, 6, 15)));
    });

    test('isoDate formats correctly', () {
      expect(DateTime(2024, 1, 5).isoDate, equals('2024-01-05'));
      expect(DateTime(2024, 12, 31).isoDate, equals('2024-12-31'));
    });

    group('relative', () {
      test('returns "just now" for recent times', () {
        expect(DateTime.now().subtract(const Duration(seconds: 30)).relative,
            equals('just now'));
      });

      test('returns minutes ago', () {
        expect(
          DateTime.now().subtract(const Duration(minutes: 5)).relative,
          equals('5 minutes ago'),
        );
      });

      test('returns singular for 1 minute', () {
        expect(
          DateTime.now().subtract(const Duration(minutes: 1)).relative,
          equals('1 minute ago'),
        );
      });

      test('returns hours ago', () {
        expect(
          DateTime.now().subtract(const Duration(hours: 3)).relative,
          equals('3 hours ago'),
        );
      });

      test('returns future relative', () {
        final future = DateTime.now().add(const Duration(days: 2));
        expect(future.relative, equals('in 2 days'));
      });
    });
  });

  // ─── List Extensions ──────────────────────────────────────────────────────
  group('PrimekitListExtensions', () {
    test('elementAtOrNull returns element in bounds', () {
      expect([1, 2, 3].elementAtOrNull(1), equals(2));
    });

    test('elementAtOrNull returns null out of bounds', () {
      expect([1, 2, 3].elementAtOrNull(10), isNull);
      expect([1, 2, 3].elementAtOrNull(-1), isNull);
    });

    test('unique removes duplicates preserving order', () {
      expect([1, 2, 2, 3, 1].unique, equals([1, 2, 3]));
    });

    test('groupBy groups correctly', () {
      final result = [1, 2, 3, 4, 5].groupBy((n) => n.isEven ? 'even' : 'odd');
      expect(result['even'], equals([2, 4]));
      expect(result['odd'], equals([1, 3, 5]));
    });

    test('chunked splits into correct sizes', () {
      expect([1, 2, 3, 4, 5].chunked(2), equals([[1, 2], [3, 4], [5]]));
    });

    test('firstWhereOrNull returns match', () {
      expect([1, 2, 3].firstWhereOrNull((n) => n > 1), equals(2));
    });

    test('firstWhereOrNull returns null when not found', () {
      expect([1, 2, 3].firstWhereOrNull((n) => n > 10), isNull);
    });

    test('insertedAt inserts at index', () {
      expect([1, 2, 3].insertedAt(1, 99), equals([1, 99, 2, 3]));
    });

    test('replacedAt replaces at index', () {
      expect([1, 2, 3].replacedAt(1, 99), equals([1, 99, 3]));
    });

    test('removedAt removes at index', () {
      expect([1, 2, 3].removedAt(1), equals([1, 3]));
    });
  });

  // ─── Map Extensions ───────────────────────────────────────────────────────
  group('PrimekitMapExtensions', () {
    test('getOrDefault returns value', () {
      expect({'a': 1}.getOrDefault('a', 0), equals(1));
    });

    test('getOrDefault returns fallback', () {
      expect({'a': 1}.getOrDefault('b', 0), equals(0));
    });

    test('mapValues transforms values', () {
      expect({'a': 1, 'b': 2}.mapValues((v) => v * 2), equals({'a': 2, 'b': 4}));
    });

    test('mergedWith gives other precedence', () {
      expect({'a': 1, 'b': 2}.mergedWith({'b': 99, 'c': 3}),
          equals({'a': 1, 'b': 99, 'c': 3}));
    });

    test('whereEntries filters correctly', () {
      final result = {'a': 1, 'b': 2, 'c': 3}
          .whereEntries((e) => e.value > 1);
      expect(result, equals({'b': 2, 'c': 3}));
    });
  });
}
