import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'flag_provider.dart';

/// A [FlagProvider] backed by MongoDB Atlas Data API (REST).
///
/// Fetches all flags from a `feature_flags` collection at initialisation and
/// on every [refresh] call, caching them locally.  Individual [getValue] reads
/// are served from the in-memory cache with no additional network traffic.
///
/// Expected document schema:
/// ```json
/// { "key": "dark_mode", "value": true, "enabled": true }
/// ```
///
/// Disabled documents (`enabled: false`) are ignored — their default values
/// are returned instead.
///
/// ```dart
/// final provider = MongoFlagProvider(
///   baseUrl: 'https://data.mongodb-api.com/app/<appId>/endpoint/data/v1',
///   apiKey: Env.mongoApiKey,
///   dataSource: 'Cluster0',
///   database: 'my_app',
/// );
/// ```
final class MongoFlagProvider implements FlagProvider {
  /// Creates a MongoDB Atlas Data API flag provider.
  MongoFlagProvider({
    required String baseUrl,
    required String apiKey,
    required String dataSource,
    required String database,
    String collection = 'feature_flags',
    Duration cacheTtl = const Duration(hours: 1),
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _dataSource = dataSource,
        _database = database,
        _collection = collection,
        _cacheTtl = cacheTtl,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final String _apiKey;
  final String _dataSource;
  final String _database;
  final String _collection;
  final Duration _cacheTtl;
  final Dio _dio;

  /// Local cache: key → raw dynamic value.
  Map<String, dynamic> _cache = {};

  DateTime? _lastFetchedAt;

  static const String _tag = 'MongoFlagProvider';

  @override
  String get providerId => 'mongo';

  @override
  DateTime? get lastFetchedAt => _lastFetchedAt;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    await _fetchAll();
  }

  @override
  Future<void> refresh() async {
    await _fetchAll();
  }

  // ---------------------------------------------------------------------------
  // Generic accessor
  // ---------------------------------------------------------------------------

  @override
  T getValue<T>(String key, T defaultValue) {
    final raw = _cache[key];
    if (raw is T) return raw;
    // Coerce int → double.
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
    final raw = _cache[key];
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return defaultValue;
  }

  @override
  Map<String, dynamic> getJson(
    String key, {
    required Map<String, dynamic> defaultValue,
  }) {
    final raw = _cache[key];
    if (raw is Map<String, dynamic>) return raw;
    // Value may be stored as a JSON string in the DB.
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } on Exception {
        // Fall through to default.
      }
    }
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _fetchAll() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/action/find',
        options: Options(
          headers: <String, String>{
            'api-key': _apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(<String, dynamic>{
          'dataSource': _dataSource,
          'database': _database,
          'collection': _collection,
          'filter': <String, dynamic>{},
        }),
      );

      final body = response.data;
      if (body == null) {
        PrimekitLogger.warning(
          'Atlas API returned null body.',
          tag: _tag,
        );
        return;
      }

      final docs = body['documents'];
      if (docs is! List<dynamic>) {
        PrimekitLogger.warning(
          'Unexpected Atlas response shape.',
          tag: _tag,
        );
        return;
      }

      final updated = <String, dynamic>{};
      for (final doc in docs) {
        if (doc is! Map<String, dynamic>) continue;
        final enabled = doc['enabled'];
        if (enabled is bool && !enabled) continue;
        final key = doc['key'];
        if (key is! String || key.isEmpty) continue;
        updated[key] = doc['value'];
      }

      _cache = Map<String, dynamic>.unmodifiable(updated);
      _lastFetchedAt = DateTime.now().toUtc();

      PrimekitLogger.info(
        'Fetched ${_cache.length} flags from Atlas.',
        tag: _tag,
      );
    } on DioException catch (error, stack) {
      PrimekitLogger.error(
        'Network error fetching flags from Atlas.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      if (_cache.isEmpty) {
        // Only rethrow on first init when we have no cached data.
        throw NetworkException(
          message: 'MongoFlagProvider._fetchAll() failed: ${error.message}',
          statusCode: error.response?.statusCode,
          cause: error,
        );
      }
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Unexpected error fetching flags from Atlas.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // TTL helper (used by CachedFlagProvider interop)
  // ---------------------------------------------------------------------------

  /// Whether the local cache is stale relative to [_cacheTtl].
  bool get isCacheStale {
    final fetched = _lastFetchedAt;
    if (fetched == null) return true;
    return DateTime.now().toUtc().difference(fetched) > _cacheTtl;
  }
}
