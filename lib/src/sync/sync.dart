/// Offline-first repository with pluggable conflict resolution and sync
/// state machine.
///
/// ## Quick start
///
/// ```dart
/// final repo = SyncRepository<Todo>(
///   collection: 'todos',
///   remoteSource: FirestoreSyncSource(),
///   fromJson: Todo.fromJson,
///   conflictResolver: LastWriteWinsResolver(),
///   syncInterval: const Duration(minutes: 5),
/// );
///
/// // Reactive stream
/// repo.watchAll().listen((todos) { /* update UI */ });
///
/// // Offline-safe writes
/// await repo.create({'title': 'Buy milk'});
/// await repo.update(id, {'done': true});
/// await repo.delete(id);
///
/// // Manual sync
/// await repo.syncNow();
///
/// // Observe sync state
/// repo.syncState.stateStream.listen((s) {
///   if (s.hasError) showSnackbar(s.error.toString());
/// });
/// ```
///
/// ## Conflict resolvers
///
/// | Class | Behaviour |
/// |-------|-----------|
/// | [LastWriteWinsResolver] | Newer `updatedAt` timestamp wins |
/// | [ServerWinsResolver] | Remote always wins |
/// | [ClientWinsResolver] | Local always wins |
/// | [FieldMergeResolver] | Per-field timestamp merge |
/// | [ManualConflictResolver] | User-supplied callback |
///
/// ## Backends
///
/// | Class | Backend |
/// |-------|---------|
/// | [FirestoreSyncSource] | Google Cloud Firestore |
/// | [MongoSyncSource] | MongoDB Atlas Data API |
library sync;

export 'conflict_resolver.dart';
export 'pending_change_store.dart';
export 'providers/firestore_sync_source.dart';
export 'providers/mongo_sync_source.dart';
export 'sync_data_source.dart';
export 'sync_document.dart';
export 'sync_repository.dart';
export 'sync_state.dart';
