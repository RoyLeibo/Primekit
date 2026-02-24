// Conditional export router for [TaskScheduler].
//
// - On platforms with `dart:io` (Android, iOS, macOS, Windows, Linux):
//   the full WorkManager-backed implementation is used.
// - On Web and other platforms without `dart:io`:
//   a no-op stub is used that logs warnings for all scheduling calls.
//
// To use Firebase-backed scheduling or custom schedulers, import the
// concrete file directly.
export 'task_scheduler_stub.dart'
    if (dart.library.io) 'task_scheduler_mobile.dart';
