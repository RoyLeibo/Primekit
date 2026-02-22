import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'sync_data_source.dart';

/// Persists [SyncChange] objects to [SharedPreferences] so that unsynced
/// local writes survive app restarts.
///
/// The store operates as a FIFO queue: changes are appended via [enqueue] and
/// consumed (in order) via [dequeueAll]. After a successful remote push the
/// caller should invoke [clear] to remove the flushed changes.
///
/// ```dart
/// final store = PendingChangeStore();
/// await store.enqueue(change);
/// final pending = await store.dequeueAll();
/// // ... push to remote ...
/// await store.clear();
/// ```
final class PendingChangeStore {
  /// Creates a [PendingChangeStore].
  ///
  /// [storageKey] may be overridden in tests to isolate storage namespaces.
  PendingChangeStore({String? storageKey})
      : _key = storageKey ?? _defaultKey;

  static const String _defaultKey = 'primekit_sync_pending_changes';
  static const String _tag = 'PendingChangeStore';

  final String _key;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Appends [change] to the tail of the persisted queue.
  ///
  /// Throws [StorageException] if the write fails.
  Future<void> enqueue(SyncChange change) async {
    try {
      final current = await _load();
      final updated = [...current, change];
      await _save(updated);

      PrimekitLogger.debug(
        'Enqueued change: ${change.id} (${change.operation.name}) — '
        'queue depth: ${updated.length}',
        tag: _tag,
      );
    } catch (e, st) {
      _handleError('enqueue', e, st);
    }
  }

  /// Returns all queued [SyncChange] objects in FIFO order without removing
  /// them.
  ///
  /// Call [clear] after a successful push to drain the queue.
  ///
  /// Throws [StorageException] if the read fails.
  Future<List<SyncChange>> dequeueAll() async {
    try {
      return await _load();
    } catch (e, st) {
      _handleError('dequeueAll', e, st);
    }
  }

  /// Returns the number of changes currently queued.
  ///
  /// Throws [StorageException] if the read fails.
  Future<int> get count async {
    try {
      final changes = await _load();
      return changes.length;
    } catch (e, st) {
      _handleError('count', e, st);
    }
  }

  /// Removes all queued changes.
  ///
  /// Should be called after all changes have been successfully pushed to the
  /// remote backend.
  ///
  /// Throws [StorageException] if the write fails.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);

      PrimekitLogger.debug('Cleared pending change store.', tag: _tag);
    } catch (e, st) {
      _handleError('clear', e, st);
    }
  }

  /// Removes a specific set of [changes] from the store, leaving any
  /// remaining changes intact.
  ///
  /// Useful when only a subset of changes was pushed successfully.
  ///
  /// Throws [StorageException] if the write fails.
  Future<void> remove(List<SyncChange> changes) async {
    try {
      final current = await _load();
      final ids = changes.map((c) => c.id).toSet();
      final remaining = current.where((c) => !ids.contains(c.id)).toList();
      await _save(remaining);
    } catch (e, st) {
      _handleError('remove', e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<List<SyncChange>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(SyncChange.fromJson)
        .toList();
  }

  Future<void> _save(List<SyncChange> changes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(changes.map((c) => c.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Never _handleError(String op, Object e, StackTrace st) {
    PrimekitLogger.error(
      'PendingChangeStore.$op failed',
      tag: _tag,
      error: e,
      stackTrace: st,
    );
    throw StorageException(
      message: 'PendingChangeStore.$op failed',
      code: 'PENDING_STORE_${op.toUpperCase()}_FAILED',
      cause: e,
    );
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the store to an empty state. For use in tests only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
