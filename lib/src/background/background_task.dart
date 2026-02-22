/// Core types for Primekit background task scheduling.
///
/// Define tasks by implementing [BackgroundTask], configure them with
/// [TaskConfig], and register them with [TaskScheduler].
library;

// ---------------------------------------------------------------------------
// BackgroundTask
// ---------------------------------------------------------------------------

/// Contract for a background task that can be scheduled and executed.
///
/// Implement this interface and register your factory in [TaskRegistry]:
///
/// ```dart
/// class SyncTask implements BackgroundTask {
///   @override
///   String get taskId => 'com.example.sync';
///
///   @override
///   Future<bool> execute(Map<String, dynamic> inputData) async {
///     await DataService.instance.sync();
///     return true; // success
///   }
/// }
/// ```
abstract interface class BackgroundTask {
  /// A stable, unique identifier for this task type.
  ///
  /// Use reverse-domain notation, e.g. `'com.example.sync'`.
  /// Primekit built-in tasks use the `'primekit.'` prefix.
  String get taskId;

  /// Executes the task body with the given [inputData].
  ///
  /// - Return `true` — task completed successfully.
  /// - Return `false` — task failed; the system may retry it.
  /// - Throw — task failed critically; system may mark it as failed.
  Future<bool> execute(Map<String, dynamic> inputData);
}

// ---------------------------------------------------------------------------
// NetworkType
// ---------------------------------------------------------------------------

/// Network connectivity requirement for a background task.
enum NetworkType {
  /// No network requirement.
  notRequired,

  /// Any active network connection.
  connected,

  /// An unmetered (Wi-Fi) connection.
  unmetered,
}

// ---------------------------------------------------------------------------
// BackgroundConstraints
// ---------------------------------------------------------------------------

/// Execution constraints that must be satisfied before a task runs.
final class BackgroundConstraints {
  /// Creates a set of background execution constraints.
  const BackgroundConstraints({
    this.networkType = NetworkType.notRequired,
    this.requiresCharging = false,
    this.requiresDeviceIdle = false,
  });

  /// Required network state before the task may run.
  final NetworkType networkType;

  /// Whether the device must be plugged in before the task runs.
  final bool requiresCharging;

  /// Whether the device must be idle before the task runs.
  final bool requiresDeviceIdle;

  @override
  String toString() => 'BackgroundConstraints('
      'networkType: $networkType, '
      'requiresCharging: $requiresCharging, '
      'requiresDeviceIdle: $requiresDeviceIdle)';
}

// ---------------------------------------------------------------------------
// TaskConfig
// ---------------------------------------------------------------------------

/// Configuration for scheduling a single background task execution.
final class TaskConfig {
  /// Creates a task configuration.
  const TaskConfig({
    required this.taskId,
    this.initialDelay,
    this.constraints = const BackgroundConstraints(),
    this.inputData = const {},
    this.maxRetries,
  });

  /// The [BackgroundTask.taskId] of the task to run.
  final String taskId;

  /// Optional delay before the task first runs.
  final Duration? initialDelay;

  /// Execution constraints (network, charging, idle).
  final BackgroundConstraints constraints;

  /// Arbitrary key-value data passed to [BackgroundTask.execute].
  final Map<String, dynamic> inputData;

  /// Maximum number of retry attempts on failure. Platform-dependent when null.
  final int? maxRetries;

  @override
  String toString() => 'TaskConfig(taskId: $taskId, '
      'initialDelay: $initialDelay, '
      'constraints: $constraints)';
}
