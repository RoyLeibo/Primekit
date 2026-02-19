import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/ads/ad_event_logger.dart';

void main() {
  setUp(() => AdEventLogger.instance.resetCounters());

  group('AdEvent factories', () {
    test('AdEvent.loaded creates AdLoaded with correct adType', () {
      final event = AdEvent.loaded('banner');
      expect(event, isA<AdLoaded>());
      expect(event.adType, equals('banner'));
    });

    test('AdEvent.shown creates AdShown with screenName', () {
      final event = AdEvent.shown('interstitial', screenName: 'HomeScreen');
      expect(event, isA<AdShown>());
      expect((event as AdShown).screenName, equals('HomeScreen'));
    });

    test('AdEvent.shown without screenName has null screenName', () {
      final event = AdEvent.shown('banner');
      expect((event as AdShown).screenName, isNull);
    });

    test('AdEvent.clicked creates AdClicked', () {
      final event = AdEvent.clicked('rewarded');
      expect(event, isA<AdClicked>());
      expect(event.adType, equals('rewarded'));
    });

    test('AdEvent.closed creates AdClosed', () {
      final event = AdEvent.closed('interstitial');
      expect(event, isA<AdClosed>());
    });

    test('AdEvent.failed creates AdFailed with error', () {
      final event = AdEvent.failed('banner', error: 'no fill');
      expect(event, isA<AdFailed>());
      expect((event as AdFailed).error, equals('no fill'));
    });

    test('AdEvent.rewarded creates AdRewarded', () {
      final event = AdEvent.rewarded(rewardType: 'coins', amount: 50);
      expect(event, isA<AdRewarded>());
      expect((event as AdRewarded).rewardType, equals('coins'));
      expect(event.amount, equals(50));
      expect(event.adType, equals('rewarded'));
    });

    test('toString includes adType', () {
      final event = AdEvent.loaded('banner');
      expect(event.toString(), contains('banner'));
    });
  });

  group('AdEventLogger', () {
    test('instance is singleton', () {
      expect(
        identical(AdEventLogger.instance, AdEventLogger.instance),
        isTrue,
      );
    });

    test('impressionsByType starts empty', () {
      expect(AdEventLogger.instance.impressionsByType, isEmpty);
    });

    test('clicksByType starts empty', () {
      expect(AdEventLogger.instance.clicksByType, isEmpty);
    });

    test('log(AdShown) increments impressionsByType', () {
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      AdEventLogger.instance.log(AdEvent.shown('interstitial'));

      expect(AdEventLogger.instance.impressionsByType['banner'], equals(2));
      expect(
        AdEventLogger.instance.impressionsByType['interstitial'],
        equals(1),
      );
    });

    test('log(AdClicked) increments clicksByType', () {
      AdEventLogger.instance.log(AdEvent.clicked('banner'));

      expect(AdEventLogger.instance.clicksByType['banner'], equals(1));
    });

    test('clickThroughRate is 0.0 with no impressions', () {
      expect(AdEventLogger.instance.clickThroughRate, equals(0.0));
    });

    test('clickThroughRate is 0.0 with impressions but no clicks', () {
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      expect(AdEventLogger.instance.clickThroughRate, equals(0.0));
    });

    test('clickThroughRate is 0.5 with 1 click in 2 impressions', () {
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      AdEventLogger.instance.log(AdEvent.clicked('banner'));

      expect(AdEventLogger.instance.clickThroughRate, equals(0.5));
    });

    test('non-impression events do not affect impression count', () {
      AdEventLogger.instance.log(AdEvent.loaded('banner'));
      AdEventLogger.instance.log(AdEvent.closed('banner'));
      AdEventLogger.instance.log(AdEvent.failed('banner', error: 'err'));

      expect(AdEventLogger.instance.impressionsByType, isEmpty);
    });

    test('resetCounters clears all state', () {
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      AdEventLogger.instance.log(AdEvent.clicked('banner'));

      AdEventLogger.instance.resetCounters();

      expect(AdEventLogger.instance.impressionsByType, isEmpty);
      expect(AdEventLogger.instance.clicksByType, isEmpty);
    });

    test('impressionsByType is unmodifiable', () {
      AdEventLogger.instance.log(AdEvent.shown('banner'));
      expect(
        () => AdEventLogger.instance.impressionsByType['banner'] = 99,
        throwsUnsupportedError,
      );
    });

    test('clicksByType is unmodifiable', () {
      AdEventLogger.instance.log(AdEvent.clicked('banner'));
      expect(
        () => AdEventLogger.instance.clicksByType['banner'] = 99,
        throwsUnsupportedError,
      );
    });
  });
}
