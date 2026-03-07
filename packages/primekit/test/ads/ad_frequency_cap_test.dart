import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/ads/ad_frequency_cap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdFrequencyCap', () {
    test('canShow is true when no impressions recorded', () {
      final cap = AdFrequencyCap(maxPerSession: 5, maxPerDay: 20);
      expect(cap.canShow, isTrue);
    });

    test('canShow is false when session limit reached', () async {
      final cap = AdFrequencyCap(maxPerSession: 2, maxPerDay: 100);
      await cap.recordImpression();
      await cap.recordImpression();
      expect(cap.canShow, isFalse);
    });

    test('canShow is false when day limit reached', () async {
      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 2);
      await cap.recordImpression();
      await cap.recordImpression();
      expect(cap.canShow, isFalse);
    });

    test('sessionImpressions increments on recordImpression', () async {
      final cap = AdFrequencyCap(maxPerSession: 10, maxPerDay: 100);
      await cap.recordImpression();
      await cap.recordImpression();
      expect(cap.sessionImpressions, equals(2));
    });

    test('todayImpressions increments on recordImpression', () async {
      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 50);
      await cap.recordImpression();
      expect(cap.todayImpressions, equals(1));
    });

    test('resetSession resets sessionImpressions to 0', () async {
      final cap = AdFrequencyCap(maxPerSession: 2, maxPerDay: 100);
      await cap.recordImpression();
      await cap.recordImpression();
      expect(cap.canShow, isFalse);

      cap.resetSession();

      expect(cap.sessionImpressions, equals(0));
      expect(cap.canShow, isTrue);
    });

    test('resetSession does not reset todayImpressions', () async {
      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 50);
      await cap.recordImpression();
      cap.resetSession();
      expect(cap.todayImpressions, equals(1));
    });

    test('maxPerSession is clamped to minimum of 1', () {
      final cap = AdFrequencyCap(maxPerSession: 0, maxPerDay: 10);
      // canShow should be false immediately since 0 impressions >= 1
      // (clamped to 1, and 0 < 1 so it IS allowed initially)
      // The clamp ensures we never get negative or zero max
      expect(cap.canShow, isTrue);
    });

    test('persists todayImpressions to SharedPreferences', () async {
      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 100);
      await cap.recordImpression();
      await cap.recordImpression();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('primekit_ad_freq_today');
      expect(stored, equals(2));
    });

    test('load restores todayImpressions from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'primekit_ad_freq_today': 7,
        'primekit_ad_freq_date': DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ).toIso8601String(),
      });

      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 100);
      await cap.load();
      expect(cap.todayImpressions, equals(7));
    });

    test('load resets count when stored date is a past day', () async {
      SharedPreferences.setMockInitialValues({
        'primekit_ad_freq_today': 15,
        'primekit_ad_freq_date': DateTime(2000, 1, 1).toIso8601String(),
      });

      final cap = AdFrequencyCap(maxPerSession: 100, maxPerDay: 100);
      await cap.load();
      expect(cap.todayImpressions, equals(0));
    });

    test('resetForTesting clears all state', () async {
      final cap = AdFrequencyCap(maxPerSession: 2, maxPerDay: 5);
      await cap.recordImpression();
      await cap.recordImpression();
      expect(cap.canShow, isFalse);

      await cap.resetForTesting();
      expect(cap.canShow, isTrue);
      expect(cap.sessionImpressions, equals(0));
      expect(cap.todayImpressions, equals(0));
    });
  });
}
