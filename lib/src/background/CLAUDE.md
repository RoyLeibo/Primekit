# background — Background Tasks

**Purpose:** Scheduled and on-demand background work using workmanager.

**Key exports:**
- `TaskScheduler` — abstract interface for scheduling tasks
- `BackgroundTask` — base class for all tasks (implement `execute()`)
- `TaskRegistry` — discovery and registration of task handlers
- `TaskResult` — execution result (success/failure/retry)
- `CommonTasks` — built-in task implementations
- `callbackDispatcher` — entry point for background isolate; must be top-level function

**Pattern:**
```dart
// In main():
TaskScheduler.registerAll(TaskRegistry.tasks);

// Top-level (NOT inside a class):
@pragma('vm:entry-point')
void callbackDispatcher() => TaskScheduler.dispatch();
```

**Important:** Background tasks run in isolated context — avoid passing large objects in task input data.

**Dependencies:** workmanager

**Maintenance:** Update when new built-in task added or dispatcher pattern changes.
