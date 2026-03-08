import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../sync_data_source.dart';
import '../pending_change_store.dart';

/// A [Hive]-backed alternative to [PendingChangeStore] for persisting
/// [SyncChange] objects across app restarts.
///
/// Uses a Hive box where each entry is a JSON-encoded [SyncChange].
///
/// ```dart
/// final store = await HivePendingChangeStore.open();
/// await store.enqueue(change);
/// final pending = await store.getPending();
/// ```
class HivePendingChangeStore {
  HivePendingChangeStore._(this._box);

  final Box<String> _box;

  /// Opens (or creates) the Hive box and returns a ready-to-use store.
  static Future<HivePendingChangeStore> open({
    String boxName = 'pk_pending_changes',
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return HivePendingChangeStore._(box);
  }

  /// Appends [change] to the store.
  Future<void> enqueue(SyncChange change) async {
    await _box.add(jsonEncode(change.toJson()));
  }

  /// Returns all pending changes in insertion order.
  List<SyncChange> getPending() {
    return _box.values
        .map(
          (raw) => SyncChange.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        )
        .toList();
  }

  /// Removes the change with the given [id], marking it as complete.
  Future<void> markComplete(String id) async {
    final keyToDelete = _findKeyById(id);
    if (keyToDelete != null) {
      await _box.delete(keyToDelete);
    }
  }

  /// Marks a change as failed by re-enqueuing it with updated metadata.
  ///
  /// For simplicity this is a no-op — the change stays in the queue and will
  /// be retried on the next sync cycle.
  Future<void> markFailed(String id) async {
    // Change remains in the box for retry.
  }

  /// Removes all pending changes.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Returns the number of pending changes.
  int get count => _box.length;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  dynamic _findKeyById(String id) {
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['id'] == id) return key;
    }
    return null;
  }
}
