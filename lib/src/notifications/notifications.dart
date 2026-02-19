/// Notifications — local notifications, push messaging, and in-app banners
/// for Flutter applications.
///
/// Three subsystems:
///
/// 1. **[LocalNotifier]** — Immediate and scheduled local notifications
///    via `flutter_local_notifications` (in pubspec).
///
/// 2. **[PushHandler]** — FCM/APNs push message handling
///    via `firebase_messaging` (optional dependency, see push_handler.dart).
///
/// 3. **[InAppBanner] / [InAppBannerService]** — Non-intrusive overlay
///    banners that slide in from the top or bottom, no extra dependency.
///
/// ## Quick-start
///
/// ```dart
/// // Local notifications:
/// await LocalNotifier.instance.initialize();
/// await LocalNotifier.instance.show(id: 1, title: 'Hi', body: 'Hello!');
/// LocalNotifier.instance.onTap.listen((tap) => navigate(tap.payload));
///
/// // Push notifications (requires firebase_messaging):
/// await PushHandler.instance.initialize(
///   onMessage: (msg) => InAppBannerService.show(
///     context,
///     InAppBannerConfig(message: msg.body ?? ''),
///   ),
///   onMessageOpenedApp: (msg) => navigate(msg.data['route']),
/// );
/// final token = await PushHandler.instance.getToken();
///
/// // In-app banners:
/// InAppBannerService.show(
///   context,
///   const InAppBannerConfig(
///     title: 'Update available',
///     message: 'A new version of the app is ready.',
///     icon: Icons.system_update_outlined,
///     position: InAppBannerPosition.top,
///   ),
/// );
/// ```
library primekit_notifications;

export 'in_app_banner.dart';
export 'local_notifier.dart';
export 'notification_channel.dart';
export 'push_handler.dart';
