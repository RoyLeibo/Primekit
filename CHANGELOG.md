# Changelog

All notable changes to Primekit will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.1] — 2026-02-24

### Changed
- **Full cross-platform support** (Android · iOS · macOS · Windows · Linux · Web): removed platform-restricted packages from module barrels so every platform gets a clean import graph.
  - `primekit/notifications.dart`: `LocalNotifier` removed from barrel (imports directly via `primekit/src/notifications/local_notifier.dart`; `flutter_local_notifications` has Windows/Linux-only transitive sub-packages).
  - `primekit/permissions.dart`: `PermissionHelper`, `PermissionGate`, `PermissionFlow` removed from barrel (import directly; `permission_handler 12.x` does not declare macOS/Linux platform support).
  - `primekit/media.dart`: `ImageCompressor`, `ImageCropperService` removed from barrel (import directly; `flutter_image_compress` has no Windows/Linux support, `image_cropper` pulls in `dart:io` which blocks Web).
  - `primekit/device.dart`: `BiometricAuth` removed from barrel (import directly; `local_auth` has no Linux support).
  - `primekit/background.dart`: `TaskScheduler` removed from barrel (import directly; `workmanager` is Android/iOS only).
- **Social module Firebase decoupling**: extracted platform-agnostic abstract interfaces (`ActivityFeedSource`, `FollowDataSource`, `FollowService`) into `*_base.dart` files so the social barrel no longer pulls in `cloud_firestore` on all platforms.
- **`pubspec.yaml`**: updated `timezone` constraint to `'>=0.10.1 <0.12.0'` so pana sees the latest 0.11.x release as compatible.
- All dependencies upgraded to latest major versions.

### Fixed
- Static analysis: removed 3 unnecessary imports (`dart:typed_data`, `pk_permission.dart`) and fixed `curly_braces_in_flow_control_structures` lint in `permission_helper_web.dart`.
- Applied `dart format` to all files in `lib/`.

### Score
- pub.dev pana score: **160 / 160** (Follow conventions 30/30, Documentation 20/20, Platform support 20/20, Static analysis 50/50, Dependencies 40/40).

---

## [0.2.0] — 2026-02-22

### Added

**Realtime Module** (`primekit/realtime.dart`)
- `PkWebSocketChannel` — auto-reconnecting WebSocket with exponential backoff, ping/pong keepalive, and connect timeout
- `FirebaseRtdbChannel` — Firebase Realtime Database channel implementation
- `RealtimeManager` — multi-channel coordinator with named channel registry
- `PresenceService` — online/away/offline presence tracking with last-seen timestamps
- `MessageBuffer` — persistent offline message buffer backed by SharedPreferences with FIFO eviction
- `RealtimeChannel` — abstract interface for all channel implementations

**Crash Module** (`primekit/crash.dart`)
- `CrashReporter` — abstract crash reporting interface
- `FirebaseCrashReporter` — Firebase Crashlytics implementation
- `SentryCrashReporter` — Sentry Flutter implementation
- `MultiCrashReporter` — fan-out reporter dispatching to multiple backends
- `ErrorBoundary` — Flutter widget that catches render errors and reports them
- `CrashConfig` — global configuration (user info, custom keys, log limits)

**Feature Flags Module** (`primekit/flags.dart`)
- `FlagService` — feature flag resolution with caching and fallback
- `FlagProvider` — abstract provider interface
- `FirebaseFlagProvider` — Firebase Remote Config implementation
- `MongoFlagProvider` — MongoDB Atlas Data API implementation
- `LocalFlagProvider` — in-memory provider for tests and overrides
- `FlagCache` — TTL-based local flag cache with SharedPreferences persistence
- `FeatureFlag` — typed flag definition with default values

**Async State Module** (`primekit/async_state.dart`)
- `AsyncStateValue<T>` — sealed class: `IdleState`, `LoadingState`, `SuccessState`, `FailureState`
- `AsyncStateNotifier<T>` — ChangeNotifier wrapper for async operations with `execute()`
- `AsyncBuilder<T>` — widget that rebuilds for each async state with typed builders
- `PaginatedStateNotifier<T>` — paginated async state with page tracking and append-on-load

**Dependency Injection Module** (`primekit/di.dart`)
- `ServiceLocator` — singleton registry with lazy factories and eager singletons
- `PkServiceScope` — inherited widget providing a `ServiceLocator` to the widget tree
- `PkServiceScopeWidget` — root widget for scoped DI
- `Module` — abstract interface for grouping related registrations
- `Disposable` — mixin for services that need lifecycle cleanup

**Offline Sync Module** (`primekit/sync.dart`)
- `SyncRepository<T>` — generic offline-first repository with optimistic updates
- `SyncDataSource` — abstract local/remote data source interface
- `PendingChangeStore` — SharedPreferences-backed queue of unsynced operations
- `ConflictResolver` — pluggable conflict resolution (local-wins, remote-wins, merge)
- `SyncDocument<T>` — versioned document wrapper with `updatedAt` tracking
- `SyncState` — sealed sync status: idle, syncing, synced, conflict, error

**Media Module** (`primekit/media.dart`)
- `MediaPicker` — unified photo/video/file picker wrapping image_picker
- `ImageCompressor` — quality/size/dimension compression via flutter_image_compress
- `ImageCropperService` — interactive cropping via image_cropper
- `MediaUploader` — chunked upload with progress stream and cancellation
- `MediaFile` — typed value object (path, mime, size, dimensions)
- `UploadTask` — observable upload task with progress, pause, resume, cancel

**RBAC Module** (`primekit/rbac.dart`)
- `RbacService` — role resolution and permission checking
- `RbacPolicy` — declarative permission policy definition
- `RbacContext` — request context (user, resource, action)
- `RbacProvider` — abstract role/permission data source
- `RbacGate` — widget that conditionally renders based on permission check
- `PermissionDeniedWidget` — fallback widget for insufficient permissions

**Social Module** (`primekit/social.dart`)
- `FollowService` — follow/unfollow with follower/following count streams
- `ProfileService` — user profile CRUD with avatar and display name management
- `ActivityFeed` — paginated activity/notification feed
- `ActivityFeedSource` — abstract feed data source
- `ShareService` — native share sheet integration
- `SocialAuthProvider` — abstract interface for Google/Apple sign-in
- `UserProfile` — typed value object with copyWith

**Background Tasks Module** (`primekit/background.dart`)
- `TaskScheduler` — Workmanager-backed one-off and periodic task scheduler
- `TaskRegistry` — static callback dispatcher required by Workmanager
- `BackgroundTask` — typed task definition with constraints and payload
- `TaskResult` — success/failure/retry result type for background callbacks
- `CommonTasks` — pre-built task factories (sync, cache refresh, cleanup)

### Changed
- `pubspec.yaml`: bumped version to `0.2.0`; added `web_socket_channel`, `sentry_flutter`, `workmanager`, `image_picker`, `flutter_image_compress`, `image_cropper`, `google_sign_in` dependencies

### Fixed
- `Result.when()` pattern variable shadowing in `Failure` branch (`failure: final f`)
- `Result.asyncMap()` return type: removed `async`, wrapped failure branch in `Future.value()`
- `list_extensions.dart` `flattened` getter: added explicit type parameter `expand<T>` to fix `List<Object?>` inference
- `websocket_channel.dart`: `_closeSocket()` now fire-and-forgets `sink.close()` with timeout to prevent indefinite hang on unestablished sockets
- `websocket_channel.dart`: stale socket leaked when `ready.timeout()` threw; now captured, nulled, and abandoned immediately in the catch block

---

## [0.1.0] — 2026-02-19

### Added

**Core Infrastructure**
- `PrimekitConfig` — global initialization and configuration
- `Result<S, F>` — type-safe discriminated union for error handling
- `PrimekitException` hierarchy — typed exceptions for every module
- `PrimekitLogger` — structured internal logging respecting log levels
- Extension methods on `String`, `DateTime`, `List`, `Map`

**Analytics Module**
- `EventTracker` — singleton multi-provider analytics dispatcher
- `AnalyticsProvider` — abstract interface for custom providers
- `AnalyticsEvent` — typed events with factory constructors (screenView, purchase, signIn, etc.)
- `FunnelTracker` — multi-step conversion funnel tracking
- `SessionTracker` — session start/end, duration, session count
- `EventCounter` — persistent action counter with SharedPreferences backend

**Auth Module**
- `TokenStore` — secure JWT storage with expiry checking (flutter_secure_storage)
- `AuthInterceptor` — Dio interceptor with auto-refresh and session expiry handling
- `SessionManager` — ChangeNotifier-based auth state management
- `OtpService` — OTP generation, storage, validation with TTL and attempt limits
- `ProtectedRouteGuard` — go_router redirect guard for authenticated routes

**Billing Module**
- `ProductCatalog` — typed product registry with pricing metadata
- `SubscriptionManager` — active subscription queries and change streams
- `EntitlementChecker` — feature-to-product mapping with access checks
- `BillingEvent` — sealed class of billing lifecycle events
- `PaywallController` — ChangeNotifier paywall display manager with impression tracking
- `PricingFormatter` — locale-aware price, period, and savings formatting

**Ads Module**
- `AdManager` — central ad coordinator for banners, interstitials, and rewarded
- `AdUnitConfig` — typed ad unit IDs per platform with test IDs factory
- `AdCooldownTimer` — enforces minimum delay between interstitial shows
- `AdFrequencyCap` — per-session and per-day impression limits
- `AdEventLogger` — typed ad event tracking with CTR calculation
- `PkBannerAd` — drop-in banner widget with auto-load and error handling

**Membership Module**
- `MembershipTier` — typed tier system with level-based comparison
- `AccessPolicy` — declarative feature-to-tier mapping
- `TierGate` — widget that conditionally renders based on user tier
- `UpgradePrompt` — standardized CTA widget (card, banner, dialog, inline styles)
- `MembershipService` — ChangeNotifier membership state provider
- `MemberBadge` — visual tier badge widget
- `TrialManager` — trial period tracking with event stream

**Email Module**
- `EmailProvider` — abstract interface (SendGrid, Resend, SMTP implementations)
- `EmailService` — singleton email dispatcher
- `EmailMessage` / `EmailAttachment` — typed email composition
- `ContactFormMailer` — pre-built contact form email sender with HTML formatting
- `VerificationMailer` — OTP and verification link emails with HTML templates
- `EmailQueue` — persistent offline-resilient email queue with retry

**Storage Module**
- `SecurePrefs` — typed flutter_secure_storage wrapper
- `JsonCache` — TTL-based JSON cache with prefix invalidation
- `AppPreferences` — typed SharedPreferences for common app settings
- `MigrationRunner` — version-ordered data migrations
- `FileCache` — local file caching with LRU eviction

**Permissions Module**
- `PermissionGate` — widget that requests and gates on permission status
- `PermissionFlow` — multi-step permission request with rationale dialogs
- `PermissionHelper` — static helpers for common permission operations

**Forms Module**
- `PkSchema` — root schema builder (string, number, bool, object, list, date)
- `PkStringSchema` — string validation: email, URL, phone, length, pattern, credit card
- `PkNumberSchema` — numeric validation: min, max, positive, integer, multipleOf
- `PkObjectSchema` — composite object schema with field-level error reporting
- `ValidationResult` — immutable validation result with field error map
- `PkFormField` — Flutter form field backed by PkSchema with debounced validation
- `PkForm` — schema-driven form container with PkFormController

**Notifications Module**
- `LocalNotifier` — local notification scheduling and cancellation
- `PushHandler` — FCM/APNs push message handler with permission flow
- `InAppBanner` — slide-in in-app notification banner with auto-dismiss
- `NotificationChannel` — Android notification channel configuration

**Network Module**
- `ApiResponse<T>` — loading/success/failure sealed class
- `ConnectivityMonitor` — debounced connectivity stream
- `OfflineQueue` — queue-and-flush for offline-resilient API calls
- `RetryInterceptor` — Dio interceptor with exponential backoff
- `PrimekitNetworkClient` — pre-configured Dio wrapper with typed responses

**Device Module**
- `DeviceInfo` — cached device details (model, OS, screen, tablet detection)
- `AppVersion` — version info with semver comparison and store links
- `BiometricAuth` — Face ID / fingerprint authentication wrapper
- `ClipboardHelper` — copy/paste with automatic SnackBar feedback

**UI Module**
- `LoadingOverlay` — global loading overlay with `wrap<T>` convenience method
- `ToastService` — typed snackbars (success, error, warning, info)
- `ConfirmDialog` — standardized confirm/cancel dialog with destructive variant
- `SkeletonLoader` — shimmer skeleton for any widget with pre-built variants
- `EmptyState` — configurable empty state with pre-built variants
- `LazyList<T>` — infinite-scroll paginated list
- `AdaptiveScaffold` — responsive scaffold (bottom nav / side nav / rail)

**Routing Module**
- `RouteGuard` — composable go_router redirect guards
- `CompositeRouteGuard` — sequential guard composition
- `DeepLinkHandler` — URI pattern matching and go_router dispatch
- `NavigationLogger` — NavigatorObserver that logs route changes to analytics
- `TabStateManager` — per-tab scroll position preservation

**i18n Module**
- `LocaleManager` — ChangeNotifier locale storage with hot switching
- `PkDateFormatter` — locale-aware date formatting presets
- `PkCurrencyFormatter` — locale-aware currency formatting with compact notation
- `PluralHelper` — correct pluralization with locale support

---

[0.2.1]: https://github.com/RoyLeibo/Primekit/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/RoyLeibo/Primekit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/RoyLeibo/Primekit/releases/tag/v0.1.0
