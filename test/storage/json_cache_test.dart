import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/storage/json_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late JsonCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = JsonCache.instance;
  });

  tearDown(() async {
    await cache.invalidateAll();
  });

  // ---------------------------------------------------------------------------
  // set / get
  // ---------------------------------------------------------------------------

  group('set and get', () {
    test('stores and retrieves a simple map', () async {
      await cache.set('key1', {'value': 42});
      final result = await cache.get('key1');
      expect(result, {'value': 42});
    });

    test('returns null for a missing key', () async {
      final result = await cache.get('nonexistent');
      expect(result, isNull);
    });

    test('stores without TTL and returns indefinitely', () async {
      await cache.set('permanent', {'data': 'test'});
      final result = await cache.get('permanent');
      expect(result, isNotNull);
    });

    test('nested map is preserved', () async {
      final data = {
        'user': {'name': 'Alice', 'age': 30},
        'tags': ['flutter', 'dart'],
      };
      await cache.set('nested', data as Map<String, dynamic>);
      final result = await cache.get('nested');
      expect(result, isNotNull);
      expect((result!['user'] as Map)['name'], 'Alice');
    });

    test('overwriting a key replaces the data', () async {
      await cache.set('overwrite', {'v': 1});
      await cache.set('overwrite', {'v': 2});
      final result = await cache.get('overwrite');
      expect(result!['v'], 2);
    });
  });

  // ---------------------------------------------------------------------------
  // TTL
  // ---------------------------------------------------------------------------

  group('TTL expiry', () {
    test('returns null after TTL expires', () async {
      await cache.set('short', {'x': 1}, ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final result = await cache.get('short');
      expect(result, isNull);
    });

    test('returns data before TTL expires', () async {
      await cache.set('long', {'x': 1}, ttl: const Duration(hours: 1));
      final result = await cache.get('long');
      expect(result, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // has
  // ---------------------------------------------------------------------------

  group('has', () {
    test('returns true for a valid entry', () async {
      await cache.set('exists', {'k': 'v'});
      expect(await cache.has('exists'), isTrue);
    });

    test('returns false for missing key', () async {
      expect(await cache.has('missing'), isFalse);
    });

    test('returns false for expired entry', () async {
      await cache.set('expired', {'k': 'v'}, ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await cache.has('expired'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // invalidate
  // ---------------------------------------------------------------------------

  group('invalidate', () {
    test('removes a single entry', () async {
      await cache.set('a', {'n': 1});
      await cache.set('b', {'n': 2});
      await cache.invalidate('a');
      expect(await cache.has('a'), isFalse);
      expect(await cache.has('b'), isTrue);
    });

    test('no-op when key does not exist', () async {
      await expectLater(cache.invalidate('ghost'), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // invalidateAll
  // ---------------------------------------------------------------------------

  group('invalidateAll', () {
    test('removes all cache entries', () async {
      await cache.set('x', {'n': 1});
      await cache.set('y', {'n': 2});
      await cache.invalidateAll();
      expect(await cache.has('x'), isFalse);
      expect(await cache.has('y'), isFalse);
    });

    test('does not throw when cache is empty', () async {
      await expectLater(cache.invalidateAll(), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // invalidateByPrefix
  // ---------------------------------------------------------------------------

  group('invalidateByPrefix', () {
    test('removes entries matching prefix', () async {
      await cache.set('user_1', {'n': 1});
      await cache.set('user_2', {'n': 2});
      await cache.set('order_1', {'n': 3});
      await cache.invalidateByPrefix('user_');
      expect(await cache.has('user_1'), isFalse);
      expect(await cache.has('user_2'), isFalse);
      expect(await cache.has('order_1'), isTrue);
    });

    test('no-op when no entries match prefix', () async {
      await cache.set('unrelated', {'n': 1});
      await expectLater(cache.invalidateByPrefix('zz_'), completes);
      expect(await cache.has('unrelated'), isTrue);
    });
  });
}
