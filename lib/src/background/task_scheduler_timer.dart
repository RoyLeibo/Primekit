import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'background_task.dart';
import 'task_registry.dart';

// ---------------------------------------------------------------------------
// ExistingWorkPolicy  (mirrors the mobile implementation)
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
// callbackDispatcher  (no-op — no WorkManager on desktop)
// ---------------------------------------------------------------------------

/// Top-level callback stub for platforms that do not support WorkManager.
///
/// Exists only to keep the API compatible with the mobile implementation.
@pragma('vm:entry-point')
void callbackDispatcher() {
  debugPrint(
    '[Primekit] callbackDispatcher: '
    'Timer-based scheduler does not use WorkManager.',
  );
}

// ---------------------------------------------------------------------------
// TaskScheduler
// ---------------------------------------------------------------------------

/// In-process background task scheduler backed by [Timer].
///
/// This implementation runs tasks inside the app process using Dart timers,
/// making it suitable for macOS, Windows, and Linux where WorkManager is
/// unavailable. Tasks survive app foreground/background transitions on
/// desktop but are cancelled when the process exits.
///
/// On Android and iOS, prefer importing [task_scheduler_mobile.dart] directly
/// to get true OS-managed background execution via WorkManager.
///
/// ### Setup
///
/// Call [initialize] in `main()` before [runApp]:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await TaskScheduler.initialize(
///     taskRegistry: {'com.example.sync': SyncTask.new},
///   );
///   runApp(const MyApp());
/// }
/// ```
final class TaskScheduler {
  TaskScheduler._();

  static final TaskScheduler _instance = TaskScheduler._();

  /// The shared singleton instance.
  static TaskScheduler get instance => _instance;

  static const String _tag = 'TaskScheduler';

  bool _initialized = false;
  final Map<String, Timer> _timers = {};

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Registers [taskRegistry] factories and marks the scheduler as ready.
  ///
  /// Must be called once in `main()` before scheduling any tasks.
  static Future<void> initialize({
    required Map<String, BackgroundTask Function()> taskRegistry,
    bool isInDebugMode = false,
  }) async {
    for (final entry in taskRegistry.entries) {
      TaskRegistry.register(entry.key, entry.value);
    }
    _instance._initialized = true;
    PrimekitLogger.info('TaskScheduler (Timer) initialised.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Schedules a periodic task that runs on [frequency] using [Timer.periodic].
  ///
  /// [uniqueName] identifies this scheduling slot — subsequent calls follow
  /// [existingPolicy].
  Future<void> schedulePeriodic({
    required String uniqueName,
    required String taskId,
    required Duration frequency,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
    ExistingWorkPolicy existingPolicy = ExistingWorkPolicy.keep,
  }) async {
    _assertInitialized();

    if (_timers.containsKey(uniqueName)) {
      if (existingPolicy == ExistingWorkPolicy.keep) {
        PrimekitLogger.verbose(
          'Periodic task "$uniqueName" already scheduled; keeping.',
          tag: _tag,
        );
        return;
      }
      _timers.remove(uniqueName)?.cancel();
    }

    final timer = Timer.periodic(frequency, (_) {
      _executeTask(taskId: taskId, inputData: inputData);
    });
    _timers[uniqueName] = timer;
    PrimekitLogger.info(
      'Scheduled periodic task "$uniqueName" '
      '(every ${frequency.inSeconds}s).',
      tag: _tag,
    );
  }

  /// Schedules a one-off task after an optional [initialDelay].
  Future<void> scheduleOnce({
    required String uniqueName,
    required String taskId,
    Duration? initialDelay,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
  }) async {
    _assertInitialized();
    _timers.remove(uniqueName)?.cancel();

    final delay = initialDelay ?? Duration.zero;
    final timer = Timer(delay, () {
      _timers.remove(uniqueName);
      _executeTask(taskId: taskId, inputData: inputData);
    });
    _timers[uniqueName] = timer;
    PrimekitLogger.info(
      'Scheduled one-off task "$uniqueName" (delay: ${delay.inSeconds}s).',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  /// Cancels the task registered under [uniqueName].
  Future<void> cancel(String uniqueName) async {
    _assertInitialized();
    _timers.remove(uniqueName)?.cancel();
    PrimekitLogger.info('Cancelled task "$uniqueName".', tag: _tag);
  }

  /// Cancels all scheduled tasks.
  Future<void> cancelAll() async {
    _assertInitialized();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    PrimekitLogger.info('All background tasks cancelled.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Status query
  // ---------------------------------------------------------------------------

  /// Returns `true` if a periodic or one-off task is active under [uniqueName].
  Future<bool> isScheduled(String uniqueName) async =>
      _timers[uniqueName]?.isActive ?? false;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<void> _executeTask({
    required String taskId,
    required Map<String, dynamic> inputData,
  }) async {
    PrimekitLogger.info('Executing task: $taskId', tag: _tag);
    try {
      final task = TaskRegistry.resolve(taskId);
      if (task == null) {
        PrimekitLogger.warning('Unknown task "$taskId" — skipping.', tag: _tag);
        return;
      }
      final success = await task.execute(inputData);
      PrimekitLogger.info(
        'Task "$taskId" completed: ${success ? "success" : "failure"}.',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Task "$taskId" threw an exception.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw const ConfigurationException(
        message:
            'TaskScheduler.initialize() must be called before '
            'scheduling tasks.',
      );
    }
  }
}
