import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/flags/feature_flag.dart';
import 'package:primekit/src/flags/flag_service.dart';
import 'package:primekit/src/flags/local_flag_provider.dart';

void main() {
  late FlagService service;

  const darkMode = BoolFlag(key: 'dark_mode', defaultValue: false);
  const maxItems = IntFlag(key: 'max_items', defaultValue: 10);
  const greeting = StringFlag(key: 'greeting', defaultValue: 'Hello');
  const threshold = DoubleFlag(key: 'threshold', defaultValue: 0.5);

  setUp(() {
    service = FlagService.instance;
    service.resetForTesting();
  });

  tearDown(() {
    service.resetForTesting();
  });

  // -------------------------------------------------------------------------
  // Configuration
  // -------------------------------------------------------------------------

  group('configure', () {
    test('configure without calling get does not throw', () {
      service.configure(LocalFlagProvider({'dark_mode': true}));
    });

    test('get throws ConfigurationException when not configured', () {
      expect(() => service.get<bool>(darkMode), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  // get
  // -------------------------------------------------------------------------

  group('get', () {
    setUp(() {
      service.configure(
        LocalFlagProvider({
          'dark_mode': true,
          'max_items': 50,
          'greeting': 'Hi',
          'threshold': 0.8,
        }),
      );
    });

    test('returns provider value for existing key', () {
      expect(service.get<bool>(darkMode), isTrue);
    });

    test('uses default when key not found in provider', () {
      const missing = BoolFlag(key: 'missing_flag', defaultValue: false);
      expect(service.get<bool>(missing), isFalse);
    });

    test('returns correct int value', () {
      expect(service.get<int>(maxItems), 50);
    });

    test('returns correct string value', () {
      expect(service.get<String>(greeting), 'Hi');
    });

    test('returns default string when key missing', () {
      const missing = StringFlag(key: 'no_such_key', defaultValue: 'Default');
      expect(service.get<String>(missing), 'Default');
    });
  });

  // -------------------------------------------------------------------------
  // isEnabled
  // -------------------------------------------------------------------------

  group('isEnabled', () {
    test('returns true when flag value is true', () {
      service.configure(LocalFlagProvider({'dark_mode': true}));
      expect(service.isEnabled(darkMode), isTrue);
    });

    test('returns false when flag value is false', () {
      service.configure(LocalFlagProvider({'dark_mode': false}));
      expect(service.isEnabled(darkMode), isFalse);
    });

    test('returns default (false) when key not in provider', () {
      service.configure(LocalFlagProvider({}));
      expect(service.isEnabled(darkMode), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // setOverride / clearOverride
  // -------------------------------------------------------------------------

  group('setOverride', () {
    setUp(() {
      service.configure(LocalFlagProvider({'dark_mode': false}));
    });

    test('override takes precedence over provider', () {
      service.setOverride(darkMode, true);
      expect(service.get<bool>(darkMode), isTrue);
    });

    test('clearOverride falls back to provider value', () {
      service.setOverride(darkMode, true);
      service.clearOverride(darkMode);
      expect(service.get<bool>(darkMode), isFalse);
    });

    test('clearAllOverrides removes all overrides', () {
      service.configure(
        LocalFlagProvider({'dark_mode': false, 'max_items': 10}),
      );
      service.setOverride(darkMode, true);
      service.setOverride(maxItems, 99);
      service.clearAllOverrides();
      expect(service.get<bool>(darkMode), isFalse);
      expect(service.get<int>(maxItems), 10);
    });

    test('override for non-existent key returns override value', () {
      const newFlag = IntFlag(key: 'new_key', defaultValue: 0);
      service.setOverride(newFlag, 777);
      expect(service.get<int>(newFlag), 777);
    });

    test('isEnabled respects override', () {
      service.setOverride(darkMode, true);
      expect(service.isEnabled(darkMode), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // refresh
  // -------------------------------------------------------------------------

  group('refresh', () {
    test('refresh completes without error', () async {
      service.configure(LocalFlagProvider({'dark_mode': true}));
      await expectLater(service.refresh(), completes);
    });
  });

  // -------------------------------------------------------------------------
  // lastFetchedAt
  // -------------------------------------------------------------------------

  group('lastFetchedAt', () {
    test('returns null for LocalFlagProvider', () {
      service.configure(LocalFlagProvider({}));
      expect(service.lastFetchedAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // abVariant
  // -------------------------------------------------------------------------

  group('abVariant', () {
    setUp(() {
      service.configure(LocalFlagProvider({}));
    });

    test('same userId always gets the same variant', () {
      const variants = ['control', 'v1', 'v2'];
      final first = service.abVariant(
        experimentKey: 'test_exp',
        userId: 'user_abc',
        variants: variants,
      );
      final second = service.abVariant(
        experimentKey: 'test_exp',
        userId: 'user_abc',
        variants: variants,
      );
      expect(first, second);
    });

    test('different user IDs can get different variants', () {
      const variants = ['control', 'treatment'];
      final results = <String>{};
      for (var i = 0; i < 200; i++) {
        results.add(
          service.abVariant(
            experimentKey: 'exp',
            userId: 'user_$i',
            variants: variants,
          ),
        );
      }
      // With 200 users and 2 variants, expect both to appear.
      expect(results, containsAll(['control', 'treatment']));
    });

    test('distribution is roughly equal across large N', () {
      const variants = ['a', 'b'];
      final counts = {'a': 0, 'b': 0};
      const n = 10000;
      for (var i = 0; i < n; i++) {
        final v = service.abVariant(
          experimentKey: 'dist_exp',
          userId: 'u$i',
          variants: variants,
        );
        counts[v] = (counts[v] ?? 0) + 1;
      }
      // Expect each variant to appear between 40% and 60% of the time.
      expect(counts['a']!, greaterThan(n * 0.40));
      expect(counts['a']!, lessThan(n * 0.60));
      expect(counts['b']!, greaterThan(n * 0.40));
      expect(counts['b']!, lessThan(n * 0.60));
    });

    test('single variant always returns that variant', () {
      final variant = service.abVariant(
        experimentKey: 'single',
        userId: 'any_user',
        variants: ['only'],
      );
      expect(variant, 'only');
    });

    test('weighted distribution respects weights', () {
      const variants = ['a', 'b'];
      const weights = [0.9, 0.1];
      final counts = {'a': 0, 'b': 0};
      const n = 5000;
      for (var i = 0; i < n; i++) {
        final v = service.abVariant(
          experimentKey: 'weighted',
          userId: 'u$i',
          variants: variants,
          weights: weights,
        );
        counts[v] = (counts[v] ?? 0) + 1;
      }
      // 'a' should dominate with ~90%.
      expect(counts['a']!, greaterThan(n * 0.80));
      expect(counts['b']!, lessThan(n * 0.20));
    });
  });
}
