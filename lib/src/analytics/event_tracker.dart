import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'analytics_event.dart';
import 'analytics_provider.dart';

/// Central fan-out hub for analytics events.
///
/// [EventTracker] is a singleton that holds a list of [AnalyticsProvider]
/// instances and dispatches every tracked event to all of them in parallel.
///
/// ## Quick-start
///
/// ```dart
/// // In main(), after PrimekitConfig.initialize():
/// EventTracker.instance.configure([
///   FirebaseAnalyticsProvider(),
///   AmplitudeAnalyticsProvider(apiKey: Env.amplitudeKey),
/// ]);
///
/// // Later, anywhere in the app:
/// await EventTracker.instance.logEvent(
///   AnalyticsEvent.screenView(screenName: 'HomeScreen'),
/// );
/// ```
final class EventTracker {
  EventTracker._();

  static final EventTracker _instance = EventTracker._();

  /// The shared singleton instance.
  static EventTracker get instance => _instance;

  // ---------------------------------------------------------------------------
  // State — all mutations go through the methods below; fields are never
  // exposed for external mutation (immutability policy).
  // ---------------------------------------------------------------------------

  List<AnalyticsProvider> _providers = const [];
  bool _enabled = true;
  bool _configured = false;

  static const String _tag = 'EventTracker';

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the tracker with the given [providers].
  ///
  /// Calling this a second time replaces the existing provider list and
  /// re-initialises each provider. Safe to call from any isolate context.
  ///
  /// Throws [ConfigurationException] if [providers] is empty.
  Future<void> configure(List<AnalyticsProvider> providers) async {
    if (providers.isEmpty) {
      throw const ConfigurationException(
        message: 'EventTracker.configure() requires at least one provider.',
      );
    }

    // Immutable snapshot — we never mutate the caller's list.
    _providers = List.unmodifiable(providers);
    _configured = true;

    final initFutures = _providers.map((p) async {
      try {
        await p.initialize();
        PrimekitLogger.info('Provider "${p.name}" initialised.', tag: _tag);
      } on Exception catch (error, stack) {
        PrimekitLogger.error(
          'Failed to initialise provider "${p.name}".',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      }
    });

    await Future.wait(initFutures);
    PrimekitLogger.info(
      'EventTracker configured with ${_providers.length} provider(s).',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Tracking
  // ---------------------------------------------------------------------------

  /// Whether event tracking is currently active.
  ///
  /// Setting this to `false` silently drops all events without forwarding
  /// them to any provider. Useful for honouring a user's opt-out preference.
  bool get enabled => _enabled;

  set enabled(bool value) {
    _enabled = value;
    PrimekitLogger.info(
      'EventTracker ${value ? "enabled" : "disabled"}.',
      tag: _tag,
    );
  }

  /// Sends [event] to every registered provider in parallel.
  ///
  /// No-op when [enabled] is `false` or [configure] has not been called.
  /// Provider-level errors are caught and logged; they never propagate to
  /// the caller.
  Future<void> logEvent(AnalyticsEvent event) async {
    if (!_enabled) return;
    if (!_configured || _providers.isEmpty) {
      PrimekitLogger.warning(
        'logEvent("${event.name}") called before configure(). '
        'Call EventTracker.instance.configure(...) first.',
        tag: _tag,
      );
      return;
    }

    PrimekitLogger.verbose('Logging event "${event.name}".', tag: _tag);

    final dispatchFutures = _providers.map((p) async {
      try {
        await p.logEvent(event);
      } on Exception catch (error, stack) {
        PrimekitLogger.error(
          'Provider "${p.name}" failed to log event "${event.name}".',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      }
    });

    await Future.wait(dispatchFutures);
  }

  /// Associates all subsequent events with [userId].
  ///
  /// Pass `null` to clear the current identity (e.g. on sign-out).
  Future<void> setUserId(String? userId) async {
    if (!_enabled || !_configured) return;

    final futures = _providers.map((p) async {
      try {
        await p.setUserId(userId);
      } on Exception catch (error, stack) {
        PrimekitLogger.error(
          'Provider "${p.name}" failed to set userId.',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      }
    });

    await Future.wait(futures);
    PrimekitLogger.debug(
      userId != null ? 'User ID set.' : 'User ID cleared.',
      tag: _tag,
    );
  }

  /// Attaches a persistent user property [key]=[value] to all future events.
  Future<void> setUserProperty(String key, String value) async {
    if (!_enabled || !_configured) return;

    final futures = _providers.map((p) async {
      try {
        await p.setUserProperty(key, value);
      } on Exception catch (error, stack) {
        PrimekitLogger.error(
          'Provider "${p.name}" failed to set user property "$key".',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      }
    });

    await Future.wait(futures);
    PrimekitLogger.debug('User property "$key" set.', tag: _tag);
  }

  /// Clears all user identity data from every registered provider.
  ///
  /// Call this on sign-out to ensure no user data is attributed to future
  /// sessions.
  Future<void> reset() async {
    if (!_configured) return;

    final futures = _providers.map((p) async {
      try {
        await p.reset();
      } on Exception catch (error, stack) {
        PrimekitLogger.error(
          'Provider "${p.name}" failed to reset.',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      }
    });

    await Future.wait(futures);
    PrimekitLogger.info('EventTracker reset complete.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the tracker to its unconfigured state.
  ///
  /// For use in tests only. Not part of the public API.
  @visibleForTesting
  void resetForTesting() {
    _providers = const [];
    _enabled = true;
    _configured = false;
  }
}
