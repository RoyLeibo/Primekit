import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core.dart';

/// Per-user notification preference management backed by Cloud Firestore.
///
/// Preferences are stored at `{basePath}/{type}` and sync in real-time
/// across all of a user's devices. Use [watchEnabled] for a live stream
/// that rebuilds UI automatically.
///
/// Falls back to [defaultValue] (true) when a preference is not set.
///
/// ```dart
/// final prefs = RemoteNotificationPreferences(
///   firestore: FirebaseFirestore.instance,
///   userId: 'user-abc',
/// );
///
/// // Write
/// await prefs.setEnabled('expense_reminder', enabled: false);
///
/// // Read once
/// final on = await prefs.isEnabled('expense_reminder'); // false
///
/// // Live stream — rebuilds UI without polling
/// prefs.watchEnabled('expense_reminder').listen((on) => setState(() {}));
/// ```
class RemoteNotificationPreferences {
  RemoteNotificationPreferences({
    required FirebaseFirestore firestore,
    required String userId,
    /// Override the default Firestore path.
    /// Defaults to `users/{userId}/settings/notifications`.
    String? basePath,
  }) : _firestore = firestore,
       _basePath = basePath ?? 'users/$userId/settings/notifications';

  final FirebaseFirestore _firestore;
  final String _basePath;

  static const String _tag = 'RemoteNotificationPreferences';
  static const String _enabledField = 'enabled';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_basePath);

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Sets whether the notification [type] is enabled for this user.
  ///
  /// Throws [StorageException] on a Firestore write failure.
  Future<void> setEnabled(String type, {required bool enabled}) async {
    try {
      await _collection.doc(type).set(
        {_enabledField: enabled},
        SetOptions(merge: true),
      );
      PrimekitLogger.debug(
        'Preference "$type" set to $enabled',
        tag: _tag,
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'setEnabled("$type") failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to save notification preference "$type"',
        code: 'NOTIF_PREF_SET_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Read once
  // ---------------------------------------------------------------------------

  /// Returns whether [type] is enabled.
  ///
  /// Returns [defaultValue] (true) when the preference is not set or if
  /// Firestore is temporarily unavailable (offline cache miss).
  Future<bool> isEnabled(String type, {bool defaultValue = true}) async {
    try {
      final doc = await _collection.doc(type).get();
      if (!doc.exists) return defaultValue;
      return (doc.data()?[_enabledField] as bool?) ?? defaultValue;
    } catch (e, st) {
      PrimekitLogger.error(
        'isEnabled("$type") failed — returning default',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return defaultValue;
    }
  }

  /// Returns all stored preferences as a `{type: enabled}` map.
  ///
  /// Returns an empty map on failure.
  Future<Map<String, bool>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return {
        for (final doc in snapshot.docs)
          doc.id: (doc.data()[_enabledField] as bool?) ?? true,
      };
    } catch (e, st) {
      PrimekitLogger.error(
        'getAll() failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Live stream
  // ---------------------------------------------------------------------------

  /// Returns a live stream of whether [type] is enabled.
  ///
  /// Emits [defaultValue] when the preference is not set. The stream is backed
  /// by Firestore's snapshot listener, so it reflects remote changes instantly.
  Stream<bool> watchEnabled(String type, {bool defaultValue = true}) {
    return _collection.doc(type).snapshots().map((snap) {
      if (!snap.exists) return defaultValue;
      return (snap.data()?[_enabledField] as bool?) ?? defaultValue;
    });
  }

  /// Returns a live stream of all preferences as a `{type: enabled}` map.
  Stream<Map<String, bool>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs)
          doc.id: (doc.data()[_enabledField] as bool?) ?? true,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Deletes all stored preferences for this user (batch delete).
  Future<void> reset() async {
    try {
      final snapshot = await _collection.get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      PrimekitLogger.debug(
        'Reset ${snapshot.docs.length} preferences',
        tag: _tag,
      );
    } catch (e, st) {
      PrimekitLogger.error(
        'reset() failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }
}
