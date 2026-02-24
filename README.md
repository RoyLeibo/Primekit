# Primekit

> A modular developer toolkit for Flutter applications. Eliminate boilerplate, ship faster.

[![pub version](https://img.shields.io/pub/v/primekit.svg)](https://pub.dev/packages/primekit)
[![pub points](https://img.shields.io/pub/points/primekit)](https://pub.dev/packages/primekit)
[![license](https://img.shields.io/github/license/RoyLeibo/Primekit)](LICENSE)
[![CI](https://github.com/RoyLeibo/Primekit/actions/workflows/ci.yml/badge.svg)](https://github.com/RoyLeibo/Primekit/actions)
[![codecov](https://codecov.io/gh/RoyLeibo/Primekit/branch/main/graph/badge.svg)](https://codecov.io/gh/RoyLeibo/Primekit)

Primekit is a production-grade, modular toolkit that gives every Flutter app a solid infrastructure
foundation from day one. Instead of wiring up the same analytics tracking, auth token management,
billing entitlements, form validation, and UI patterns for every new project — import Primekit and
start building features.

**25 modules. 933 tests. Zero boilerplate.**

---

## Modules

| Module | Description | Import |
|--------|-------------|--------|
| **Analytics** | Multi-provider event tracking, funnels, sessions | `primekit/analytics.dart` |
| **Auth** | Token store, interceptors, session manager | `primekit/auth.dart` |
| **Billing** | Subscriptions, entitlements, paywall, pricing | `primekit/billing.dart` |
| **Ads** | AdManager, banners, interstitials, rewarded | `primekit/ads.dart` |
| **Membership** | Tier system, TierGate widget, upgrade prompts | `primekit/membership.dart` |
| **Email** | Contact forms, verification, queued sending | `primekit/email.dart` |
| **Storage** | Encrypted prefs, TTL cache, migrations | `primekit/storage.dart` |
| **Permissions** | PermissionGate widget, rationale flows | `primekit/permissions.dart` |
| **Forms** | Zod-like schema validation for Dart | `primekit/forms.dart` |
| **Notifications** | Local, push, and in-app messaging | `primekit/notifications.dart` |
| **Network** | Connectivity monitor, offline queue, typed responses | `primekit/network.dart` |
| **Device** | Device info, biometrics, version checks | `primekit/device.dart` |
| **UI** | Loaders, toasts, skeletons, adaptive scaffold | `primekit/ui.dart` |
| **Routing** | Deep links, composable guards, navigation logging | `primekit/routing.dart` |
| **i18n** | Locale manager, date/currency formatters | `primekit/i18n.dart` |
| **Realtime** | WebSocket channels, presence, buffered messaging | `primekit/realtime.dart` |
| **Crash** | Crashlytics, Sentry, error boundaries, multi-reporter | `primekit/crash.dart` |
| **Flags** | Feature flags with Firebase, MongoDB, local providers | `primekit/flags.dart` |
| **Async State** | AsyncStateNotifier, AsyncBuilder, pagination | `primekit/async_state.dart` |
| **DI** | Lightweight dependency injection and service locator | `primekit/di.dart` |
| **Sync** | Offline-first sync with conflict resolution | `primekit/sync.dart` |
| **Media** | Image picker, compressor, cropper, upload | `primekit/media.dart` |
| **RBAC** | Role-based access control with policy evaluation | `primekit/rbac.dart` |
| **Social** | Follow, profiles, activity feed, sharing | `primekit/social.dart` |
| **Background** | Workmanager-based background task scheduling | `primekit/background.dart` |

---

## Platform Support

Primekit is a multi-module toolkit — platform support varies by module. Most modules target
**Android and iOS** (the primary mobile platforms), with many supporting all six Flutter targets.

| Module | Android | iOS | Web | macOS | Windows | Linux |
|--------|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
| **Async State** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **DI** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Forms** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **RBAC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Membership** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **i18n** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **UI** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Routing** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Network** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Analytics** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Email** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Storage** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Auth** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Crash** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Flags** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Realtime** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Sync** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Social** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Notifications** | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Device** | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Media** | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ |
| **Billing** | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| **Permissions** | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ |
| **Background** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Ads** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

**Legend:** ✅ Full support · ⚠️ Partial · ❌ Not supported

**Notes:**
- **Firebase modules** (Auth, Crash, Flags, Realtime, Social, Sync) don't support Windows or Linux — [Firebase SDK limitation](https://firebase.google.com/docs/flutter/setup).
- **Media** — picking and cropping work on Web; image compression (`flutter_image_compress`) does not.
- **Permissions** — `permission_handler` has limited macOS coverage (camera, microphone only).
- **Background** — `workmanager` supports Android and iOS only; no desktop or web background execution.
- **Ads** — Google Mobile Ads SDK targets Android and iOS only.

---

## Installation

```yaml
dependencies:
  primekit: ^0.2.0
```

```bash
flutter pub add primekit
```

---

## Quick Start

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrimekitConfig.initialize(
    environment: PrimekitEnvironment.production,
  );

  runApp(const MyApp());
}
```

---

## Module Documentation

### Analytics — Multi-provider event tracking

Log once, dispatch to any provider (Firebase, Mixpanel, Amplitude, PostHog, custom).

```dart
// Configure once
EventTracker.instance.configure(providers: [
  FirebaseAnalyticsProvider(),
  MixpanelProvider(token: 'YOUR_TOKEN'),
]);

// Log anywhere
EventTracker.instance.logEvent(
  AnalyticsEvent.purchase(
    amount: 9.99,
    currency: 'USD',
    productId: 'pro_monthly',
  ),
);

// Track funnels
FunnelTracker.instance.startFunnel('onboarding');
FunnelTracker.instance.completeStep('onboarding', 'profile_created');
FunnelTracker.instance.completeStep('onboarding', 'payment_added');
```

---

### Auth — Token management & session

```dart
// Configure
final authInterceptor = AuthInterceptor(
  tokenStore: TokenStore.instance,
  onRefresh: (refreshToken) async {
    final response = await authApi.refresh(refreshToken);
    return response.accessToken;
  },
  onSessionExpired: () => navigateToLogin(),
);

// Check auth state
SessionManager.instance.isAuthenticated; // bool

// Login
await SessionManager.instance.login(
  accessToken: tokens.access,
  refreshToken: tokens.refresh,
);

// go_router guard
GoRouter(
  redirect: ProtectedRouteGuard(
    sessionManager: SessionManager.instance,
  ).redirect,
);
```

---

### Billing — Subscriptions & entitlements

```dart
// Check access (replaces switch/if chains everywhere)
final canSync = await EntitlementChecker.instance.canAccess('cloud_sync');

if (!canSync) {
  PaywallController.instance.show(featureName: 'cloud_sync');
}

// Get subscription info
final sub = await SubscriptionManager.instance.getActiveSubscriptions();
sub.first.status; // SubscriptionStatus.active
sub.first.daysUntilExpiry; // Duration
```

---

### Forms — Zod-like schema validation

The missing schema validation library for Dart. Define once, validate everywhere.

```dart
// Define a schema
final loginSchema = PkSchema.object({
  'email':    PkSchema.string().email().required(),
  'password': PkSchema.string().minLength(8).required(),
});

// Validate form data
final result = loginSchema.validate(formData);
result.isValid;           // bool
result.errors;            // {'email': 'Invalid email address'}
result.errorFor('email'); // 'Invalid email address'

// Use in Flutter forms
PkForm(
  schema: loginSchema,
  builder: (controller) => Column(children: [
    PkFormField(schema: loginSchema.field('email'), fieldName: 'email'),
    PkFormField(schema: loginSchema.field('password'), fieldName: 'password'),
    ElevatedButton(onPressed: controller.submit, child: const Text('Login')),
  ]),
  onSubmit: (values) async => await authService.login(values),
);
```

---

### Membership — Tier gating made trivial

```dart
// Gate any widget by membership tier
TierGate(
  requires: MembershipTier.pro,
  fallback: UpgradePrompt(targetTier: MembershipTier.pro),
  child: const ExportToPdfButton(),
);

// Programmatic check
if (MembershipService.instance.currentTier.isAtLeast(MembershipTier.pro)) {
  // unlock feature
}
```

---

### Storage — Typed, encrypted, cached

```dart
// Secure encrypted storage
await SecurePrefs.instance.setString('api_key', 'secret');
final key = await SecurePrefs.instance.getString('api_key');

// TTL cache
await JsonCache.instance.set(
  'user_profile',
  userJson,
  ttl: const Duration(hours: 1),
);
final cached = await JsonCache.instance.get('user_profile'); // null if expired
```

---

### Network — Typed responses & offline support

```dart
// Typed API responses
final client = PrimekitNetworkClient(baseUrl: 'https://api.example.com');

final response = await client.get<User>(
  '/users/me',
  parser: User.fromJson,
);

response.when(
  loading: () => showSpinner(),
  success: (user) => showProfile(user),
  failure: (error) => showError(error.userMessage),
);

// Offline queue — requests survive no-connectivity periods
await OfflineQueue.instance.enqueue(QueuedRequest(
  method: 'POST',
  url: '/analytics/events',
  body: eventPayload,
));
```

---

### Realtime — WebSocket channels & presence

```dart
// Open a channel
final channel = PkWebSocketChannel(
  uri: Uri.parse('wss://api.example.com/socket'),
  channelId: 'room-42',
);
await channel.connect();

// Listen for messages
channel.messages.listen((msg) {
  print('${msg.type}: ${msg.payload}');
});

// Send (buffered while offline, replayed on reconnect)
await channel.send({'text': 'hello'}, type: 'chat');

// Presence
await PresenceService.instance.setOnline(userId: 'user-1');
PresenceService.instance.watchPresence('user-2').listen((status) {
  print('user-2 is $status');
});
```

---

### Crash — Multi-provider crash reporting

```dart
// Configure once
CrashReporter.configure(
  MultiCrashReporter([
    FirebaseCrashReporter(),
    SentryCrashReporter(dsn: Env.sentryDsn),
  ]),
);

// Report anywhere
await CrashReporter.instance.recordError(
  error,
  stackTrace,
  reason: 'Payment processing failed',
);

// Wrap risky widgets
ErrorBoundary(
  onError: (error, stack) => CrashReporter.instance.recordError(error, stack),
  fallback: const ErrorFallbackWidget(),
  child: const PaymentScreen(),
);
```

---

### Flags — Feature flags with remote providers

```dart
// Configure
FlagService.instance.configure(
  provider: FirebaseFlagProvider(),
  cache: FlagCache(ttl: const Duration(minutes: 5)),
);

// Check a flag
final showNewCheckout = await FlagService.instance.getBool(
  'new_checkout_flow',
  defaultValue: false,
);

// Override locally (great for testing)
FlagService.instance.configure(
  provider: LocalFlagProvider({'dark_mode': true, 'beta_ui': false}),
);
```

---

### Async State — Unified loading/error/success state

```dart
// Notifier
class UserNotifier extends AsyncStateNotifier<User> {
  Future<void> load(String id) => execute(() => userRepo.findById(id));
}

// Widget
AsyncBuilder<User>(
  notifier: context.read<UserNotifier>(),
  onLoading: () => const CircularProgressIndicator(),
  onSuccess: (user) => UserCard(user: user),
  onFailure: (error) => ErrorView(error: error),
);
```

---

### DI — Lightweight service locator

```dart
// Register
final locator = ServiceLocator()
  ..registerSingleton<AuthService>(() => FirebaseAuthService())
  ..registerLazy<UserRepo>(() => UserRepo(locator.get<AuthService>()));

// Resolve
final auth = locator.get<AuthService>();

// Scoped (via widget tree)
PkServiceScopeWidget(
  locator: locator,
  child: const MyApp(),
);

// Access in widgets
final auth = PkServiceScope.of(context).get<AuthService>();
```

---

### Sync — Offline-first with conflict resolution

```dart
final repo = SyncRepository<Note>(
  local: HiveNoteSource(),
  remote: ApiNoteSource(),
  conflictResolver: ConflictResolver.lastWriteWins(),
);

// Works offline — changes queued and synced when online
await repo.save(note);
await repo.sync(); // flush pending changes to remote
```

---

### Media — Pick, compress, upload

```dart
// Pick from gallery
final file = await MediaPicker.pickImage(source: ImageSource.gallery);

// Compress
final compressed = await ImageCompressor.compress(
  file,
  maxWidth: 1080,
  quality: 85,
);

// Upload with progress
final task = MediaUploader.upload(compressed, destination: 'avatars/user-1.jpg');
task.progress.listen((pct) => setState(() => _progress = pct));
final url = await task.result;
```

---

### RBAC — Role-based access control

```dart
// Define a policy
final policy = RbacPolicy(rules: {
  'post:delete': {'admin', 'moderator'},
  'post:edit':   {'admin', 'moderator', 'author'},
  'post:view':   {'admin', 'moderator', 'author', 'reader'},
});

// Check in code
final allowed = await RbacService.instance.can(
  userId: currentUser.id,
  action: 'post:delete',
  resource: post.id,
);

// Gate in widgets
RbacGate(
  action: 'post:delete',
  resource: post.id,
  fallback: const SizedBox.shrink(),
  child: DeleteButton(onTap: () => deletePost(post)),
);
```

---

### Social — Follow, profiles, activity feed

```dart
// Follow / unfollow
await FollowService.instance.follow(targetUserId: 'user-abc');
await FollowService.instance.unfollow(targetUserId: 'user-abc');

// Profile
final profile = await ProfileService.instance.getProfile('user-abc');
await ProfileService.instance.updateDisplayName('Jane Doe');

// Activity feed (paginated)
final feed = ActivityFeed(source: FirebaseActivityFeedSource());
final page = await feed.loadNextPage();
```

---

### Background — Scheduled background tasks

```dart
// Register task handlers (call once at app start)
TaskRegistry.registerAll({
  'sync_data': (payload) async {
    await SyncRepository.instance.sync();
    return TaskResult.success();
  },
});

// Schedule periodic sync
await TaskScheduler.instance.schedulePeriodic(
  BackgroundTask(
    name: 'sync_data',
    frequency: const Duration(hours: 1),
    constraints: TaskConstraints(requiresNetwork: true),
  ),
);
```

---

### UI — Drop-in components

```dart
// Loading overlay
LoadingOverlay.show(context, message: 'Saving...');
final result = await saveData();
LoadingOverlay.hide(context);

// Or wrap a future
final data = await LoadingOverlay.wrap(context, fetchData());

// Typed toasts
ToastService.success(context, 'Profile saved!');
ToastService.error(context, 'Upload failed. Try again.');

// Skeleton loading
SkeletonLoader(
  isLoading: isLoading,
  child: UserCard(user: user),
);

// Confirm dialog
final confirmed = await ConfirmDialog.show(
  context,
  title: 'Delete Account?',
  message: 'This cannot be undone.',
  isDestructive: true,
);
```

---

### Email — Send transactional emails

```dart
// Configure once
EmailService.instance.configure(
  provider: SendGridProvider(
    apiKey: Env.sendgridKey,
    fromEmail: 'hello@myapp.com',
  ),
);

// Contact form
final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
await mailer.send(
  senderName: 'Jane Doe',
  senderEmail: 'jane@example.com',
  message: 'I love this app!',
);

// Verification email
final verifier = VerificationMailer(fromEmail: 'noreply@myapp.com', appName: 'MyApp');
await verifier.sendOtp(toEmail: 'user@example.com', otp: '847291');
```

---

## Architecture

Primekit follows **Clean Architecture** principles:

```
lib/
├── primekit.dart          ← Full library import
├── src/
│   ├── core/              ← Shared: Result<S,F>, exceptions, logger, extensions
│   ├── analytics/         ← EventTracker, FunnelTracker, SessionTracker
│   ├── async_state/       ← AsyncStateNotifier, AsyncBuilder, PaginatedStateNotifier
│   ├── auth/              ← TokenStore, AuthInterceptor, SessionManager
│   ├── ads/               ← AdManager, BannerAd, Cooldown, FrequencyCap
│   ├── background/        ← TaskScheduler, TaskRegistry, CommonTasks
│   ├── billing/           ← EntitlementChecker, SubscriptionManager, Paywall
│   ├── crash/             ← CrashReporter (Firebase, Sentry), ErrorBoundary
│   ├── device/            ← DeviceInfo, AppVersion, BiometricAuth
│   ├── di/                ← ServiceLocator, PkServiceScope, Module
│   ├── email/             ← EmailService, ContactFormMailer, VerificationMailer
│   ├── flags/             ← FlagService, Firebase/Mongo/local providers
│   ├── forms/             ← PkSchema, PkForm, PkFormField, ValidationResult
│   ├── i18n/              ← LocaleManager, PkDateFormatter, PkCurrencyFormatter
│   ├── media/             ← MediaPicker, ImageCompressor, MediaUploader
│   ├── membership/        ← MembershipTier, TierGate, UpgradePrompt
│   ├── network/           ← PrimekitNetworkClient, ApiResponse<T>, OfflineQueue
│   ├── notifications/     ← LocalNotifier, PushHandler, InAppBanner
│   ├── permissions/       ← PermissionGate, PermissionFlow, PermissionHelper
│   ├── rbac/              ← RbacService, RbacPolicy, RbacGate
│   ├── realtime/          ← PkWebSocketChannel, RealtimeManager, PresenceService
│   ├── routing/           ← RouteGuard, DeepLinkHandler, NavigationLogger
│   ├── social/            ← FollowService, ProfileService, ActivityFeed
│   ├── storage/           ← SecurePrefs, JsonCache, AppPreferences, Migrations
│   ├── sync/              ← SyncRepository, ConflictResolver, PendingChangeStore
│   └── ui/                ← LoadingOverlay, ToastService, SkeletonLoader
```

### Design Principles

- **Immutable by default** — all data classes are immutable with `copyWith`
- **Result pattern** — no uncaught exceptions; all errors are typed `Result<S, F>`
- **Provider-agnostic** — analytics, email, billing, crash, flags all use abstract providers
- **Modular imports** — import only what you use for tree-shaking
- **Null-safe** — full Dart 3 null safety throughout
- **Testable** — every class is injectable and mockable

---

## Testing

```bash
# Run all tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific module
flutter test test/analytics/
flutter test test/realtime/
flutter test test/forms/
```

933 tests across 25 modules.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Roadmap

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Planned for v0.3.0:**
- `RevenueCatBillingProvider` — full RevenueCat integration
- `FirebaseAnalyticsProvider` — bundled Firebase Analytics provider
- `MixpanelProvider` — bundled Mixpanel provider
- `primekit_cli` — code generation CLI for scaffolding modules
- Riverpod integration helpers (`pkRef`, `pkProvider`)
- BLoC integration helpers
