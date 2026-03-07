# primekit_firebase

> Firebase adapter layer for PrimeKit — drop-in implementations backed by Firebase services.

[![pub version](https://img.shields.io/pub/v/primekit_firebase.svg)](https://pub.dev/packages/primekit_firebase)
[![pub points](https://img.shields.io/pub/points/primekit_firebase)](https://pub.dev/packages/primekit_firebase)
[![license](https://img.shields.io/github/license/RoyLeibo/Primekit)](LICENSE)

## Installation

```yaml
dependencies:
  primekit_firebase: ^1.0.0
```

## What's included

- **FirebaseAuthInterceptor** — injects Firebase ID tokens into HTTP requests
- **FirebaseCrashReporter** — routes `CrashReporter` calls to Firebase Crashlytics
- **FirebaseFlagProvider** — feature flags via Firebase Remote Config
- **FirebaseStorageUploader** — uploads media via Firebase Storage
- **PushHandler** — FCM push notification handling with foreground/background support
- **FirebaseRbacProvider** — role-based access control backed by Firestore
- **FirebasePresenceService / FirebaseRtdbChannel** — realtime presence and messaging via RTDB
- **FirebaseActivityFeedSource / FollowService / ProfileService** — social graph via Firestore
- **FirestoreSyncSource** — offline-first sync source backed by Firestore

## Documentation

[github.com/RoyLeibo/Primekit](https://github.com/RoyLeibo/Primekit)

## License

MIT — see [LICENSE](LICENSE).
