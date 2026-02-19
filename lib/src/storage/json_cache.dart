import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// A TTL-based JSON cache backed by [SharedPreferences].
///
/// Entries are stored as JSON strings with an embedded `expiresAt` field.
/// Reading an expired entry returns `null` and lazily removes the stored data.
/// When no TTL is supplied the entry never expires.
///
/// ```dart
/// final cache = JsonCache.instance;
///
/// await cache.set(
///   'user_profile',
///   {'name': 'Alice', 'age': 30},
///   ttl: Duration(minutes: 15),
/// );
///
/// final profile = await cache.get('user_profile'); // null after 15 min
/// ```
final class JsonCache {
  JsonCache._internal();

  static final JsonCache _instance = JsonCache._internal();

  /// The singleton instance.
  static JsonCache get instance => _instance;

  static const String _prefix = 'pk_json_cache::';
  static const String _fieldData = 'data';
  static const String _fieldExpiresAt = 'expiresAt';

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Stores [data] under [key] with an optional [ttl].
  ///
  /// When [ttl] is `null` the entry never expires.
  ///
  /// Throws [StorageException] on failure.
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration? ttl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiresAt = ttl != null
          ? DateTime.now().toUtc().add(ttl).toIso8601String()
          : null;

      final envelope = jsonEncode({
        _fieldData: data,
        _fieldExpiresAt: expiresAt,
      });

      await prefs.setString('$_prefix$key', envelope);
      PrimekitLogger.verbose(
        'Cached "$key" (expires: ${expiresAt ?? 'never'})',
        tag: 'JsonCache',
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to cache "$key"',
        tag: 'JsonCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to write cache entry for key "$key"',
        code: 'JSON_CACHE_WRITE_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the cached data for [key], or `null` if not found or expired.
  ///
  /// Expired entries are lazily removed from storage.
  ///
  /// Throws [StorageException] on storage failure.
  Future<Map<String, dynamic>?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;

      final envelope = _decodeEnvelope(raw, key);
      if (envelope == null) {
        await prefs.remove('$_prefix$key');
        return null;
      }

      if (_isExpired(envelope[_fieldExpiresAt] as String?)) {
        PrimekitLogger.debug(
          'Cache miss (expired) for key "$key"',
          tag: 'JsonCache',
        );
        // Lazy eviction.
        unawaited(prefs.remove('$_prefix$key'));
        return null;
      }

      final data = envelope[_fieldData];
      if (data is! Map<String, dynamic>) {
        PrimekitLogger.warning(
          'Cache entry for "$key" has unexpected data type; evicting',
          tag: 'JsonCache',
        );
        unawaited(prefs.remove('$_prefix$key'));
        return null;
      }

      PrimekitLogger.verbose('Cache hit for "$key"', tag: 'JsonCache');
      return data;
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to read cache entry "$key"',
        tag: 'JsonCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to read cache entry for key "$key"',
        code: 'JSON_CACHE_READ_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Existence check
  // ---------------------------------------------------------------------------

  /// Returns `true` if a non-expired entry exists for [key].
  Future<bool> has(String key) async {
    final value = await get(key);
    return value != null;
  }

  // ---------------------------------------------------------------------------
  // Invalidation
  // ---------------------------------------------------------------------------

  /// Removes the entry for [key].
  ///
  /// Throws [StorageException] on failure.
  Future<void> invalidate(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
      PrimekitLogger.debug('Invalidated cache key "$key"', tag: 'JsonCache');
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to invalidate "$key"',
        tag: 'JsonCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to invalidate cache key "$key"',
        code: 'JSON_CACHE_INVALIDATE_FAILED',
        cause: e,
      );
    }
  }

  /// Removes all cache entries managed by [JsonCache].
  ///
  /// Does not affect keys from other [SharedPreferences] consumers.
  ///
  /// Throws [StorageException] on failure.
  Future<void> invalidateAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs
          .getKeys()
          .where((k) => k.startsWith(_prefix))
          .toList(growable: false);

      await Future.wait(cacheKeys.map(prefs.remove));
      PrimekitLogger.debug(
        'Invalidated ${cacheKeys.length} cache entries',
        tag: 'JsonCache',
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to invalidate all cache entries',
        tag: 'JsonCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to invalidate all cache entries',
        code: 'JSON_CACHE_INVALIDATE_ALL_FAILED',
        cause: e,
      );
    }
  }

  /// Removes all cache entries whose keys begin with [prefix].
  ///
  /// Useful for invalidating all entries related to a specific domain, e.g.
  /// `await cache.invalidateByPrefix('user_')`.
  ///
  /// Throws [StorageException] on failure.
  Future<void> invalidateByPrefix(String prefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachePrefix = '$_prefix$prefix';
      final matchingKeys = prefs
          .getKeys()
          .where((k) => k.startsWith(cachePrefix))
          .toList(growable: false);

      await Future.wait(matchingKeys.map(prefs.remove));
      PrimekitLogger.debug(
        'Invalidated ${matchingKeys.length} entries with prefix "$prefix"',
        tag: 'JsonCache',
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to invalidate by prefix "$prefix"',
        tag: 'JsonCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to invalidate cache entries with prefix "$prefix"',
        code: 'JSON_CACHE_PREFIX_INVALIDATE_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _decodeEnvelope(String raw, String key) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on Exception catch (e) {
      PrimekitLogger.warning(
        'Malformed cache envelope for key "$key"',
        tag: 'JsonCache',
        error: e,
      );
      return null;
    }
  }

  bool _isExpired(String? expiresAtIso) {
    if (expiresAtIso == null) return false;
    final expiresAt = DateTime.tryParse(expiresAtIso);
    if (expiresAt == null) return true;
    return DateTime.now().toUtc().isAfter(expiresAt);
  }
}

// Suppress lint for intentional fire-and-forget calls.
void unawaited(Future<dynamic> future) {}
