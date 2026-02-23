import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/ads/ad_unit_config.dart';

void main() {
  group('AdUnitConfig', () {
    const config = AdUnitConfig(
      bannerId: 'banner-1',
      interstitialId: 'inter-1',
      rewardedId: 'reward-1',
    );

    test('constructor sets required fields', () {
      expect(config.bannerId, equals('banner-1'));
      expect(config.interstitialId, equals('inter-1'));
      expect(config.rewardedId, equals('reward-1'));
    });

    test('optional fields default to null', () {
      expect(config.nativeId, isNull);
      expect(config.appOpenId, isNull);
    });

    test('optional fields can be set', () {
      const full = AdUnitConfig(
        bannerId: 'b',
        interstitialId: 'i',
        rewardedId: 'r',
        nativeId: 'n',
        appOpenId: 'a',
      );
      expect(full.nativeId, equals('n'));
      expect(full.appOpenId, equals('a'));
    });

    test('copyWith replaces only specified fields', () {
      final copy = config.copyWith(bannerId: 'banner-2');
      expect(copy.bannerId, equals('banner-2'));
      expect(copy.interstitialId, equals('inter-1')); // unchanged
      expect(copy.rewardedId, equals('reward-1')); // unchanged
    });

    test('copyWith with no args returns equivalent config', () {
      final copy = config.copyWith();
      expect(copy.bannerId, equals(config.bannerId));
      expect(copy.interstitialId, equals(config.interstitialId));
      expect(copy.rewardedId, equals(config.rewardedId));
    });

    test('toString contains relevant ids', () {
      expect(config.toString(), contains('banner-1'));
      expect(config.toString(), contains('inter-1'));
    });

    group('testIds()', () {
      test('returns non-empty IDs', () {
        // testIds() is platform-aware; it should not throw in test env.
        try {
          final testConfig = AdUnitConfig.testIds();
          expect(testConfig.bannerId, isNotEmpty);
          expect(testConfig.interstitialId, isNotEmpty);
          expect(testConfig.rewardedId, isNotEmpty);
        } on UnsupportedError {
          // Acceptable when running on a non-mobile platform in CI.
          markTestSkipped('AdUnitConfig.testIds() requires iOS or Android.');
        }
      });
    });

    group('forPlatform()', () {
      const iosConfig = AdUnitConfig(
        bannerId: 'ios-banner',
        interstitialId: 'ios-inter',
        rewardedId: 'ios-reward',
      );
      const androidConfig = AdUnitConfig(
        bannerId: 'and-banner',
        interstitialId: 'and-inter',
        rewardedId: 'and-reward',
      );

      test(
        'returns the platform-appropriate config or throws on non-mobile',
        () {
          try {
            final selected = AdUnitConfig.forPlatform(
              ios: iosConfig,
              android: androidConfig,
            );
            expect([
              iosConfig.bannerId,
              androidConfig.bannerId,
            ], contains(selected.bannerId));
          } on UnsupportedError {
            markTestSkipped('forPlatform() requires iOS or Android.');
          }
        },
      );
    });
  });
}
