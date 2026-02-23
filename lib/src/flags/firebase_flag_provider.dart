import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'flag_provider.dart';

/// A [FlagProvider] backed by Firebase Remote Config.
///
/// ```dart
/// final provider = FirebaseFlagProvider();
/// await FlagService.instance.configure(provider);
/// ```
///
/// The [fetchInterval] governs how frequently [refresh] will actually hit
/// the network (Firebase enforces a server-side throttle as well).
/// During development you may lower [minimumFetchInterval] to [Duration.zero].
final class FirebaseFlagProvider implements FlagProvider {
  /// Creates a Firebase Remote Config provider.
  FirebaseFlagProvider({
    FirebaseRemoteConfig? remoteConfig,
    Duration fetchInterval = const Duration(hours: 1),
    Duration minimumFetchInterval = const Duration(minutes: 5),
  }) : _fetchInterval = fetchInterval,
       _minimumFetchInterval = minimumFetchInterval,
       _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final Duration _fetchInterval;
  final Duration _minimumFetchInterval;

  DateTime? _lastFetchedAt;

  static const String _tag = 'FirebaseFlagProvider';

  @override
  String get providerId => 'firebase';

  @override
  DateTime? get lastFetchedAt => _lastFetchedAt;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchInterval,
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );
      await _remoteConfig.fetchAndActivate();
      _lastFetchedAt = DateTime.now().toUtc();
      PrimekitLogger.info(
        'Initialised — ${_remoteConfig.getAll().length} keys loaded.',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to initialise Firebase Remote Config.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      throw ConfigurationException(
        message: 'FirebaseFlagProvider.initialize() failed: $error',
      );
    }
  }

  @override
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
      _lastFetchedAt = DateTime.now().toUtc();
      PrimekitLogger.info('Config refreshed.', tag: _tag);
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to refresh Firebase Remote Config.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generic accessor
  // ---------------------------------------------------------------------------

  @override
  T getValue<T>(String key, T defaultValue) {
    if (T == bool) return getBool(key, defaultValue: defaultValue as bool) as T;
    if (T == int) return getInt(key, defaultValue: defaultValue as int) as T;
    if (T == double) {
      return getDouble(key, defaultValue: defaultValue as double) as T;
    }
    if (T == String) {
      return getString(key, defaultValue: defaultValue as String) as T;
    }
    if (T == Map) {
      return getJson(key, defaultValue: defaultValue as Map<String, dynamic>)
          as T;
    }
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Typed accessors
  // ---------------------------------------------------------------------------

  @override
  bool getBool(String key, {required bool defaultValue}) {
    try {
      return _remoteConfig.getBool(key);
    } on Exception {
      return defaultValue;
    }
  }

  @override
  String getString(String key, {required String defaultValue}) {
    try {
      final value = _remoteConfig.getString(key);
      return value.isEmpty ? defaultValue : value;
    } on Exception {
      return defaultValue;
    }
  }

  @override
  int getInt(String key, {required int defaultValue}) {
    try {
      return _remoteConfig.getInt(key);
    } on Exception {
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, {required double defaultValue}) {
    try {
      return _remoteConfig.getDouble(key);
    } on Exception {
      return defaultValue;
    }
  }

  @override
  Map<String, dynamic> getJson(
    String key, {
    required Map<String, dynamic> defaultValue,
  }) {
    try {
      final raw = _remoteConfig.getString(key);
      if (raw.isEmpty) return defaultValue;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return defaultValue;
    } on Exception catch (error) {
      PrimekitLogger.warning(
        'Failed to decode JSON flag "$key".',
        tag: _tag,
        error: error,
      );
      return defaultValue;
    }
  }
}
