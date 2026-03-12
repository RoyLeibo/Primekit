# firebase — Firebase Adapters

**Purpose:** All Firebase-backed implementations of abstract Primekit interfaces. Import via `package:primekit/firebase.dart`.

**Key exports:**
- `AppInitializer` — one-shot Firebase boot; call in `main()` after `PrimekitConfig.initialize()`
- `FirebaseAuthInterceptor` — Dio interceptor using Firebase ID tokens
- `FirebaseCrashReporter` — Crashlytics implementation of `CrashReporter`
- `FirebaseStorageUploader` — Firebase Storage implementation of `MediaUploader`
- `FirestoreSyncSource` — Firestore implementation of `SyncDataSource`
- `FirebaseFlagProvider` — Remote Config implementation of `FlagProvider`
- `FirebaseRbacProvider` — Firestore-backed RBAC policy loader
- `FirebasePresenceService` — Realtime Database presence tracking
- Firebase providers for: auth, crash, media, sync, flags, rbac, social, currency, audit, realtime

**Firebase packages wrapped:** firebase_auth, firebase_storage, cloud_firestore, firebase_crashlytics, firebase_messaging, firebase_remote_config, firebase_database

**IMPORTANT:** These classes are NOT re-exported from individual module barrel files. Always `import 'package:primekit/firebase.dart'` explicitly.

**Maintenance:** Update when new Firebase adapter added or Firebase package versions change.
