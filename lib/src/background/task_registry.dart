import '../core/logger.dart';
import 'background_task.dart';
import 'common_tasks.dart';

/// Global registry mapping [BackgroundTask.taskId] strings to factory
/// functions used by WorkManager's top-level dispatch callback.
///
/// All tasks must be registered before [TaskScheduler.initialize] is called.
/// Primekit built-in tasks are pre-registered via [registerBuiltIns].
///
/// ```dart
/// TaskRegistry.register('com.example.sync', SyncTask.new);
/// ```
abstract final class TaskRegistry {
  static const String _tag = 'TaskRegistry';

  /// Internal factory map.
  static final Map<String, BackgroundTask Function()> _registry = {};

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Registers a factory for [taskId].
  ///
  /// Overwrites any existing registration for the same [taskId].
  static void register(String taskId, BackgroundTask Function() factory) {
    _registry[taskId] = factory;
    PrimekitLogger.debug('Registered task: $taskId', tag: _tag);
  }

  /// Resolves [taskId] to a new [BackgroundTask] instance, or returns `null`
  /// if no factory has been registered for that identifier.
  static BackgroundTask? resolve(String taskId) {
    final factory = _registry[taskId];
    if (factory == null) {
      PrimekitLogger.warning(
        'No factory registered for taskId: $taskId',
        tag: _tag,
      );
      return null;
    }
    return factory();
  }

  // ---------------------------------------------------------------------------
  // Built-in registration
  // ---------------------------------------------------------------------------

  /// Pre-registers all Primekit built-in tasks.
  ///
  /// Call this once during app initialisation alongside your own registrations:
  ///
  /// ```dart
  /// TaskRegistry.registerBuiltIns();
  /// TaskRegistry.register('com.example.sync', SyncTask.new);
  /// ```
  static void registerBuiltIns() {
    register(NetworkSyncTask.id, NetworkSyncTask.new);
    register(CacheCleanupTask.id, CacheCleanupTask.new);
    register(EmailQueueFlushTask.id, EmailQueueFlushTask.new);
    PrimekitLogger.info('Built-in tasks registered.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Clears all registered factories. For use in tests only.
  static void clearForTesting() => _registry.clear();

  /// Returns a snapshot of all registered task IDs. For use in tests only.
  static List<String> get registeredIds =>
      List<String>.unmodifiable(_registry.keys);
}
