// Conditional export router for [LocalNotifier].
//
// - On Web (`dart.library.html`): uses the browser Notification API
//   implementation via `dart:js_interop` and `package:web`.
// - On platforms with `dart:io` (Android, iOS, macOS): uses
//   `flutter_local_notifications` with full scheduling support.
// - On all other platforms (Windows, Linux): a no-op stub is used.
//
// Shared value types ([PendingNotification], [NotificationTap]) are
// defined in `notification_types.dart` and re-exported by every branch.
export 'local_notifier_stub.dart'
    if (dart.library.html) 'local_notifier_web.dart'
    if (dart.library.io) 'local_notifier_io.dart';
