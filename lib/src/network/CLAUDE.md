# network — HTTP Client

**Purpose:** Pre-configured Dio wrapper with retry, auth injection, and offline queue.

**Key exports:**
- `PrimekitNetworkClient` — Dio wrapper; configure with `baseUrl`, `onAuthToken`, interceptors
- `ApiResponse<T>` — typed response wrapper (loading/success/failure)
- `RetryInterceptor` — exponential backoff on 5xx/network errors
- `ConnectivityMonitor` — stream of network state changes (used by PawTrack)
- `OfflineQueue` — queues requests when offline, replays on reconnect
- `SyncStatusMonitor` — tracks sync queue progress

**Dependencies:** `core`, dio 5.7.0, connectivity_plus 7.0.0, rxdart 0.28.0

**Pattern:**
```dart
final client = PrimekitNetworkClient(
  baseUrl: 'https://api.example.com',
  onAuthToken: () async => sessionManager.currentToken,
);
```

**Maintenance:** Update when new interceptor added or offline queue API changes.
