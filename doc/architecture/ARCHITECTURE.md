# Primekit Architecture

## Overview

Primekit is a modular infrastructure toolkit organized as a single pub.dev package with 15 independently importable modules. All modules share a thin core layer of primitives but have no dependencies on each other.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Your Flutter App                         │
├────────────┬────────────┬────────────┬────────────┬─────────────┤
│  Analytics │    Auth    │  Billing   │    Forms   │    UI       │
│  Ads       │  Storage   │  Membership│  Permissions│  Network   │
│  Email     │   Device   │  Routing   │    i18n    │ Notif.      │
├─────────────────────────────────────────────────────────────────┤
│                         Primekit Core                            │
│           Result<S,F> │ Exceptions │ Logger │ Extensions        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Independence

Each module:
- Has its own barrel file (`lib/src/<module>/<module>.dart`)
- Can be imported individually (`import 'package:primekit/<module>.dart'`)
- Has zero dependencies on other Primekit modules (only on Core)
- Has its own test suite under `test/<module>/`

This enables tree-shaking: if you only use `analytics` and `forms`, only those modules are compiled.

---

## Core Layer

### `Result<S, F>`

The foundational error-handling type. No module throws unhandled exceptions across public APIs — all fallible operations return `Result<S, F>` or `PkResult<T>`.

```dart
// All public APIs use this pattern
Future<PkResult<User>> fetchUser() async {
  try {
    final data = await _api.get('/user');
    return Result.success(User.fromJson(data));
  } on DioException catch (e) {
    return Result.failure(NetworkException(message: e.message ?? 'Request failed'));
  }
}
```

### `PrimekitException` hierarchy

```
PrimekitException (sealed)
├── NetworkException
│   ├── NoConnectivityException
│   └── TimeoutException
├── AuthException
│   ├── TokenExpiredException
│   └── UnauthorizedException
├── StorageException
├── BillingException
│   └── PurchaseCancelledException
├── ValidationException
├── EmailException
├── PermissionDeniedException
└── ConfigurationException
```

### `PrimekitLogger`

Internal logger that respects the configured log level and is auto-silenced in production builds. Never use `print()` — always use `PrimekitLogger`.

```dart
PrimekitLogger.debug('Token refreshed', tag: 'Auth');
PrimekitLogger.error('Purchase failed', error: e, tag: 'Billing');
```

---

## Provider Pattern

Modules that interact with third-party services use an abstract provider pattern. This decouples Primekit from any specific SDK and makes testing trivial.

```dart
// Abstract interface in Primekit
abstract class AnalyticsProvider {
  Future<void> logEvent(AnalyticsEvent event);
}

// User implements for their SDK of choice
class FirebaseAnalyticsProvider implements AnalyticsProvider {
  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event.name,
      parameters: event.parameters,
    );
  }
}

// Or: use bundled providers (v0.2.0+)
```

This pattern is used by: Analytics, Email, Billing.

---

## Singleton Services

Services that maintain state (EventTracker, SessionManager, etc.) use the singleton pattern with optional test backdoors:

```dart
class EventTracker {
  EventTracker._();
  static EventTracker? _instance;
  static EventTracker get instance => _instance ??= EventTracker._();

  // For testing: inject a fresh instance
  @visibleForTesting
  static EventTracker testInstance({required List<AnalyticsProvider> providers}) {
    final tracker = EventTracker._();
    tracker._providers = providers;
    return tracker;
  }
}
```

---

## Immutability

All data classes are immutable. No public API mutates an object — operations return new instances:

```dart
// ✅ Correct pattern
final updated = subscription.copyWith(status: SubscriptionStatus.active);

// ❌ Never do this
subscription.status = SubscriptionStatus.active;
```

---

## State Management Integration

Primekit services that need to notify the UI extend `ChangeNotifier` for easy integration with any state management solution:

```dart
// Works with Provider
ChangeNotifierProvider(create: (_) => SessionManager.instance)

// Works with Riverpod
final sessionProvider = ChangeNotifierProvider((ref) => SessionManager.instance);

// Works with BLoC (via stream)
SessionManager.instance.stateStream.listen((state) { ... });
```

---

## File Size Guidelines

Following the codebase's "many small files" principle:
- Target: 200–400 lines per file
- Maximum: 800 lines
- Extract helpers and models into separate files

---

## Dependency Philosophy

New dependencies require justification:
- Prefer Dart SDK / Flutter SDK built-ins
- Each major third-party dependency must be documented in `pubspec.yaml`
- Optional integrations (RevenueCat, Firebase) should never be hard dependencies

---

## Testing Strategy

### Unit tests (required for all modules)
Test pure logic in isolation with mocked dependencies.

### Widget tests (required for all widgets)
Test `TierGate`, `PermissionGate`, `SkeletonLoader`, etc. using `flutter_test`.

### Integration notes
`TokenStore`, `JsonCache`, `SecurePrefs` — test using fake/in-memory implementations.

Coverage minimum: **80%** enforced by CI.
