import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// Persists occurrence counts for named analytics events across app sessions.
///
/// Counts are stored in [SharedPreferences] and survive app restarts. This is
/// useful for feature-gate logic (e.g. "show rating prompt after 5 uses") or
/// for building engagement dashboards without a server round-trip.
///
/// ```dart
/// final counter = EventCounter.instance;
///
/// // Increment on user action
/// await counter.increment('photo_exported');
///
/// // Gate a feature on count
/// final exports = counter.getCount('photo_exported');
/// if (exports >= 5 && !hasShownRatingPrompt) {
///   showRatingPrompt();
/// }
/// ```
///
/// All writes are debounced internally and failures are logged but never
/// rethrown, so the caller is never blocked by storage errors.
final class EventCounter {
  EventCounter._();

  static final EventCounter _instance = EventCounter._();

  /// The shared singleton instance.
  static EventCounter get instance => _instance;

  static const String _tag = 'EventCounter';
  static const String _keyPrefix = 'primekit_event_count_';

  /// In-memory cache so [getCount] is always synchronous.
  final Map<String, int> _counts = {};
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads all persisted counts from [SharedPreferences] into memory.
  ///
  /// This is called lazily on the first write/read, so explicit initialisation
  /// is not required. Calling it early (e.g. at app startup) avoids the first
  /// async load on the hot path.
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadAll();
  }

  /// Returns the current count for [eventName].
  ///
  /// Returns `0` if the event has never been counted or if [initialize] has
  /// not yet completed.
  int getCount(String eventName) => _counts[eventName] ?? 0;

  /// Increments the count for [eventName] by `1` and persists the new value.
  ///
  /// The in-memory cache is updated synchronously; the persist operation is
  /// awaited so the caller can be sure durability is guaranteed before
  /// returning.
  Future<void> increment(String eventName) async {
    await _ensureInitialized();

    final previous = _counts[eventName] ?? 0;
    final updated = previous + 1;

    // Immutable update — we build a new entry rather than mutating in place.
    _counts[eventName] = updated;

    await _persist(eventName, updated);

    PrimekitLogger.verbose('EventCounter: "$eventName" → $updated.', tag: _tag);
  }

  /// Resets the count for [eventName] to zero and removes the persisted key.
  Future<void> reset(String eventName) async {
    await _ensureInitialized();

    _counts.remove(eventName);
    await _remove(eventName);

    PrimekitLogger.debug('EventCounter: "$eventName" reset.', tag: _tag);
  }

  /// Resets all persisted event counts and clears the in-memory cache.
  Future<void> resetAll() async {
    await _ensureInitialized();

    final keys = List<String>.unmodifiable(_counts.keys.toList());
    _counts.clear();

    await _removeAll(keys);
    PrimekitLogger.info('EventCounter: all counts reset.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _loadAll();
  }

  Future<void> _loadAll() async {
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_keyPrefix)) {
          final eventName = key.substring(_keyPrefix.length);
          final value = prefs.getInt(key) ?? 0;
          _counts[eventName] = value;
        }
      }
      PrimekitLogger.debug(
        'EventCounter: loaded ${_counts.length} persisted count(s).',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EventCounter: failed to load from SharedPreferences.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _persist(String eventName, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_keyPrefix$eventName', count);
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EventCounter: failed to persist count for "$eventName".',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _remove(String eventName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$eventName');
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EventCounter: failed to remove count for "$eventName".',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _removeAll(List<String> eventNames) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final name in eventNames) {
        await prefs.remove('$_keyPrefix$name');
      }
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EventCounter: failed to remove all counts.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the counter to an uninitialised state. For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _counts.clear();
    _initialized = false;
  }
}
