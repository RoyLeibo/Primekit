export 'background_task.dart';
export 'common_tasks.dart';
export 'task_registry.dart';
export 'task_result.dart';

// task_scheduler.dart is NOT exported here — workmanager only declares
// Android/iOS support, blocking macOS/Windows/Linux platform analysis.
// Import directly: import 'package:primekit/src/background/task_scheduler.dart';
