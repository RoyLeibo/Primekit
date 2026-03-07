# Changelog

## [1.0.0] — 2026-03-07

Initial release of `primekit_firebase`, extracted from the monolithic `primekit` package.

### Included adapters
- **FirebaseAuthInterceptor**: Auto-injects Firebase ID tokens into Dio requests
- **FirebaseCrashReporter**: Crashlytics-backed `CrashReporter` implementation
- **FirebaseStorageUploader**: Firebase Storage-backed `MediaUploader`
- **PushHandler**: FCM-backed push notification handler
- **FirebaseRtdbChannel**: Firebase Realtime Database `RealtimeChannel`
- **FirestoreSyncSource**: Firestore-backed `SyncDataSource`
- **FirebaseFlagProvider**: Remote Config-backed `FlagProvider`
- **FirebaseRbacProvider**: Firestore-backed `RbacProvider`
- **Firebase social adapters**: `FirebaseActivityFeedSource`, `FirebaseFollowSource`, `FirebaseProfileSource`, `FirebaseSocialAuth`
