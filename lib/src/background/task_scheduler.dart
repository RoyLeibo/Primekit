// Conditional export router for [TaskScheduler].
//
// - On platforms with `dart:io` (Android, iOS, macOS, Windows, Linux):
//   uses a Timer-based in-process scheduler that works on all six platforms.
//   On Android/iOS, consumers who need true OS-managed background execution
//   should import [task_scheduler_mobile.dart] directly.
// - On Web and other platforms without `dart:io`:
//   a no-op stub is used that logs warnings for all scheduling calls.
export 'task_scheduler_stub.dart'
    if (dart.library.io) 'task_scheduler_timer.dart';
