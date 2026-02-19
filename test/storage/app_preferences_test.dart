import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferences.instance;
  });

  tearDown(() async {
    await prefs.clearAll();
  });

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  group('theme mode', () {
    test('defaults to ThemeMode.system when not set', () async {
      expect(await prefs.getThemeMode(), ThemeMode.system);
    });

    test('stores and retrieves ThemeMode.dark', () async {
      await prefs.setThemeMode(ThemeMode.dark);
      expect(await prefs.getThemeMode(), ThemeMode.dark);
    });

    test('stores and retrieves ThemeMode.light', () async {
      await prefs.setThemeMode(ThemeMode.light);
      expect(await prefs.getThemeMode(), ThemeMode.light);
    });

    test('stores and retrieves ThemeMode.system', () async {
      await prefs.setThemeMode(ThemeMode.dark);
      await prefs.setThemeMode(ThemeMode.system);
      expect(await prefs.getThemeMode(), ThemeMode.system);
    });
  });

  // ---------------------------------------------------------------------------
  // Locale
  // ---------------------------------------------------------------------------

  group('locale', () {
    test('returns null when not set', () async {
      expect(await prefs.getLocale(), isNull);
    });

    test('stores and retrieves language code', () async {
      await prefs.setLocale('fr');
      expect(await prefs.getLocale(), 'fr');
    });

    test('overwrites previous locale', () async {
      await prefs.setLocale('en');
      await prefs.setLocale('de');
      expect(await prefs.getLocale(), 'de');
    });
  });

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  group('onboarding', () {
    test('isOnboardingComplete returns false by default', () async {
      expect(await prefs.isOnboardingComplete(), isFalse);
    });

    test('sets onboarding complete to true', () async {
      await prefs.setOnboardingComplete(true);
      expect(await prefs.isOnboardingComplete(), isTrue);
    });

    test('sets onboarding complete back to false', () async {
      await prefs.setOnboardingComplete(true);
      await prefs.setOnboardingComplete(false);
      expect(await prefs.isOnboardingComplete(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Generic set / get
  // ---------------------------------------------------------------------------

  group('generic set/get', () {
    test('String round-trip', () async {
      await prefs.set<String>('str_key', 'hello');
      expect(await prefs.get<String>('str_key'), 'hello');
    });

    test('bool round-trip (true)', () async {
      await prefs.set<bool>('bool_key', true);
      expect(await prefs.get<bool>('bool_key'), isTrue);
    });

    test('bool round-trip (false)', () async {
      await prefs.set<bool>('bool_key', false);
      expect(await prefs.get<bool>('bool_key'), isFalse);
    });

    test('int round-trip', () async {
      await prefs.set<int>('int_key', 42);
      expect(await prefs.get<int>('int_key'), 42);
    });

    test('double round-trip', () async {
      await prefs.set<double>('dbl_key', 3.14);
      expect(await prefs.get<double>('dbl_key'), 3.14);
    });

    test('Map<String, dynamic> round-trip', () async {
      final data = {'name': 'Bob', 'score': 100};
      await prefs.set<Map<String, dynamic>>('map_key', data);
      final result = await prefs.get<Map<String, dynamic>>('map_key');
      expect(result, data);
    });

    test('returns null for missing key', () async {
      expect(await prefs.get<String>('absent'), isNull);
    });

    test('unsupported type throws ArgumentError on set', () async {
      await expectLater(
        () => prefs.set<List<int>>('bad', <int>[1, 2, 3]),
        throwsArgumentError,
      );
    });

    test('unsupported type throws ArgumentError on get', () async {
      await expectLater(
        () => prefs.get<List<int>>('bad'),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // remove / clearAll
  // ---------------------------------------------------------------------------

  group('remove and clearAll', () {
    test('remove deletes a custom key', () async {
      await prefs.set<String>('to_remove', 'value');
      await prefs.remove('to_remove');
      expect(await prefs.get<String>('to_remove'), isNull);
    });

    test('clearAll removes all primekit entries', () async {
      await prefs.setThemeMode(ThemeMode.dark);
      await prefs.setLocale('ja');
      await prefs.set<int>('x', 5);
      await prefs.clearAll();

      expect(await prefs.getThemeMode(), ThemeMode.system);
      expect(await prefs.getLocale(), isNull);
      expect(await prefs.get<int>('x'), isNull);
    });
  });
}
