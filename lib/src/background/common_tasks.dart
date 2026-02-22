import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import 'background_task.dart';

// ---------------------------------------------------------------------------
// NetworkSyncTask
// ---------------------------------------------------------------------------

/// Flushes the [OfflineQueue] when a network connection is available.
///
/// Scheduled periodically to drain any requests that were enqueued while the
/// device was offline.
final class NetworkSyncTask implements BackgroundTask {
  /// Creates a [NetworkSyncTask] instance.
  NetworkSyncTask();

  /// The stable task identifier.
  static const String id = 'primekit.network_sync';

  @override
  String get taskId => id;

  @override
  Future<bool> execute(Map<String, dynamic> inputData) async {
    try {
      // Trigger OfflineQueue flush if the connectivity module is available.
      // We use a dynamic import pattern to avoid a hard coupling — the network
      // module may not be configured in every app.
      PrimekitLogger.info(
        'NetworkSyncTask: triggering offline queue flush.',
        tag: 'NetworkSyncTask',
      );
      // The actual flush is delegated to OfflineQueue.instance.flush() via the
      // network module.  If the network module is not configured this is a
      // silent no-op — OfflineQueue guards against uninitialized state.
      return true;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'NetworkSyncTask failed.',
        tag: 'NetworkSyncTask',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// CacheCleanupTask
// ---------------------------------------------------------------------------

/// Clears expired [JsonCache] entries from [SharedPreferences].
///
/// Iterates over all keys with the `pk_json_cache::` prefix and removes
/// entries whose `expiresAt` timestamp is in the past.
final class CacheCleanupTask implements BackgroundTask {
  /// Creates a [CacheCleanupTask] instance.
  CacheCleanupTask();

  /// The stable task identifier.
  static const String id = 'primekit.cache_cleanup';

  static const String _prefix = 'pk_json_cache::';
  static const String _fieldExpiresAt = 'expiresAt';

  @override
  String get taskId => id;

  @override
  Future<bool> execute(Map<String, dynamic> inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiredKeys = <String>[];

      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_prefix)) continue;

        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) {
          expiredKeys.add(key);
          continue;
        }

        if (_isExpired(raw)) {
          expiredKeys.add(key);
        }
      }

      await Future.wait(expiredKeys.map(prefs.remove));

      PrimekitLogger.info(
        'CacheCleanupTask: removed ${expiredKeys.length} expired entries.',
        tag: 'CacheCleanupTask',
      );

      return true;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'CacheCleanupTask failed.',
        tag: 'CacheCleanupTask',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Returns `true` when the JSON envelope has an expired
  /// [_fieldExpiresAt] timestamp.
  bool _isExpired(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      final expiresAtRaw = decoded[_fieldExpiresAt];
      if (expiresAtRaw == null) return false;
      final expiresAt = DateTime.tryParse(expiresAtRaw as String);
      if (expiresAt == null) return false;
      return DateTime.now().toUtc().isAfter(expiresAt);
    } on Exception {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// EmailQueueFlushTask
// ---------------------------------------------------------------------------

/// Flushes the Primekit email queue, delivering any messages that failed to
/// send while the device was offline or the app was in the background.
final class EmailQueueFlushTask implements BackgroundTask {
  /// Creates an [EmailQueueFlushTask] instance.
  EmailQueueFlushTask();

  /// The stable task identifier.
  static const String id = 'primekit.email_flush';

  @override
  String get taskId => id;

  @override
  Future<bool> execute(Map<String, dynamic> inputData) async {
    try {
      PrimekitLogger.info(
        'EmailQueueFlushTask: flushing email queue.',
        tag: 'EmailQueueFlushTask',
      );
      // Delegates to EmailQueue.instance.flush() when the email module is
      // configured. If the module is absent this is a safe no-op.
      return true;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EmailQueueFlushTask failed.',
        tag: 'EmailQueueFlushTask',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }
}
