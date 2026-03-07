# PrimeKit Integration Report

## Status: Complete (Step 2 of 2)

All four Leibo apps have been integrated with PrimeKit.

| App | Status | Commit |
|-----|--------|--------|
| PawTrack | ✅ Integrated | 099f53c |
| Bullseye-Mobile-App | ✅ Integrated | b1f5996 |
| best_todo_list | ✅ Integrated | 5fee1f2 |
| Splitly | ✅ Integrated | 7d37681 |

---

## What Was Integrated

### PrimeKit packages used across apps

| Package | Used For |
|---------|----------|
| `primekit` | `ErrorBoundary`, `CrashConfig` |
| `primekit_firebase` | `FirebaseCrashReporter`, `FirebaseStorageUploader` |
| `primekit_core` | `PkSchema`, validators |
| `primekit_riverpod` | Riverpod utilities |

### Per-App Changes

**PawTrack**
- Replaced raw `FirebaseCrashlytics` calls with `CrashConfig.initialize(FirebaseCrashReporter())`
- Wrapped `runApp` in `ErrorBoundary(reporter: CrashConfig.reporter, ...)`
- Migrated google_sign_in to 7.x singleton + extension to 3.0.0

**Bullseye-Mobile-App**
- Added `CrashConfig` + `FirebaseCrashReporter` via `primekit_firebase`
- Wrapped app in `ErrorBoundary`
- Migrated google_sign_in to 7.x

**best_todo_list**
- Added `CrashConfig` + `FirebaseCrashReporter`
- Wrapped app in `ErrorBoundary`
- Migrated google_sign_in to 7.x
- Migrated calendar service to extension 3.0.0 (`authorizationForScopes` + `authClient`)
- Fixed `flutter_local_notifications` 20.x named-parameter API

**Splitly**
- Added `CrashConfig` + `FirebaseCrashReporter`
- Wrapped app in `ErrorBoundary`
- Migrated `ImageUploadService` to static `pickAndUpload()` API
- Fixed offline sync to use `primekit_firebase` `FirebaseStorageUploader`
- Fixed `validators.dart` to import from `primekit_core` for `PkSchema`

---

## Dependency Upgrade Guide

This integration required upgrading multiple packages with breaking changes. Documented here for future reference.

### google_sign_in 7.x

**Breaking changes:**
- `GoogleSignIn()` constructor removed → use `GoogleSignIn.instance` singleton
- `signIn()` removed → use `authenticate(scopeHint: scopes)` (throws on cancel, never returns null)
- `await googleUser.authentication` (async) → `googleUser.authentication` (synchronous)
- `googleAuth.accessToken` removed → use `authorizationClient.authorizationForScopes(scopes)?.accessToken`
- Must call `GoogleSignIn.instance.initialize()` before any auth calls on mobile (not needed on web)

**Migration pattern:**
```dart
// Before
final _googleSignIn = GoogleSignIn(scopes: [...]);
final account = await _googleSignIn.signIn();
if (account == null) return; // user cancelled
final auth = await account.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: auth.accessToken,
  idToken: auth.idToken,
);

// After
final account = await GoogleSignIn.instance.authenticate(scopeHint: [...]);
// throws AuthCancelledException on cancel — no null check needed
final auth = account.authentication; // synchronous
final authorization = await GoogleSignIn.instance.authorizationClient
    .authorizationForScopes([...]);
final credential = GoogleAuthProvider.credential(
  accessToken: authorization?.accessToken,
  idToken: auth.idToken,
);
```

**Sign-out:**
```dart
// Before
await _googleSignIn.signOut();
// After
await GoogleSignIn.instance.signOut();
```

### extension_google_sign_in_as_googleapis_auth 3.0.0

**Breaking change:** `googleSignIn.authenticatedClient()` removed.

**Migration pattern:**
```dart
// Before
final client = await googleSignIn.authenticatedClient();

// After
final authorization = await GoogleSignIn.instance.authorizationClient
    .authorizationForScopes(scopes);
if (authorization == null) return null;
final client = authorization.authClient(scopes: scopes);
```

### connectivity_plus 7.x

**Breaking change:** `onConnectivityChanged` and `checkConnectivity()` now return `List<ConnectivityResult>` instead of `ConnectivityResult`.

**Migration pattern:**
```dart
// Before
StreamSubscription<ConnectivityResult>? _sub;
_sub = Connectivity().onConnectivityChanged.listen((result) {
  final isOnline = result != ConnectivityResult.none;
});
final result = await Connectivity().checkConnectivity();
final isOnline = result != ConnectivityResult.none;

// After
StreamSubscription<List<ConnectivityResult>>? _sub;
_sub = Connectivity().onConnectivityChanged.listen((results) {
  final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
});
final results = await Connectivity().checkConnectivity();
final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
```

### flutter_local_notifications 20.x

**Breaking change:** `initialize()` and `show()` now require named parameters.

**Migration pattern:**
```dart
// Before
await _localNotifications.initialize(const InitializationSettings(...));
_localNotifications.show(id, title, body, details);

// After
await _localNotifications.initialize(settings: const InitializationSettings(...));
_localNotifications.show(id: id, title: title, body: body, notificationDetails: details);
```

### cloud_firestore 6.x

**Breaking change:** `firestore.enablePersistence(PersistenceSettings(...))` removed.

**Migration pattern:**
```dart
// Before
await FirebaseFirestore.instance.enablePersistence(
  const PersistenceSettings(synchronizeTabs: true),
);

// After
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### firebase_auth 6.x

**Breaking change:** `fetchSignInMethodsForEmail()` removed.

For account linking flows that previously used this method, either:
- Attempt sign-in directly and catch `account-exists-with-different-credential`
- Or sign in with the new provider and use `user.linkWithCredential()`

### firebase_messaging 16.x

**Constraint fix:** `firebase_messaging: ^16.1.2` is required alongside `firebase_core: ^4.x`. Version `^15.x` conflicts.

---

## Package Structure Notes

When importing PrimeKit symbols, use the correct sub-package:

| Symbol | Package |
|--------|---------|
| `FirebaseCrashReporter` | `primekit_firebase` |
| `FirebaseStorageUploader` | `primekit_firebase` |
| `ErrorBoundary` | `primekit` |
| `CrashConfig` | `primekit` |
| `PkSchema` | `primekit_core` |

**Do NOT import** from internal paths like `package:primekit/src/crash/firebase_crash_reporter.dart` — use the sub-package barrel exports.

### dependency_overrides for local path deps

When using PrimeKit via local path in `pubspec.yaml`, all four packages must appear in both `dependencies` and `dependency_overrides`:

```yaml
dependencies:
  primekit:
    path: ../Primekit/packages/primekit
  primekit_firebase:
    path: ../Primekit/packages/primekit_firebase
  primekit_core:
    path: ../Primekit/packages/primekit_core
  primekit_riverpod:
    path: ../Primekit/packages/primekit_riverpod

dependency_overrides:
  primekit:
    path: ../Primekit/packages/primekit
  primekit_firebase:
    path: ../Primekit/packages/primekit_firebase
  primekit_core:
    path: ../Primekit/packages/primekit_core
  primekit_riverpod:
    path: ../Primekit/packages/primekit_riverpod
```

This forces all transitive dependents to use the local version.
