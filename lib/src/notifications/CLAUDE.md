# notifications — Local & Remote Notifications + Rule Engine

**Purpose:** Cross-platform notification handling. Platform implementations are conditionally exported. Includes a rule engine for scheduling notifications relative to target times.

**Key exports:**
- `LocalNotifier` — abstract interface (auto-picks web/io/stub impl via conditional export)
- `NotificationChannel` — Android notification channel config
- `PendingNotification`, `NotificationTap` — value types
- `RemoteNotificationPreferences` — FCM topic/preference management
- `InAppBanner` — Flutter widget for in-app banner notifications
- `NotificationRule` — immutable rule: "X [timeUnit] before" a target time
- `NotificationTimeUnit` — enum: minutes, hours, days, weeks
- `NotificationRuleService` — pure-function scheduling engine (calculateNextNotificationTime, resetFiredStatus, markRuleFired, hasPendingRules)
- `NextNotificationResult` — result of next-notification calculation
- `NotificationPreferences` — string-key per-type preference (SharedPreferences)
- `TypedNotificationPreferences<T>` — generic enum-based per-type preferences
- `NotificationPreferencesStore` — abstract backend interface for remote preference storage

**Platform implementations (auto-selected, no manual import needed):**
- Web: Browser Notification API via `dart:js_interop`
- iOS/Android: `flutter_local_notifications` with scheduling
- Desktop/Other: No-op stub

**Dependencies:** flutter_local_notifications 21.0.0, timezone, web (conditional), shared_preferences

**Active usage:** PawTrack + best_todo_list use `NotificationRule` + `NotificationRuleService` for vaccine/med/todo/reminder scheduling. PawTrack uses `LocalNotifier` + `NotificationChannel` for delivery.

**Maintenance:** Update when new platform supported, notification API adds new methods, or rule engine gains new capabilities.
