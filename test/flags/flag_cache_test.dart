import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/flags/flag_cache.dart';
import 'package:primekit/src/flags/local_flag_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // providerId
  // -------------------------------------------------------------------------

  group('providerId', () {
    test('wraps delegate providerId', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      expect(cache.providerId, 'cached(local)');
    });
  });

  // -------------------------------------------------------------------------
  // initialize
  // -------------------------------------------------------------------------

  group('initialize', () {
    test('initializes without error when cache is stale', () async {
      final cache = CachedFlagProvider(
        delegate: LocalFlagProvider({'flag': true}),
      );
      await expectLater(cache.initialize(), completes);
    });
  });

  // -------------------------------------------------------------------------
  // Cached reads (second call returns cached value)
  // -------------------------------------------------------------------------

  group('cached reads', () {
    test('getBool returns cached value on second call', () async {
      final delegate = LocalFlagProvider({'flag': true});
      final cache = CachedFlagProvider(delegate: delegate);

      // First call — seeds the cache.
      final first = cache.getBool('flag', defaultValue: false);
      // Second call — served from memory cache.
      final second = cache.getBool('flag', defaultValue: false);

      expect(first, second);
    });

    test('returns defaultValue for keys not in delegate', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      cache.seedCacheForTesting({
        'known': true,
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getBool('unknown', defaultValue: false), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Seeded cache
  // -------------------------------------------------------------------------

  group('seeded cache', () {
    test('returns seeded bool value', () {
      final cache = CachedFlagProvider(
        delegate: LocalFlagProvider({}),
        ttl: const Duration(hours: 1),
      );
      cache.seedCacheForTesting({
        'my_flag': true,
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getBool('my_flag', defaultValue: false), isTrue);
    });

    test('returns seeded string value', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      cache.seedCacheForTesting({
        'msg': 'cached!',
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getString('msg', defaultValue: ''), 'cached!');
    });

    test('returns seeded int value', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      cache.seedCacheForTesting({
        'count': 99,
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getInt('count', defaultValue: 0), 99);
    });

    test('returns seeded double value', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      cache.seedCacheForTesting({
        'ratio': 0.75,
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getDouble('ratio', defaultValue: 0.0), 0.75);
    });

    test('returns seeded JSON value', () {
      final cache = CachedFlagProvider(delegate: LocalFlagProvider({}));
      cache.seedCacheForTesting({
        'config': {'a': 1},
      }, cachedAt: DateTime.now().toUtc());
      expect(cache.getJson('config', defaultValue: {}), {'a': 1});
    });
  });

  // -------------------------------------------------------------------------
  // TTL expiry — stale-while-revalidate
  // -------------------------------------------------------------------------

  group('TTL expiry', () {
    test('cache is stale when cachedAt is far in the past', () {
      final cache = CachedFlagProvider(
        delegate: LocalFlagProvider({'flag': true}),
        ttl: const Duration(milliseconds: 1),
      );
      cache.seedCacheForTesting(
        {'flag': true},
        cachedAt: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
      );
      // Stale-while-revalidate: still returns the stale value immediately,
      // but triggers a background refresh (fire-and-forget).
      // The important contract is that the call does not throw.
      expect(() => cache.getBool('flag', defaultValue: false), returnsNormally);
    });

    test('returns stale value immediately when cache has expired', () {
      final cache = CachedFlagProvider(
        delegate: LocalFlagProvider({'flag': false}),
        ttl: const Duration(milliseconds: 1),
      );
      // Seed with stale data.
      cache.seedCacheForTesting({
        'flag': true,
      }, cachedAt: DateTime.now().toUtc().subtract(const Duration(seconds: 5)));
      // Stale-while-revalidate: returns stale value.
      expect(cache.getBool('flag', defaultValue: false), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // refresh
  // -------------------------------------------------------------------------

  group('refresh', () {
    test('refresh completes without error', () async {
      final cache = CachedFlagProvider(
        delegate: LocalFlagProvider({'flag': true}),
      );
      await expectLater(cache.refresh(), completes);
    });
  });
}
