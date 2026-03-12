# notifications — Local & Remote Notifications

**Purpose:** Cross-platform notification handling. Platform implementations are conditionally exported.

**Key exports:**
- `LocalNotifier` — abstract interface (auto-picks web/io/stub impl via conditional export)
- `NotificationChannel` — Android notification channel config
- `PendingNotification`, `NotificationTap` — value types
- `RemoteNotificationPreferences` — FCM topic/preference management
- `InAppBanner` — Flutter widget for in-app banner notifications

**Platform implementations (auto-selected, no manual import needed):**
- Web: Browser Notification API via `dart:js_interop`
- iOS/Android: `flutter_local_notifications` with scheduling
- Desktop/Other: No-op stub

**Dependencies:** flutter_local_notifications 21.0.0, timezone, web (conditional)

**Active usage:** PawTrack uses `LocalNotifier` + `NotificationChannel` for vaccine/med reminders.

**Maintenance:** Update when new platform supported or notification API adds new methods.
