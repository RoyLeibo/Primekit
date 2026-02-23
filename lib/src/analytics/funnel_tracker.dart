import 'package:flutter/foundation.dart';

import '../core/logger.dart';
import 'analytics_event.dart';
import 'event_tracker.dart';

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

/// Defines a named multi-step user funnel.
///
/// ```dart
/// const onboarding = FunnelDefinition(
///   name: 'onboarding',
///   steps: [
///     'welcome', 'profile_setup', 'notification_permission', 'complete',
///   ],
/// );
/// ```
final class FunnelDefinition {
  /// Creates an immutable funnel definition.
  ///
  /// [steps] must be non-empty and contain unique names.
  const FunnelDefinition({required this.name, required this.steps})
    : assert(name != '', 'FunnelDefinition.name must not be empty'),
      assert(steps.length > 0, 'FunnelDefinition.steps must not be empty');

  /// Unique identifier for this funnel.
  final String name;

  /// Ordered list of step names. Steps must be completed in order.
  final List<String> steps;
}

/// Immutable snapshot of a user's progress through a funnel.
final class FunnelState {
  const FunnelState({
    required this.funnelName,
    required this.userId,
    required this.completedSteps,
    required this.startedAt,
    required this.status,
    this.abandonReason,
    this.completedAt,
  });

  /// The funnel this state belongs to.
  final String funnelName;

  /// The user participating in the funnel, if known.
  final String? userId;

  /// Steps that have been completed so far (in order).
  final List<String> completedSteps;

  /// When the funnel was started.
  final DateTime startedAt;

  /// Current status of the funnel.
  final FunnelStatus status;

  /// Populated when [status] is [FunnelStatus.abandoned].
  final String? abandonReason;

  /// Populated when [status] is [FunnelStatus.completed].
  final DateTime? completedAt;

  /// Returns a copy with the given fields replaced.
  FunnelState copyWith({
    List<String>? completedSteps,
    FunnelStatus? status,
    String? abandonReason,
    DateTime? completedAt,
  }) => FunnelState(
    funnelName: funnelName,
    userId: userId,
    completedSteps:
        completedSteps ?? List<String>.unmodifiable(this.completedSteps),
    startedAt: startedAt,
    status: status ?? this.status,
    abandonReason: abandonReason ?? this.abandonReason,
    completedAt: completedAt ?? this.completedAt,
  );
}

/// The lifecycle status of a funnel session.
enum FunnelStatus {
  /// The funnel has been started but no steps have been completed yet.
  started,

  /// One or more steps are in progress.
  inProgress,

  /// All steps have been completed.
  completed,

  /// The user exited the funnel before completing all steps.
  abandoned,
}

// ---------------------------------------------------------------------------
// FunnelTracker
// ---------------------------------------------------------------------------

/// Tracks multi-step user funnels and forwards funnel events to [EventTracker].
///
/// Register your funnel definitions once, then call [startFunnel],
/// [completeStep], and [abandonFunnel] at the appropriate points in your app:
///
/// ```dart
/// final tracker = FunnelTracker.instance;
///
/// tracker.registerFunnel(const FunnelDefinition(
///   name: 'checkout',
///   steps: ['cart', 'shipping', 'payment', 'confirmation'],
/// ));
///
/// tracker.startFunnel('checkout', userId: currentUser.id);
/// tracker.completeStep('checkout', 'cart');
/// tracker.completeStep('checkout', 'shipping');
/// tracker.abandonFunnel('checkout', reason: 'payment_failed');
/// ```
final class FunnelTracker {
  FunnelTracker._();

  static final FunnelTracker _instance = FunnelTracker._();

  /// The shared singleton instance.
  static FunnelTracker get instance => _instance;

  static const String _tag = 'FunnelTracker';

  /// Registered funnel definitions keyed by funnel name.
  final Map<String, FunnelDefinition> _definitions = {};

  /// Active funnel states keyed by funnel name.
  final Map<String, FunnelState> _states = {};

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Registers a [FunnelDefinition] so it can be tracked.
  ///
  /// Calling this again with the same `definition.name` replaces the existing
  /// definition. Does not affect any in-flight funnel state.
  void registerFunnel(FunnelDefinition definition) {
    _definitions[definition.name] = definition;
    PrimekitLogger.debug(
      'Funnel "${definition.name}" registered '
      '(${definition.steps.length} steps).',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts a new session for [funnelName].
  ///
  /// If a session is already active for the same funnel, it is discarded and
  /// replaced with a fresh one. [userId] is optional and is included in all
  /// events emitted for this session.
  ///
  /// Logs a warning and returns without effect if [funnelName] has not been
  /// registered via [registerFunnel].
  void startFunnel(String funnelName, {String? userId}) {
    final definition = _definitions[funnelName];
    if (definition == null) {
      PrimekitLogger.warning(
        'startFunnel("$funnelName"): funnel not registered.',
        tag: _tag,
      );
      return;
    }

    final state = FunnelState(
      funnelName: funnelName,
      userId: userId,
      completedSteps: const [],
      startedAt: DateTime.now().toUtc(),
      status: FunnelStatus.started,
    );

    _states[funnelName] = state;

    _emitEvent(
      'funnel_started',
      funnelName: funnelName,
      userId: userId,
      extra: {'total_steps': definition.steps.length},
    );

    PrimekitLogger.info('Funnel "$funnelName" started.', tag: _tag);
  }

  /// Records completion of [stepName] in [funnelName].
  ///
  /// Steps may be completed in any order, but the tracker logs the index of
  /// the step as it appears in the definition to preserve ordering context.
  ///
  /// If this is the last required step, [completeStep] automatically marks the
  /// funnel as completed and emits a `funnel_completed` event.
  ///
  /// No-op with a warning if:
  /// - The funnel has not been registered.
  /// - No active session exists (call [startFunnel] first).
  /// - The funnel session is already completed or abandoned.
  void completeStep(String funnelName, String stepName) {
    final definition = _definitions[funnelName];
    if (definition == null) {
      PrimekitLogger.warning(
        'completeStep: funnel "$funnelName" not registered.',
        tag: _tag,
      );
      return;
    }

    final state = _states[funnelName];
    if (state == null) {
      PrimekitLogger.warning(
        'completeStep("$funnelName", "$stepName"): no active session. '
        'Call startFunnel() first.',
        tag: _tag,
      );
      return;
    }

    if (state.status == FunnelStatus.completed ||
        state.status == FunnelStatus.abandoned) {
      PrimekitLogger.warning(
        'completeStep("$funnelName", "$stepName"): session already '
        '${state.status.name}.',
        tag: _tag,
      );
      return;
    }

    final stepIndex = definition.steps.indexOf(stepName);
    final updatedSteps = List<String>.unmodifiable([
      ...state.completedSteps,
      stepName,
    ]);

    _emitEvent(
      'funnel_step_completed',
      funnelName: funnelName,
      userId: state.userId,
      extra: {
        'step_name': stepName,
        'step_index': stepIndex,
        'steps_completed': updatedSteps.length,
        'total_steps': definition.steps.length,
      },
    );

    final allStepsComplete = definition.steps.every(updatedSteps.contains);

    if (allStepsComplete) {
      final completedAt = DateTime.now().toUtc();
      final duration = completedAt.difference(state.startedAt);

      _states[funnelName] = state.copyWith(
        completedSteps: updatedSteps,
        status: FunnelStatus.completed,
        completedAt: completedAt,
      );

      _emitEvent(
        'funnel_completed',
        funnelName: funnelName,
        userId: state.userId,
        extra: {'duration_seconds': duration.inSeconds},
      );

      PrimekitLogger.info(
        'Funnel "$funnelName" completed in ${duration.inSeconds}s.',
        tag: _tag,
      );
    } else {
      _states[funnelName] = state.copyWith(
        completedSteps: updatedSteps,
        status: FunnelStatus.inProgress,
      );

      PrimekitLogger.debug(
        'Funnel "$funnelName": step "$stepName" completed '
        '(${updatedSteps.length}/${definition.steps.length}).',
        tag: _tag,
      );
    }
  }

  /// Records that the user abandoned [funnelName] before completing all steps.
  ///
  /// [reason] is an optional machine-readable string (e.g. `'payment_failed'`)
  /// included in the `funnel_abandoned` event.
  ///
  /// No-op with a warning if no active session exists.
  void abandonFunnel(String funnelName, {String? reason}) {
    final state = _states[funnelName];
    if (state == null) {
      PrimekitLogger.warning(
        'abandonFunnel("$funnelName"): no active session.',
        tag: _tag,
      );
      return;
    }

    if (state.status == FunnelStatus.completed ||
        state.status == FunnelStatus.abandoned) {
      PrimekitLogger.warning(
        'abandonFunnel("$funnelName"): session already ${state.status.name}.',
        tag: _tag,
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final duration = now.difference(state.startedAt);

    _states[funnelName] = state.copyWith(
      status: FunnelStatus.abandoned,
      abandonReason: reason,
    );

    _emitEvent(
      'funnel_abandoned',
      funnelName: funnelName,
      userId: state.userId,
      extra: {
        'steps_completed': state.completedSteps.length,
        'last_step': state.completedSteps.lastOrNull,
        'duration_seconds': duration.inSeconds,
        'reason': ?reason,
      },
    );

    PrimekitLogger.info(
      'Funnel "$funnelName" abandoned'
      '${reason != null ? ' (reason: $reason)' : ''}.',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // State access
  // ---------------------------------------------------------------------------

  /// Returns the current [FunnelState] for [funnelName], or `null` if no
  /// session has been started.
  FunnelState? getState(String funnelName) => _states[funnelName];

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _emitEvent(
    String eventName, {
    required String funnelName,
    required String? userId,
    Map<String, Object?> extra = const {},
  }) {
    final params = <String, Object?>{
      'funnel_name': funnelName,
      'user_id': ?userId,
      ...extra,
    };

    EventTracker.instance.logEvent(
      AnalyticsEvent(name: eventName, parameters: params),
    );
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Clears all definitions and states. For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _definitions.clear();
    _states.clear();
  }
}
