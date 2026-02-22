import 'package:workmanager/workmanager.dart' as wm;

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'background_task.dart';
import 'task_registry.dart';

// ---------------------------------------------------------------------------
// ExistingWorkPolicy
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
// WorkManager top-level callback
// ---------------------------------------------------------------------------

/// Top-level callback registered with WorkManager.
///
/// Must be a free function (not a method) so it can be called on the
/// WorkManager background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  wm.Workmanager().executeTask(
    (String taskName, Map<String, dynamic>? inputData) =>
        TaskScheduler._dispatchTask(
      taskName: taskName,
      inputData: inputData ?? {},
    ),
  );
}

// ---------------------------------------------------------------------------
// TaskScheduler
// ---------------------------------------------------------------------------

/// Unified background task scheduler built on WorkManager.
///
/// Supports periodic and one-off tasks with typed constraints.
///
/// ### Setup
///
/// Call [initialize] in `main()` before [runApp]:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   TaskRegistry.registerBuiltIns();
///   TaskRegistry.register('com.example.sync', SyncTask.new);
///
///   await TaskScheduler.initialize(
///     taskRegistry: {'com.example.sync': SyncTask.new},
///     isInDebugMode: kDebugMode,
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

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialises the WorkManager plugin and registers the dispatch callback.
  ///
  /// [taskRegistry] maps task IDs to factory functions. Primekit built-in
  /// tasks can be pre-populated via [TaskRegistry.registerBuiltIns].
  ///
  /// Must be called once in `main()` before scheduling any tasks.
  static Future<void> initialize({
    required Map<String, BackgroundTask Function()> taskRegistry,
    bool isInDebugMode = false,
  }) async {
    for (final entry in taskRegistry.entries) {
      TaskRegistry.register(entry.key, entry.value);
    }

    await wm.Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: isInDebugMode,
    );

    _instance._initialized = true;
    PrimekitLogger.info('TaskScheduler initialised.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Schedules a periodic task.
  ///
  /// [uniqueName] identifies this scheduling slot — subsequent calls with the
  /// same name follow [existingPolicy].
  ///
  /// [frequency] has a platform minimum of 15 minutes on Android.
  Future<void> schedulePeriodic({
    required String uniqueName,
    required String taskId,
    required Duration frequency,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
    ExistingWorkPolicy existingPolicy = ExistingWorkPolicy.keep,
  }) async {
    _assertInitialized();
    try {
      await wm.Workmanager().registerPeriodicTask(
        uniqueName,
        taskId,
        frequency: frequency,
        inputData: inputData,
        constraints: _toConstraints(constraints),
        existingWorkPolicy: _toPolicy(existingPolicy),
      );
      PrimekitLogger.info(
        'Scheduled periodic task "$uniqueName" '
        '(every ${frequency.inMinutes}m).',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to schedule periodic task "$uniqueName".',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Schedules a one-off task.
  Future<void> scheduleOnce({
    required String uniqueName,
    required String taskId,
    Duration? initialDelay,
    Map<String, dynamic> inputData = const {},
    BackgroundConstraints constraints = const BackgroundConstraints(),
  }) async {
    _assertInitialized();
    try {
      await wm.Workmanager().registerOneOffTask(
        uniqueName,
        taskId,
        initialDelay: initialDelay ?? Duration.zero,
        inputData: inputData,
        constraints: _toConstraints(constraints),
      );
      PrimekitLogger.info(
        'Scheduled one-off task "$uniqueName".',
        tag: _tag,
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to schedule one-off task "$uniqueName".',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  /// Cancels the task registered under [uniqueName].
  Future<void> cancel(String uniqueName) async {
    _assertInitialized();
    await wm.Workmanager().cancelByUniqueName(uniqueName);
    PrimekitLogger.info('Cancelled task "$uniqueName".', tag: _tag);
  }

  /// Cancels all registered background tasks.
  Future<void> cancelAll() async {
    _assertInitialized();
    await wm.Workmanager().cancelAll();
    PrimekitLogger.info('All background tasks cancelled.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Status query (best-effort)
  // ---------------------------------------------------------------------------

  /// Returns `true` if a task with [uniqueName] is scheduled.
  ///
  /// Note: WorkManager does not expose a reliable cross-platform query API.
  /// This is a best-effort implementation that always returns `false` on
  /// platforms that do not support the query.
  Future<bool> isScheduled(String uniqueName) async => false;

  // ---------------------------------------------------------------------------
  // Static dispatch (called from top-level callback)
  // ---------------------------------------------------------------------------

  /// Dispatches execution to the registered [BackgroundTask] for [taskName].
  static Future<bool> _dispatchTask({
    required String taskName,
    required Map<String, dynamic> inputData,
  }) async {
    PrimekitLogger.info('Dispatching task: $taskName', tag: _tag);
    try {
      final task = TaskRegistry.resolve(taskName);
      if (task == null) {
        PrimekitLogger.warning(
          'Unknown task "$taskName" — returning false.',
          tag: _tag,
        );
        return false;
      }
      final success = await task.execute(inputData);
      PrimekitLogger.info(
        'Task "$taskName" completed: '
        '${success ? 'success' : 'failure'}.',
        tag: _tag,
      );
      return success;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Task "$taskName" threw an exception.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion helpers
  // ---------------------------------------------------------------------------

  wm.Constraints _toConstraints(BackgroundConstraints c) => wm.Constraints(
        networkType: switch (c.networkType) {
          NetworkType.notRequired => wm.NetworkType.not_required,
          NetworkType.connected => wm.NetworkType.connected,
          NetworkType.unmetered => wm.NetworkType.unmetered,
        },
        requiresCharging: c.requiresCharging,
        requiresDeviceIdle: c.requiresDeviceIdle,
      );

  wm.ExistingWorkPolicy _toPolicy(ExistingWorkPolicy policy) =>
      switch (policy) {
        ExistingWorkPolicy.replace => wm.ExistingWorkPolicy.replace,
        ExistingWorkPolicy.keep => wm.ExistingWorkPolicy.keep,
        ExistingWorkPolicy.append => wm.ExistingWorkPolicy.append,
      };

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
