# sync — Offline-First Data Sync

**Purpose:** Generic repository pattern for transparent local write → background sync to remote.

**Key exports:**
- `SyncRepository<T>` — offline-first repo; write is instant (local), sync happens in background
- `SyncDataSource` — abstract remote backend interface (implement for Firestore/Mongo/HTTP)
- `ConflictResolver` — pluggable strategy for resolving write conflicts
- `PendingChangeStore` — persists changes for retry (Hive-backed: `HivePendingChangeStore`)
- `SyncDocument<T>` — document wrapper with `syncStatus`, `lastModified`, `pendingChanges`
- `SyncState` enum — `idle` | `syncing` | `error`
- `FirestoreSyncSource`, `MongoSyncSource` — implementations (in `firebase.dart`)

**Pattern:**
```dart
repo.watchAll().listen((items) => /* update UI */);
await repo.create(item); // returns immediately after local write
await repo.syncNow();    // manual sync trigger
```

**Dependencies:** `core`, `storage` (Hive for pending changes), `network`

**Maintenance:** Update when conflict resolution API changes or new backend implementation added.
