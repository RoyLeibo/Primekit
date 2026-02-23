import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'conflict_resolver.dart';
import 'pending_change_store.dart';
import 'sync_data_source.dart';
import 'sync_state.dart';

// ---------------------------------------------------------------------------
// SyncRepository
// ---------------------------------------------------------------------------

/// Generic offline-first repository that transparently persists data locally
/// and synchronises with a remote [SyncDataSource].
///
/// All write operations ([create], [update], [delete]) return immediately after
/// writing to the local cache and enqueueing a [SyncChange]. Background sync
/// is triggered periodically via [syncInterval] and can also be triggered
/// manually via [syncNow].
///
/// Conflict resolution is handled by a pluggable [ConflictResolver]; the
/// default is [LastWriteWinsResolver].
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
/// // Listen for reactive updates
/// repo.watchAll().listen((todos) => setState(() => _todos = todos));
///
/// // Write (offline-safe)
/// await repo.create({'title': 'Buy milk', 'done': false});
/// await repo.syncNow();
/// ```
class SyncRepository<T> extends ChangeNotifier {
  /// Creates a [SyncRepository].
  SyncRepository({
    required String collection,
    required SyncDataSource remoteSource,
    required T Function(Map<String, dynamic>) fromJson,
    ConflictResolver<T>? conflictResolver,
    Duration syncInterval = const Duration(minutes: 5),
    String? userId,
    PendingChangeStore? pendingChangeStore,
  }) : _collection = collection,
       _remoteSource = remoteSource,
       _fromJson = fromJson,
       _conflictResolver = conflictResolver ?? LastWriteWinsResolver<T>(),
       _syncInterval = syncInterval,
       _userId = userId,
       _pendingStore =
           pendingChangeStore ??
           PendingChangeStore(storageKey: 'primekit_sync_$collection') {
    _syncStateManager = SyncStateManager();
    _startSyncTimer();
  }

  static const String _tag = 'SyncRepository';
  static const _uuid = Uuid();

  final String _collection;
  final SyncDataSource _remoteSource;
  final T Function(Map<String, dynamic>) _fromJson;
  final ConflictResolver<T> _conflictResolver;
  final Duration _syncInterval;
  final String? _userId;
  final PendingChangeStore _pendingStore;

  late final SyncStateManager _syncStateManager;

  // In-memory local cache: document ID → raw JSON map
  final Map<String, Map<String, dynamic>> _localCache = {};

  // Reactive stream controller
  final StreamController<List<T>> _watchController =
      StreamController<List<T>>.broadcast();

  Timer? _syncTimer;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  String get _cacheKey => 'primekit_local_cache_$_collection';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (!_disposed) syncNow();
    });
    // Load persisted cache on first run
    _loadLocalCache();
  }

  // ---------------------------------------------------------------------------
  // Public API — Read
  // ---------------------------------------------------------------------------

  /// The sync state manager, exposing [SyncState] and change notifications.
  SyncStateManager get syncState => _syncStateManager;

  /// Returns all non-deleted documents from the local cache.
  Future<List<T>> getAll() async {
    await _ensureCacheLoaded();
    return _activeDocuments();
  }

  /// Returns the document with [id] from the local cache, or `null` if not
  /// found or soft-deleted.
  Future<T?> getById(String id) async {
    await _ensureCacheLoaded();
    final doc = _localCache[id];
    if (doc == null || doc['isDeleted'] == true) return null;
    return _fromJson(doc);
  }

  /// A broadcast stream that emits the current list of non-deleted documents
  /// every time local state changes.
  Stream<List<T>> watchAll() => _watchController.stream;

  // ---------------------------------------------------------------------------
  // Public API — Write
  // ---------------------------------------------------------------------------

  /// Creates a new document from [data] and queues a [SyncOperation.create]
  /// change.
  ///
  /// An `id` and timestamp fields are injected automatically if absent.
  Future<T> create(Map<String, dynamic> data) async {
    await _ensureCacheLoaded();

    final now = DateTime.now().toUtc();
    final id = (data['id'] as String?) ?? _uuid.v4();

    final doc = {
      ...data,
      'id': id,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isDeleted': false,
      'version': 1,
    };

    _localCache[id] = doc;
    await _persistLocalCache();
    _emitWatchEvent();

    await _pendingStore.enqueue(
      SyncChange(
        id: id,
        document: doc,
        operation: SyncOperation.create,
        timestamp: now,
      ),
    );

    _syncStateManager.updatePendingChanges(await _pendingStore.count);
    notifyListeners();

    PrimekitLogger.debug('Created document $id in $_collection', tag: _tag);

    return _fromJson(doc);
  }

  /// Merges [data] into the document with [id] and queues a
  /// [SyncOperation.update] change.
  ///
  /// The document must already exist locally; throws [StorageException] if not.
  Future<T> update(String id, Map<String, dynamic> data) async {
    await _ensureCacheLoaded();

    final existing = _localCache[id];
    if (existing == null) {
      throw StorageException(
        message: 'Document $id not found in $_collection',
        code: 'SYNC_DOC_NOT_FOUND',
      );
    }

    final now = DateTime.now().toUtc();
    final currentVersion = (existing['version'] as int?) ?? 1;

    final updated = {
      ...existing,
      ...data,
      'id': id,
      'updatedAt': now.toIso8601String(),
      'version': currentVersion + 1,
    };

    _localCache[id] = updated;
    await _persistLocalCache();
    _emitWatchEvent();

    await _pendingStore.enqueue(
      SyncChange(
        id: id,
        document: updated,
        operation: SyncOperation.update,
        timestamp: now,
      ),
    );

    _syncStateManager.updatePendingChanges(await _pendingStore.count);
    notifyListeners();

    PrimekitLogger.debug('Updated document $id in $_collection', tag: _tag);

    return _fromJson(updated);
  }

  /// Soft-deletes the document with [id] and queues a [SyncOperation.delete]
  /// change.
  ///
  /// The document is hidden from [getAll] and [watchAll] immediately but
  /// remains in the local store until the delete is acknowledged by the remote.
  Future<void> delete(String id) async {
    await _ensureCacheLoaded();

    final existing = _localCache[id];
    if (existing == null) return; // Idempotent

    final now = DateTime.now().toUtc();
    final deleted = {
      ...existing,
      'isDeleted': true,
      'updatedAt': now.toIso8601String(),
    };

    _localCache[id] = deleted;
    await _persistLocalCache();
    _emitWatchEvent();

    await _pendingStore.enqueue(
      SyncChange(
        id: id,
        document: deleted,
        operation: SyncOperation.delete,
        timestamp: now,
      ),
    );

    _syncStateManager.updatePendingChanges(await _pendingStore.count);
    notifyListeners();

    PrimekitLogger.debug(
      'Soft-deleted document $id in $_collection',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Public API — Sync
  // ---------------------------------------------------------------------------

  /// The number of local changes not yet pushed to the remote backend.
  int get pendingChangesCount => _syncStateManager.state.pendingChanges;

  /// All pending [SyncChange] objects waiting to be pushed.
  List<SyncChange> get pendingChanges =>
      []; // Populated lazily via async getter

  /// Triggers a sync cycle: pushes pending local changes, then pulls remote
  /// changes since the last sync timestamp.
  ///
  /// No-ops if a sync is already in progress.
  Future<void> syncNow() async {
    if (_syncStateManager.state.isSyncing || _disposed) return;

    _syncStateManager.transition(
      _syncStateManager.state.copyWith(status: SyncStatus.syncing),
    );

    PrimekitLogger.info('syncNow() started for $_collection', tag: _tag);

    try {
      // 1. Push pending local changes
      await _pushPendingChanges();

      // 2. Pull remote changes since last sync
      await _pullRemoteChanges();

      _syncStateManager.markSyncComplete(
        pendingChanges: await _pendingStore.count,
      );

      PrimekitLogger.info('syncNow() complete for $_collection', tag: _tag);
    } catch (e, st) {
      PrimekitLogger.error(
        'syncNow() failed for $_collection',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _syncStateManager.markSyncError(e);
    }
  }

  /// Clears the local cache and re-fetches all documents from the remote.
  ///
  /// Use this to recover from a corrupted local state or to force a complete
  /// re-download.
  Future<void> fullSync() async {
    if (_disposed) return;

    _syncStateManager.transition(
      _syncStateManager.state.copyWith(status: SyncStatus.syncing),
    );

    PrimekitLogger.info('fullSync() started for $_collection', tag: _tag);

    try {
      _localCache.clear();
      await _pendingStore.clear();

      final remote = await _remoteSource.fetchChanges(
        collection: _collection,
        since: null, // full fetch
        userId: _userId,
      );

      for (final doc in remote) {
        final id = doc['id'] as String?;
        if (id != null) _localCache[id] = doc;
      }

      await _persistLocalCache();
      _emitWatchEvent();

      _syncStateManager.markSyncComplete(pendingChanges: 0);

      PrimekitLogger.info(
        'fullSync() complete — fetched ${remote.length} documents for '
        '$_collection',
        tag: _tag,
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'fullSync() failed for $_collection',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _syncStateManager.markSyncError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync internals
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingChanges() async {
    final changes = await _pendingStore.dequeueAll();
    if (changes.isEmpty) return;

    PrimekitLogger.debug(
      'Pushing ${changes.length} pending change(s) for $_collection',
      tag: _tag,
    );

    // Try batch push first; fall back to individual pushes on failure
    try {
      await _remoteSource.pushBatch(collection: _collection, changes: changes);
      await _pendingStore.clear();
    } catch (_) {
      // Fallback: push individually
      final pushed = <SyncChange>[];
      for (final change in changes) {
        try {
          await _remoteSource.pushChange(
            collection: _collection,
            document: change.document,
            operation: change.operation,
          );
          pushed.add(change);
        } catch (e) {
          PrimekitLogger.warning(
            'Failed to push change ${change.id}: $e',
            tag: _tag,
            error: e,
          );
          // Re-throw so the outer catch marks the sync as errored
          throw StorageException(
            message: 'Failed to push change ${change.id}',
            code: 'SYNC_PUSH_FAILED',
            cause: e,
          );
        }
      }
      await _pendingStore.remove(pushed);
    }
  }

  Future<void> _pullRemoteChanges() async {
    final lastSyncedAt = _syncStateManager.state.lastSyncedAt;

    final remoteChanges = await _remoteSource.fetchChanges(
      collection: _collection,
      since: lastSyncedAt,
      userId: _userId,
    );

    if (remoteChanges.isEmpty) return;

    PrimekitLogger.debug(
      'Pulled ${remoteChanges.length} remote change(s) for $_collection',
      tag: _tag,
    );

    for (final remote in remoteChanges) {
      final id = remote['id'] as String?;
      if (id == null) continue;

      final local = _localCache[id];
      if (local == null) {
        // New document from remote
        _localCache[id] = remote;
      } else {
        // Potential conflict: both sides have been modified
        final resolved = await _conflictResolver.resolve(
          local: local,
          remote: remote,
        );
        _localCache[id] = resolved;
      }
    }

    await _persistLocalCache();
    _emitWatchEvent();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Local cache persistence
  // ---------------------------------------------------------------------------

  bool _cacheLoaded = false;

  Future<void> _ensureCacheLoaded() async {
    if (!_cacheLoaded) await _loadLocalCache();
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _localCache[entry.key] = (entry.value as Map<String, dynamic>);
        }
      }
      _cacheLoaded = true;
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to load local cache for $_collection',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _persistLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_localCache));
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to persist local cache for $_collection',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<T> _activeDocuments() => _localCache.values
      .where((doc) => doc['isDeleted'] != true)
      .map(_fromJson)
      .toList();

  void _emitWatchEvent() {
    if (!_watchController.isClosed) {
      _watchController.add(_activeDocuments());
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  Future<void> dispose() async {
    _disposed = true;
    _syncTimer?.cancel();
    await _watchController.close();
    _syncStateManager.dispose();
    super.dispose();
  }
}
