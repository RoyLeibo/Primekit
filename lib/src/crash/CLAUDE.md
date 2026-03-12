# crash — Crash Reporting

**Purpose:** Multi-backend crash reporting with widget error boundary.

**Key exports:**
- `CrashReporter` — abstract interface; implement or use provided backends
- `SentryCrashReporter` — Sentry implementation
- `MultiCrashReporter` — chains multiple reporters (e.g. Sentry + Firebase)
- `ErrorBoundary` — Flutter widget that catches build errors and reports them
- `FirebaseCrashReporter` — Crashlytics impl (import via `firebase.dart`, NOT exported here)

**Pattern:**
```dart
MultiCrashReporter([SentryCrashReporter(), FirebaseCrashReporter()])
```

**Dependencies:** sentry_flutter, firebase (conditional)

**Maintenance:** Update when new reporter backend added.
