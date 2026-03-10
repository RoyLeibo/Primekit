import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../core.dart';
import '../sync/sync_status.dart';
import 'connectivity_monitor.dart';

/// Bridges [ConnectivityMonitor] and Firestore's `hasPendingWrites` metadata
/// into a unified [PkSyncStatus] stream for use with [PkSyncStatusBadge].
///
/// | Condition                      | Emitted status       |
/// |-------------------------------|----------------------|
/// | Device offline                 | `PkSyncStatus.offline`  |
/// | Online + Firestore write error | `PkSyncStatus.error`    |
/// | Online + pending local writes  | `PkSyncStatus.syncing`  |
/// | Online + all writes flushed    | `PkSyncStatus.synced`   |
///
/// Call [setWatchPath] once after sign-in with a Firestore collection your
/// app actively writes to. Without a watch path, only connectivity state is
/// tracked (no `syncing` / `synced` distinction).
///
/// ```dart
/// // Once after login
/// SyncStatusMonitor.instance.setWatchPath('users/$uid/expenses');
///
/// // In any widget
/// PkSyncStatusBadge(
///   statusStream: SyncStatusMonitor.instance.status,
///   pendingCountStream: SyncStatusMonitor.instance.pendingCount,
/// );
/// ```
final class SyncStatusMonitor {
  SyncStatusMonitor._({
    ConnectivityMonitor? connectivity,
    FirebaseFirestore? firestore,
  }) : _connectivity = connectivity ?? ConnectivityMonitor.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static SyncStatusMonitor? _instance;

  /// The shared singleton instance.
  static SyncStatusMonitor get instance {
    _instance ??= SyncStatusMonitor._();
    return _instance!;
  }

  final ConnectivityMonitor _connectivity;
  final FirebaseFirestore _firestore;

  static const String _tag = 'SyncStatusMonitor';

  String? _watchPath;
  bool _started = false;

  final BehaviorSubject<bool> _pendingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<int> _pendingCountSubject = BehaviorSubject.seeded(0);
  final BehaviorSubject<bool> _errorSubject = BehaviorSubject.seeded(false);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _firestoreSubscription;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Sets the Firestore collection path to watch for pending writes.
  ///
  /// Call once after the user signs in. Re-calling updates the watch path and
  /// restarts the listener. Call with `null` to stop watching Firestore writes.
  void setWatchPath(String? path) {
    _watchPath = path;
    if (_started) {
      _stopFirestoreListener();
      if (path != null) _startFirestoreListener();
    }
  }

  // ---------------------------------------------------------------------------
  // Public streams
  // ---------------------------------------------------------------------------

  /// A stream of the current synchronisation status.
  ///
  /// Combines connectivity and Firestore write state. Starts the internal
  /// listeners on first subscription.
  Stream<PkSyncStatus> get status {
    _ensureStarted();
    return Rx.combineLatest3<bool, bool, bool, PkSyncStatus>(
      _connectivity.isConnected,
      _pendingSubject.stream,
      _errorSubject.stream,
      (online, hasPending, hasError) {
        if (!online) return PkSyncStatus.offline;
        if (hasError) return PkSyncStatus.error;
        if (hasPending) return PkSyncStatus.syncing;
        return PkSyncStatus.synced;
      },
    ).distinct();
  }

  /// The number of documents currently queued for a remote write.
  ///
  /// Useful for the badge counter. Emits 0 when there is no pending writes
  /// or no watch path is configured.
  Stream<int> get pendingCount {
    _ensureStarted();
    return _pendingCountSubject.stream.distinct();
  }

  /// A one-shot snapshot of the current status (no stream needed).
  PkSyncStatus get currentStatus {
    final online = _connectivity.currentStatus;
    if (!online) return PkSyncStatus.offline;
    if (_errorSubject.value) return PkSyncStatus.error;
    if (_pendingSubject.value) return PkSyncStatus.syncing;
    return PkSyncStatus.synced;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    if (_watchPath != null) _startFirestoreListener();
  }

  void _startFirestoreListener() {
    final path = _watchPath;
    if (path == null) return;

    PrimekitLogger.debug('Starting Firestore sync listener on "$path"', tag: _tag);

    _firestoreSubscription = _firestore
        .collection(path)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            final hasPending = snapshot.metadata.hasPendingWrites;
            final pendingCount =
                snapshot.docs.where((d) => d.metadata.hasPendingWrites).length;

            _pendingSubject.add(hasPending);
            _pendingCountSubject.add(pendingCount);

            // Clear any previous error once a successful snapshot arrives.
            if (_errorSubject.value) _errorSubject.add(false);

            PrimekitLogger.verbose(
              hasPending
                  ? 'Pending writes: $pendingCount document(s)'
                  : 'All writes synced',
              tag: _tag,
            );
          },
          onError: (Object error, StackTrace stack) {
            PrimekitLogger.error(
              'Firestore sync listener error',
              tag: _tag,
              error: error,
              stackTrace: stack,
            );
            _errorSubject.add(true);
          },
        );
  }

  void _stopFirestoreListener() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    // Reset pending state when listener is torn down.
    _pendingSubject.add(false);
    _pendingCountSubject.add(0);
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the singleton and disposes all streams. For use in tests only.
  @visibleForTesting
  Future<void> disposeForTesting() async {
    _stopFirestoreListener();
    await _pendingSubject.close();
    await _pendingCountSubject.close();
    await _errorSubject.close();
    _started = false;
    _instance = null;
  }
}
