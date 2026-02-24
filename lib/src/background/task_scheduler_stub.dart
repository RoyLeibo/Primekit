import 'package:flutter/foundation.dart';

import 'background_task.dart';

// ---------------------------------------------------------------------------
// ExistingWorkPolicy  (mirrors the real implementation)
// ---------------------------------------------------------------------------

/// Controls what happens when a task with the same unique name is scheduled
/// while an existing task with that name is already enqueued or running.
enum ExistingWorkPolicy {
  /// Replace the existing task with the new one.
  replace,

  /// Keep the existing task and discard the new scheduling request.
  keep,

  /// Append the new task after the existing one completes.
  append,
}

// ---------------------------------------------------------------------------
// callbackDispatcher  (no-op on non-mobile)
// ---------------------------------------------------------------------------

/// Top-level callback stub for platforms that do not support WorkManager.
///
/// On Web and Desktop this function exists only to satisfy imports; it is
/// never actually called by the system.
@pragma('vm:entry-point')
void callbackDispatcher() {
  debugPrint(
    '[Primekit] callbackDispatcher: Background tasks not supported on this platform.',
  );
}

// ---------------------------------------------------------------------------
// TaskScheduler (stub)
// ---------------------------------------------------------------------------

/// Stub [TaskScheduler] for platforms that do not support WorkManager.
///
/// All scheduling methods are no-ops that emit a debug warning.
/// This class has the EXACT same public API as the mobile implementation.
final class TaskScheduler {
  TaskScheduler._();

  static final TaskScheduler _instance = TaskScheduler._();

  /// The shared singleton instance.
  static TaskScheduler get instance => _instance;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// No-op on platforms that do not support background tasks.
  static Future<void> initialize({
    required Map<String, BackgroundTask Function()> taskRegistry,
    bool isInDebugMode = false,
  }) async {
    debugPrint(
      '[Primekit] TaskScheduler.initialize: Background tasks not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// No-op on platforms that do not support background tasks.
  Future<void> schedulePeriodic({
    required String uniqueName,
    required String taskId,
    required Duration frequency,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
    ExistingWorkPolicy existingPolicy = ExistingWorkPolicy.keep,
  }) async {
    debugPrint(
      '[Primekit] TaskScheduler.schedulePeriodic: Background tasks not supported on this platform.',
    );
  }

  /// No-op on platforms that do not support background tasks.
  Future<void> scheduleOnce({
    required String uniqueName,
    required String taskId,
    Duration? initialDelay,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
  }) async {
    debugPrint(
      '[Primekit] TaskScheduler.scheduleOnce: Background tasks not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  /// No-op on platforms that do not support background tasks.
  Future<void> cancel(String uniqueName) async {
    debugPrint(
      '[Primekit] TaskScheduler.cancel: Background tasks not supported on this platform.',
    );
  }

  /// No-op on platforms that do not support background tasks.
  Future<void> cancelAll() async {
    debugPrint(
      '[Primekit] TaskScheduler.cancelAll: Background tasks not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Status query
  // ---------------------------------------------------------------------------

  /// Always returns `false` — background tasks are not available on this platform.
  Future<bool> isScheduled(String uniqueName) async => false;
}
