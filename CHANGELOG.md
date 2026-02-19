# Changelog

All notable changes to Primekit will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned for v0.2.0
- `RevenueCatBillingProvider` — bundled RevenueCat integration
- `FirebaseAnalyticsProvider` — bundled Firebase Analytics provider
- `MixpanelProvider` — bundled Mixpanel provider
- `primekit_cli` — code generation CLI
- Riverpod integration helpers (`pkRef`, `pkProvider`)
- BLoC integration helpers

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

[Unreleased]: https://github.com/RoyLeibo/Primekit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/RoyLeibo/Primekit/releases/tag/v0.1.0
