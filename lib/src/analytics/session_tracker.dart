import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import 'analytics_event.dart';
import 'event_tracker.dart';

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

/// Discriminated union of all events emitted by [SessionTracker].
sealed class SessionEvent {
  const SessionEvent();
}

/// Emitted when a new session starts.
final class SessionStartedEvent extends SessionEvent {
  const SessionStartedEvent({
    required this.sessionCount,
    required this.startedAt,
  });

  /// The total number of sessions including this one.
  final int sessionCount;

  /// When this session started (UTC).
  final DateTime startedAt;
}

/// Emitted when a session ends.
final class SessionEndedEvent extends SessionEvent {
  const SessionEndedEvent({
    required this.sessionCount,
    required this.duration,
    required this.endedAt,
  });

  /// Session ordinal (same value as [SessionStartedEvent.sessionCount]).
  final int sessionCount;

  /// How long the session lasted.
  final Duration duration;

  /// When this session ended (UTC).
  final DateTime endedAt;
}

/// Emitted when the tracker detects the user has been idle.
final class SessionIdleEvent extends SessionEvent {
  const SessionIdleEvent({required this.idleDuration});

  /// How long the user has been idle.
  final Duration idleDuration;
}

// ---------------------------------------------------------------------------
// SessionTracker
// ---------------------------------------------------------------------------

/// Tracks app session lifecycle and idle detection.
///
/// Use [startSession] and [endSession] around your app foreground/background
/// transitions. The stream of [SessionEvent]s can be used to drive UI badges,
/// push-notification scheduling, or analytics dashboards.
///
/// ```dart
/// // In your top-level widget or AppLifecycleObserver:
/// final tracker = SessionTracker.instance;
/// tracker.startSession();
///
/// // Listen for events anywhere:
/// tracker.events.listen((event) {
///   switch (event) {
///     case SessionStartedEvent(:final sessionCount):
///       print('Session #$sessionCount started');
///     case SessionEndedEvent(:final duration):
///       print('Session lasted ${duration.inSeconds}s');
///     case SessionIdleEvent(:final idleDuration):
///       print('Idle for ${idleDuration.inSeconds}s');
///   }
/// });
/// ```
final class SessionTracker {
  SessionTracker._();

  static final SessionTracker _instance = SessionTracker._();

  /// The shared singleton instance.
  static SessionTracker get instance => _instance;

  static const String _tag = 'SessionTracker';
  static const String _prefKeySessionCount = 'primekit_session_count';

  /// How long without activity before an idle event is emitted.
  static const Duration _idleThreshold = Duration(minutes: 5);

  final StreamController<SessionEvent> _eventController =
      StreamController<SessionEvent>.broadcast();

  DateTime? _sessionStart;
  int _sessionCount = 0;
  Timer? _idleTimer;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Broadcast stream of [SessionEvent]s emitted during session tracking.
  Stream<SessionEvent> get events => _eventController.stream;

  /// The elapsed time since [startSession] was last called.
  ///
  /// Returns [Duration.zero] when no session is active.
  Duration get currentSessionDuration {
    final start = _sessionStart;
    if (start == null) return Duration.zero;
    return DateTime.now().toUtc().difference(start);
  }

  /// The total number of sessions started since the app was first installed.
  ///
  /// Persisted across app restarts via [SharedPreferences].
  int get sessionCount => _sessionCount;

  /// Starts a new session.
  ///
  /// If a session is already active, this call is a no-op (the existing
  /// session continues uninterrupted).
  Future<void> startSession() async {
    if (_sessionStart != null) {
      PrimekitLogger.verbose(
        'startSession() called while session already active — ignored.',
        tag: _tag,
      );
      return;
    }

    await _ensureInitialized();

    _sessionCount += 1;
    await _persistSessionCount(_sessionCount);

    _sessionStart = DateTime.now().toUtc();
    _resetIdleTimer();

    final event = SessionStartedEvent(
      sessionCount: _sessionCount,
      startedAt: _sessionStart!,
    );
    _eventController.add(event);

    unawaited(
      EventTracker.instance.logEvent(
        AnalyticsEvent(
          name: 'session_start',
          parameters: {'session_count': _sessionCount},
        ),
      ),
    );

    PrimekitLogger.info('Session #$_sessionCount started.', tag: _tag);
  }

  /// Ends the current session.
  ///
  /// No-op when no session is active.
  Future<void> endSession() async {
    final start = _sessionStart;
    if (start == null) {
      PrimekitLogger.verbose(
        'endSession() called with no active session — ignored.',
        tag: _tag,
      );
      return;
    }

    _idleTimer?.cancel();
    _idleTimer = null;

    final endedAt = DateTime.now().toUtc();
    final duration = endedAt.difference(start);

    // Clear session start before emitting so getters return consistent values.
    _sessionStart = null;

    final event = SessionEndedEvent(
      sessionCount: _sessionCount,
      duration: duration,
      endedAt: endedAt,
    );
    _eventController.add(event);

    unawaited(
      EventTracker.instance.logEvent(
        AnalyticsEvent(
          name: 'session_end',
          parameters: {
            'session_count': _sessionCount,
            'duration_seconds': duration.inSeconds,
          },
        ),
      ),
    );

    PrimekitLogger.info(
      'Session #$_sessionCount ended after ${duration.inSeconds}s.',
      tag: _tag,
    );
  }

  /// Signals user activity, resetting the idle detection timer.
  ///
  /// Call this from gesture detectors or scroll listeners to keep the idle
  /// timer accurate.
  void recordActivity() {
    if (_sessionStart == null) return;
    _resetIdleTimer();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    _sessionCount = await _loadSessionCount();
    PrimekitLogger.debug(
      'Loaded persisted session count: $_sessionCount.',
      tag: _tag,
    );
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, _onIdle);
  }

  void _onIdle() {
    const idleDuration = _idleThreshold;
    _eventController.add(const SessionIdleEvent(idleDuration: _idleThreshold));

    unawaited(
      EventTracker.instance.logEvent(
        AnalyticsEvent(
          name: 'session_idle',
          parameters: {'idle_seconds': idleDuration.inSeconds},
        ),
      ),
    );

    PrimekitLogger.debug(
      'Session idle for ${idleDuration.inSeconds}s.',
      tag: _tag,
    );
  }

  static Future<int> _loadSessionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_prefKeySessionCount) ?? 0;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to load session count from SharedPreferences.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      return 0;
    }
  }

  static Future<void> _persistSessionCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeySessionCount, count);
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to persist session count.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets tracker to its initial state. For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _sessionStart = null;
    _sessionCount = 0;
    _initialized = false;
  }
}
