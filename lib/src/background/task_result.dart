/// Sealed result type for background task execution outcomes.
///
/// Use the factory constructors to create specific result variants:
///
/// ```dart
/// // In BackgroundTask.execute():
/// if (success) return const TaskResult.success();
/// if (canRetry) return const TaskResult.retry(reason: 'network unavailable');
/// return TaskResult.failure(error);
/// ```
sealed class TaskResult {
  const TaskResult._();

  /// The task completed successfully.
  const factory TaskResult.success() = TaskSuccess;

  /// The task failed transiently and should be retried.
  const factory TaskResult.retry({String? reason}) = TaskRetry;

  /// The task failed critically and should not be retried.
  const factory TaskResult.failure(Object error) = TaskFailure;
}

// ---------------------------------------------------------------------------
// Concrete variants
// ---------------------------------------------------------------------------

/// Indicates successful task completion.
final class TaskSuccess extends TaskResult {
  /// Creates a success result.
  const TaskSuccess() : super._();

  @override
  String toString() => 'TaskResult.success()';
}

/// Indicates a transient failure — the scheduler may retry the task.
final class TaskRetry extends TaskResult {
  /// Creates a retry result with an optional [reason] for logging.
  const TaskRetry({this.reason}) : super._();

  /// Optional human-readable reason for the retry request.
  final String? reason;

  @override
  String toString() => 'TaskResult.retry(reason: $reason)';
}

/// Indicates a critical failure — the task should not be retried.
final class TaskFailure extends TaskResult {
  /// Creates a failure result wrapping the given [error].
  const TaskFailure(this.error) : super._();

  /// The underlying error that caused the failure.
  final Object error;

  @override
  String toString() => 'TaskResult.failure($error)';
}
