# Primekit — Flutter Shared Library (v2.3.1)

Modular Flutter utility library. Each module is independently importable via `package:primekit/<module>.dart`. Firebase adapters live separately in `firebase.dart` and are NOT re-exported from module barrel files.

## Initialization (required in main() before any module use)

```dart
void main() async {
  await PrimekitConfig.initialize(environment: PrimekitEnvironment.production);
  await AppInitializer.init(options: DefaultFirebaseOptions.currentPlatform); // Firebase only

  ServiceLocator.instance
    ..registerModule(AuthModule())
    ..registerModule(NetworkModule());
  await ServiceLocator.instance.allReady(); // wait for async singletons

  await ServiceLocator.instance.get<SessionManager>().restoreSession();
  runApp(const MyApp());
}
```

## Architecture Patterns

| Pattern | Description |
|---------|-------------|
| **Barrel exports** | `lib/<module>.dart` → `lib/src/<module>/` |
| **Exceptions** | All throw `PrimekitException` subtypes (sealed, have `.userMessage`) |
| **DI** | `ServiceLocator` (get_it-like) + `DiModule` for grouping |
| **State** | Sealed classes: `Result<S,F>`, `AsyncState<T>`, `SessionState` |
| **Provider abstraction** | Abstract interfaces + swappable backends (Firebase / Mongo / HTTP) |
| **Immutability** | All value types `const`; operations return new objects |
| **Conditional exports** | Platform-specific code hidden via `dart.library.html` / `dart.library.io` |
| **Firebase isolation** | All Firebase impls importable via `firebase.dart`, never auto-exported |

## Module Map

| Module | Import | Purpose | Key Classes |
|--------|--------|---------|-------------|
| **core** | `core.dart` | Exceptions, Result type, config, logging | `PrimekitException`, `Result<S,F>`, `PrimekitConfig`, `PrimekitLogger` |
| **di** | `di.dart` | Service locator + lifecycle | `ServiceLocator`, `DiModule`, `ServiceScope`, `PkDisposable` |
| **async_state** | (via core) | Async loading/data/error state machine | `AsyncState<T>`, `AsyncStateNotifier<T>`, `AsyncBuilder`, `PaginatedState<T>` |
| **forms** | `forms.dart` | Schema-based validation (Zod-like fluent API) | `PkSchema`, `PkForm`, `PkFormController`, `ValidationResult` |
| **auth** | `auth.dart` | Session + token management + route guards | `SessionManager`, `SessionState`, `TokenStore`, `AuthInterceptor`, `ProtectedRouteGuard` |
| **network** | `network.dart` | HTTP client + retry + offline queue | `PrimekitNetworkClient`, `ConnectivityMonitor`, `OfflineQueue`, `RetryInterceptor` |
| **storage** | `storage.dart` | SharedPrefs, SecureStorage, Hive, migrations | `AppPreferences`, `SecurePrefs`, `JsonCache<T>`, `MigrationRunner` |
| **sync** | `sync.dart` | Offline-first repo + background sync | `SyncRepository<T>`, `SyncDataSource`, `ConflictResolver`, `SyncDocument<T>` |
| **notifications** | `notifications.dart` | Local + remote notifications + rule engine (platform-conditional) | `LocalNotifier`, `NotificationChannel`, `InAppBanner`, `RemoteNotificationPreferences`, `NotificationRule`, `NotificationRuleService`, `TypedNotificationPreferences` |
| **media** | `media.dart` | Image pick / compress / crop / upload | `MediaPicker`, `ImageCompressor`, `AvatarUploader`, `UploadTask` |
| **permissions** | `permissions.dart` | Platform permissions (platform-conditional) | `PkPermission`, `PermissionHelper`, `PermissionFlow`, `PermissionGate` |
| **rbac** | `rbac.dart` | Role-based access control + multi-user sharing | `RbacService`, `RbacPolicy`, `Permission`, `Role`, `RbacGate`, `PkSharingMixin`, `PkMember`, `PkShareRole`, `PkSharingConfig` |
| **flags** | `flags.dart` | Feature flags with caching | `FlagService`, `FeatureFlag`, `LocalFlagProvider`, `FirebaseFlagProvider` |
| **billing** | `billing.dart` | IAP + subscriptions | `SubscriptionManager`, `EntitlementChecker`, `PaywallController`, `PricingFormatter` |
| **membership** | `membership.dart` | Membership tiers + trials + feature access | `MembershipService`, `MembershipTier`, `TrialManager`, `TierGate`, `MemberBadge` |
| **analytics** | `analytics.dart` | Event tracking abstraction | `EventTracker`, `FunnelTracker`, `SessionTracker`, `AnalyticsProvider` |
| **audit** | `audit.dart` | Immutable append-only audit trail | `AuditLogService`, `AuditEvent`, `AuditQuery`, `FirestoreAuditBackend` |
| **crash** | `crash.dart` | Multi-backend crash reporting | `CrashReporter`, `SentryCrashReporter`, `MultiCrashReporter`, `ErrorBoundary` |
| **realtime** | `realtime.dart` | WebSocket + Firebase realtime channels | `RealtimeManager`, `RealtimeChannel`, `MessageBuffer`, `PresenceTypes` |
| **social** | `social.dart` | Activity feeds, follows, social auth | `ActivityFeed`, `FollowService`, `ProfileService`, `SocialAuthService`, `ShareService` |
| **email** | `email.dart` | Templated email + retry queue | `EmailService`, `EmailQueue`, `ContactFormMailer`, `VerificationMailer` |
| **background** | `background.dart` | Background tasks + scheduler (workmanager) | `TaskScheduler`, `BackgroundTask`, `TaskRegistry`, `callbackDispatcher` |
| **device** | `device.dart` | Device info, location, biometrics | `DeviceInfo`, `LocationService`, `BiometricAuth`, `AppVersion` |
| **contacts** | `contacts.dart` | Native contact picker | `ContactsPicker`, `PkContact` |
| **export** | `export.dart` | PDF building, CSV building, file sharing | `PkPdfBuilder`, `PkPdfSection`, `PkPdfTableConfig`, `PkPdfTableColumn`, `PkPdfPageConfig`, `PkCsvBuilder<T>`, `PkExportShare` |
| **scheduling** | `scheduling.dart` | Generic recurrence & schedule computation | `RecurrenceRule`, `RecurrenceMode`, `ScheduleTimeOfDay`, `ScheduleSlot`, `ScheduleCalculator` |
| **calendar** | `calendar.dart` | Calendar events + Google Calendar | `CalendarService`, `CalendarEvent`, `GoogleCalendarProvider` |
| **currency** | `currency.dart` | Currency conversion + cached rates | `CurrencyConverter`, `CurrencyCache`, `HttpCurrencyRateSource` |
| **invites** | `invites.dart` | Invite code generation + sharing UI + join form | `InviteCode`, `InviteShareSheet`, `InviteShareConfig`, `InviteJoinForm` |
| **i18n** | `i18n.dart` | Locale management + formatting | `LocaleManager`, `DateFormatter`, `CurrencyFormatter`, `PluralHelper` |
| **i18n_hebrew** | `i18n_hebrew.dart` | Hebrew calendar + Jewish holidays (OPTIONAL, not in primekit.dart) | `PkHebrewDateFormatter`, `PkJewishHolidayService`, `PkJewishHoliday`, `PkJewishHolidayCategory` |
| **design_system** | `design_system.dart` | Design tokens + shared themes | `PkAppTheme`, `PkAppThemeExtension`, `PkGradients`, `PkColorScheme`, `PkTypography`, `PkSpacing`, `PkRadius` |
| **ui** | `ui.dart` | General-purpose UI widgets | `AdaptiveScaffold`, `SkeletonLoader`, `EmptyState`, `LazyList`, `ToastService`, `ConfirmDialog`, `PkGlassCard`, `PkConfettiOverlay`, `PkProgressBar`, `StatusBadge`, `PkNumericStepper`, `PkItemPickerSheet`, `PkOnboardingFlow`, `PkScreenshotShareService` |
| **routing** | `routing.dart` | Route guards + deep links (go_router) | `RouteGuard`, `ProtectedRouteGuard`, `DeepLinkHandler`, `TabStateManager` |
| **speech** | `speech.dart` | Speech-to-text with mic permission handling | `PkSpeechService`, `PkSpeechResult`, `PkSpeechListenOptions`, `PkSpeechLocale`, `PkListeningDialog`, `SpeechException` |
| **ads** | `ads.dart` | Ad integration | See `lib/src/ads/` |
| **ai** | `ai.dart` | Multi-provider AI abstraction + quota metering | `AiService`, `OpenAiProvider`, `AnthropicProvider`, `AiQuotaService`, `AiQuotaConfig`, `AiQuotaSnapshot` |
| **riverpod** | `riverpod.dart` | Riverpod base classes + helpers | `PkAsyncNotifier`, `PkProviders`, `PkPaginationNotifier`, `PkThemeNotifier`, `pkThemeProvider` |
| **home_widget** | `home_widget.dart` | Home screen widget data bridge | `PkHomeWidgetService`, `PkWidgetData`, `PkWidgetName`, `HomeWidgetException` |
| **habits** | `habits.dart` | Habit tracking, streaks, heatmap widget | `PkHabit`, `PkHabitFrequency`, `PkHabitService`, `PkHabitStatistics`, `StreakCalculator`, `PkHabitHeatmap` |
| **statistics** | `statistics.dart` | Completion analytics, trends, productivity | `PkCompletionEvent`, `PkCreationEvent`, `PkStatsCalculator`, `PkStatsStore`, `SharedPrefsStatsStore` |
| **firebase** | `firebase.dart` | ALL Firebase adapters (not per-module) | `AppInitializer`, `FirebaseAuthInterceptor`, `FirestoreSyncSource`, `FirebaseFlagProvider`, `FirestoreHabitService` |

## What to Ignore

- `build/` — compiled artifacts
- `**/*.g.dart`, `**/*.freezed.dart` — generated, never edit
- `doc/` — generated API docs
- `example/` — standalone demo app (separate pubspec)
- `tool/` — build scripts

## Module Dependencies (key ones)

- `core` + `di` → no dependencies (foundational, import first)
- `auth` → depends on `storage` (SecurePrefs for tokens) + `network` (AuthInterceptor)
- `sync` → depends on `storage` (Hive) + `network`
- `firebase` → implements interfaces from: `auth`, `crash`, `media`, `sync`, `flags`, `rbac`, `social`, `currency`, `audit`, `realtime`
- `speech` → depends on `core` (exceptions, logger) + `permissions` (mic permission) + `speech_to_text` package
- `billing` / `membership` → depend on `core`
- `home_widget` → depends on `core` (exceptions, logger) + `home_widget` package
- `rbac` sharing mixin → depends on `core` + `cloud_firestore`

## Shared Library Contract

PrimeKit is the shared code foundation for ALL Flutter apps in leibo-apps (Splitly, PawTrack, best_todo_list, Bullseye-Mobile-App). Every generic, reusable feature belongs here — not in individual apps.

**Before adding code to an app:** check this Module Map. If PrimeKit already provides it, use it.
**Before adding code to PrimeKit:** ensure it's generic (not domain-specific to one app).

## Maintenance Rules

> When you modify Primekit, update ALL of the following:
> - Public API change in a module → update `lib/src/<module>/CLAUDE.md`
> - New module added → create `lib/src/<module>/CLAUDE.md` + add row to Module Map above
> - Cross-cutting pattern change → update Architecture Patterns table
> - Version bump → update title line
> - **ANY change** → update `leibo-apps/PRIMEKIT.md` (master tracker) integration matrix + feature list
> - Module consumers changed → update `leibo-apps/<app>/PRIMEKIT.md` for affected apps
