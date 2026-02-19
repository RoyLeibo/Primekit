# 🚀 Primekit

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

---

## ✨ Modules

| Module | Description | Import |
|--------|-------------|--------|
| 📊 **Analytics** | Multi-provider event tracking, funnels, sessions | `primekit/analytics.dart` |
| 🔐 **Auth** | Token store, interceptors, session manager | `primekit/auth.dart` |
| 💳 **Billing** | Subscriptions, entitlements, paywall, pricing | `primekit/billing.dart` |
| 📢 **Ads** | AdManager, banners, interstitials, rewarded | `primekit/ads.dart` |
| 👑 **Membership** | Tier system, TierGate widget, upgrade prompts | `primekit/membership.dart` |
| 📧 **Email** | Contact forms, verification, queued sending | `primekit/email.dart` |
| 💾 **Storage** | Encrypted prefs, TTL cache, migrations | `primekit/storage.dart` |
| 🔒 **Permissions** | PermissionGate widget, rationale flows | `primekit/permissions.dart` |
| 📋 **Forms** | Zod-like schema validation for Dart | `primekit/forms.dart` |
| 🔔 **Notifications** | Local, push, and in-app messaging | `primekit/notifications.dart` |
| 🌐 **Network** | Connectivity monitor, offline queue, typed responses | `primekit/network.dart` |
| 📱 **Device** | Device info, biometrics, version checks | `primekit/device.dart` |
| 🎨 **UI** | Loaders, toasts, skeletons, adaptive scaffold | `primekit/ui.dart` |
| 🗺️ **Routing** | Deep links, composable guards, navigation logging | `primekit/routing.dart` |
| 🌍 **i18n** | Locale manager, date/currency formatters | `primekit/i18n.dart` |

---

## 📦 Installation

```yaml
dependencies:
  primekit: ^0.1.0
```

```bash
flutter pub add primekit
```

---

## ⚡ Quick Start

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

## 📚 Module Documentation

### 📊 Analytics — Multi-provider event tracking

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

### 🔐 Auth — Token management & session

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

### 💳 Billing — Subscriptions & entitlements

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

### 📋 Forms — Zod-like schema validation

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

### 👑 Membership — Tier gating made trivial

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

### 💾 Storage — Typed, encrypted, cached

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

### 🌐 Network — Typed responses & offline support

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

### 🎨 UI — Drop-in components

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

### 📧 Email — Send transactional emails

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

## 🏗️ Architecture

Primekit follows **Clean Architecture** principles:

```
lib/
├── primekit.dart          ← Full library import
├── src/
│   ├── core/              ← Shared: Result<S,F>, exceptions, logger, extensions
│   ├── analytics/         ← EventTracker, FunnelTracker, SessionTracker
│   ├── auth/              ← TokenStore, AuthInterceptor, SessionManager
│   ├── billing/           ← EntitlementChecker, SubscriptionManager, Paywall
│   ├── ads/               ← AdManager, BannerAd, Cooldown, FrequencyCap
│   ├── membership/        ← MembershipTier, TierGate, UpgradePrompt
│   ├── email/             ← EmailService, ContactFormMailer, VerificationMailer
│   ├── storage/           ← SecurePrefs, JsonCache, AppPreferences, Migrations
│   ├── permissions/       ← PermissionGate, PermissionFlow, PermissionHelper
│   ├── forms/             ← PkSchema, PkForm, PkFormField, ValidationResult
│   ├── notifications/     ← LocalNotifier, PushHandler, InAppBanner
│   ├── network/           ← PrimekitNetworkClient, ApiResponse<T>, OfflineQueue
│   ├── device/            ← DeviceInfo, AppVersion, BiometricAuth
│   ├── ui/                ← LoadingOverlay, ToastService, SkeletonLoader
│   ├── routing/           ← RouteGuard, DeepLinkHandler, NavigationLogger
│   └── i18n/              ← LocaleManager, PkDateFormatter, PkCurrencyFormatter
```

### Design Principles

- **Immutable by default** — all data classes are immutable with `copyWith`
- **Result pattern** — no uncaught exceptions; all errors are typed `Result<S, F>`
- **Provider-agnostic** — analytics, email, billing all use abstract providers
- **Modular imports** — import only what you use for tree-shaking
- **Null-safe** — full Dart 3 null safety throughout
- **Testable** — every class is injectable and mockable

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific module
flutter test test/analytics/
flutter test test/forms/
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

## 🗺️ Roadmap

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Coming in v0.2.0:**
- `RevenueCatBillingProvider` — full RevenueCat integration
- `FirebaseAnalyticsProvider` — bundled Firebase provider
- `MixpanelProvider` — bundled Mixpanel provider
- `primekit_cli` — code generation CLI for scaffolding modules
- Riverpod integration helpers
- BLoC integration helpers
