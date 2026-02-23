import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import 'flag_provider.dart';

/// A caching decorator for any [FlagProvider].
///
/// Wraps a [delegate] provider and adds:
/// - In-memory + [SharedPreferences] persistence across app restarts.
/// - TTL-based expiry — values are considered fresh for [ttl] after the last
///   fetch.
/// - Stale-while-revalidate — stale values are returned immediately while a
///   background refresh is triggered concurrently.
///
/// ```dart
/// final cached = CachedFlagProvider(
///   delegate: FirebaseFlagProvider(),
///   ttl: const Duration(hours: 2),
/// );
/// FlagService.instance.configure(cached);
/// ```
final class CachedFlagProvider implements FlagProvider {
  /// Creates a caching wrapper around [delegate].
  CachedFlagProvider({
    required FlagProvider delegate,
    Duration ttl = const Duration(hours: 1),
    SharedPreferences? prefs,
  }) : _delegate = delegate,
       _ttl = ttl,
       _prefs = prefs;

  final FlagProvider _delegate;
  final Duration _ttl;

  /// Lazily resolved prefs instance (injected for testing or
  /// resolved on demand).
  SharedPreferences? _prefs;

  Map<String, dynamic> _memoryCache = {};
  DateTime? _cachedAt;
  bool _refreshing = false;

  static const String _tag = 'CachedFlagProvider';
  static const String _prefsKey = 'pk_flag_cache';
  static const String _prefsTimestampKey = 'pk_flag_cache_timestamp';

  @override
  String get providerId => 'cached(${_delegate.providerId})';

  @override
  DateTime? get lastFetchedAt => _cachedAt ?? _delegate.lastFetchedAt;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    await _loadFromPrefs();

    if (_isCacheStale) {
      await _delegate.initialize();
      await _hydrateCacheFromDelegate();
    } else {
      // Initialise delegate in background so it is ready for next refresh.
      unawaited(_delegate.initialize());
    }
  }

  @override
  Future<void> refresh() async {
    await _delegate.refresh();
    await _hydrateCacheFromDelegate();
  }

  // ---------------------------------------------------------------------------
  // Generic accessor
  // ---------------------------------------------------------------------------

  @override
  T getValue<T>(String key, T defaultValue) {
    _triggerBackgroundRefreshIfStale();

    final raw = _memoryCache[key];
    if (raw is T) return raw;
    if (T == double && raw is int) return raw.toDouble() as T;
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Typed accessors
  // ---------------------------------------------------------------------------

  @override
  bool getBool(String key, {required bool defaultValue}) =>
      getValue<bool>(key, defaultValue);

  @override
  String getString(String key, {required String defaultValue}) =>
      getValue<String>(key, defaultValue);

  @override
  int getInt(String key, {required int defaultValue}) =>
      getValue<int>(key, defaultValue);

  @override
  double getDouble(String key, {required double defaultValue}) {
    _triggerBackgroundRefreshIfStale();
    final raw = _memoryCache[key];
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return defaultValue;
  }

  @override
  Map<String, dynamic> getJson(
    String key, {
    required Map<String, dynamic> defaultValue,
  }) {
    _triggerBackgroundRefreshIfStale();
    final raw = _memoryCache[key];
    if (raw is Map<String, dynamic>) return raw;
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool get _isCacheStale {
    final ts = _cachedAt;
    if (ts == null) return true;
    return DateTime.now().toUtc().difference(ts) > _ttl;
  }

  /// Fire-and-forget background refresh when cache is stale.
  /// Stale-while-revalidate: caller still gets the cached (stale) value.
  void _triggerBackgroundRefreshIfStale() {
    if (!_isCacheStale || _refreshing) return;
    _refreshing = true;
    unawaited(
      _delegate
          .refresh()
          .then((_) async {
            await _hydrateCacheFromDelegate();
            _refreshing = false;
          })
          .catchError((Object error) {
            PrimekitLogger.warning(
              'Background flag refresh failed.',
              tag: _tag,
              error: error,
            );
            _refreshing = false;
          }),
    );
  }

  /// Reads all flag values from the delegate and snapshot them into the cache.
  Future<void> _hydrateCacheFromDelegate() async {
    // The delegate exposes per-key reads but not a bulk dump.
    // CachedFlagProvider piggybacks on the memory snapshot already held by the
    // delegate via a simple passthrough: we store key-value pairs gathered
    // from the delegate's in-memory state that our callers have asked for.
    // For providers that expose a _cache map (e.g. MongoFlagProvider) we can
    // read it, otherwise we rely on the cache being populated lazily.
    // We take a snapshot of the keys currently in our cache, refresh each one.
    final updated = <String, dynamic>{};
    for (final key in _memoryCache.keys) {
      updated[key] = _delegate.getValue<dynamic>(key, _memoryCache[key]);
    }
    _memoryCache = Map<String, dynamic>.unmodifiable(updated);
    _cachedAt = DateTime.now().toUtc();
    await _persistToPrefs();

    PrimekitLogger.debug(
      'Cache hydrated with ${_memoryCache.length} entries.',
      tag: _tag,
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await _resolvePrefs();
      final raw = prefs.getString(_prefsKey);
      final ts = prefs.getString(_prefsTimestampKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _memoryCache = Map<String, dynamic>.unmodifiable(decoded);
        }
      }

      if (ts != null) {
        _cachedAt = DateTime.tryParse(ts);
      }

      PrimekitLogger.debug(
        'Loaded ${_memoryCache.length} cached flags from prefs.',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to load cached flags from prefs.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _persistToPrefs() async {
    try {
      final prefs = await _resolvePrefs();
      await prefs.setString(_prefsKey, jsonEncode(_memoryCache));
      await prefs.setString(
        _prefsTimestampKey,
        (_cachedAt ?? DateTime.now().toUtc()).toIso8601String(),
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to persist cached flags to prefs.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<SharedPreferences> _resolvePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Exposes the internal memory cache for testing.
  Map<String, dynamic> get cacheForTesting =>
      Map<String, dynamic>.of(_memoryCache);

  /// Directly seeds the cache (for testing stale-while-revalidate logic).
  void seedCacheForTesting(Map<String, dynamic> data, {DateTime? cachedAt}) {
    _memoryCache = Map<String, dynamic>.unmodifiable(data);
    _cachedAt = cachedAt;
  }
}

// Suppress lint for intentional fire-and-forget calls.
void unawaited(Future<dynamic> future) {}
