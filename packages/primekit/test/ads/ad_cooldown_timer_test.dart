import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/ads/ad_cooldown_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdCooldownTimer', () {
    test('canShowAd is true when never shown', () {
      final timer = AdCooldownTimer(cooldown: const Duration(minutes: 3));
      expect(timer.canShowAd, isTrue);
    });

    test('timeUntilNextAd is null when canShowAd is true', () {
      final timer = AdCooldownTimer();
      expect(timer.timeUntilNextAd, isNull);
    });

    test('canShowAd is false immediately after recordAdShown', () async {
      final timer = AdCooldownTimer(cooldown: const Duration(hours: 1));
      await timer.recordAdShown();
      expect(timer.canShowAd, isFalse);
    });

    test('timeUntilNextAd is non-null after recording', () async {
      final timer = AdCooldownTimer(cooldown: const Duration(hours: 1));
      await timer.recordAdShown();
      expect(timer.timeUntilNextAd, isNotNull);
      expect(timer.timeUntilNextAd!.inMinutes, greaterThan(0));
    });

    test('canShowAd is true with a zero cooldown', () async {
      final timer = AdCooldownTimer(cooldown: Duration.zero);
      await timer.recordAdShown();
      // After 0ms cooldown the time has already passed.
      expect(timer.canShowAd, isTrue);
    });

    test('persists last-shown timestamp to SharedPreferences', () async {
      final timer = AdCooldownTimer(cooldown: const Duration(hours: 1));
      await timer.recordAdShown();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('primekit_ad_last_shown'), isNotNull);
    });

    test('load restores persisted timestamp', () async {
      // Pre-populate with a recent timestamp (within cooldown).
      final recentTime = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );
      SharedPreferences.setMockInitialValues({
        'primekit_ad_last_shown': recentTime.toIso8601String(),
      });

      final timer = AdCooldownTimer(cooldown: const Duration(minutes: 3));
      await timer.load();

      expect(timer.canShowAd, isFalse);
    });

    test('load: cooldown expired means canShowAd is true', () async {
      final oldTime = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        'primekit_ad_last_shown': oldTime.toIso8601String(),
      });

      final timer = AdCooldownTimer(cooldown: const Duration(minutes: 3));
      await timer.load();

      expect(timer.canShowAd, isTrue);
    });

    test('resetForTesting clears state', () async {
      final timer = AdCooldownTimer(cooldown: const Duration(hours: 1));
      await timer.recordAdShown();
      expect(timer.canShowAd, isFalse);

      await timer.resetForTesting();

      expect(timer.canShowAd, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('primekit_ad_last_shown'), isNull);
    });
  });
}
