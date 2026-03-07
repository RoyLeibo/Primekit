import 'dart:async';

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// SyncStatus
// ---------------------------------------------------------------------------

/// The current phase of the sync state machine.
enum SyncStatus {
  /// No sync is in progress; the repository is up to date.
  idle,

  /// A sync cycle (push or pull, or both) is actively running.
  syncing,

  /// The last sync cycle failed. Inspect [SyncState.error] for details.
  error,

  /// Sync is intentionally paused (e.g. the user toggled it off).
  paused,

  /// The device has no network connectivity; sync is deferred.
  offline,
}

// ---------------------------------------------------------------------------
// SyncState
// ---------------------------------------------------------------------------

/// Immutable snapshot of the sync engine's state at a point in time.
///
/// Observe via [SyncStateManager.stateStream] or [SyncStateManager.state].
final class SyncState {
  /// Creates an immutable [SyncState].
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.pendingChanges = 0,
    this.error,
    this.progress,
  }) : assert(
         progress == null || (progress >= 0.0 && progress <= 1.0),
         'progress must be between 0.0 and 1.0',
       );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// The current sync phase.
  final SyncStatus status;

  /// UTC timestamp of the last completed (successful) sync, or `null` if the
  /// repository has never been synced.
  final DateTime? lastSyncedAt;

  /// Number of local writes that have not yet been pushed to the remote.
  final int pendingChanges;

  /// The error from the most recent failed sync cycle, or `null` when the
  /// status is not [SyncStatus.error].
  final Object? error;

  /// Fractional progress (0.0 – 1.0) during a batch sync operation.
  ///
  /// `null` when no progress information is available (e.g. during a
  /// single-document push).
  final double? progress;

  // ---------------------------------------------------------------------------
  // Convenience predicates
  // ---------------------------------------------------------------------------

  /// Returns `true` while a sync cycle is actively running.
  bool get isSyncing => status == SyncStatus.syncing;

  /// Returns `true` when the repository is idle and fully synced.
  bool get isIdle => status == SyncStatus.idle;

  /// Returns `true` when the last sync attempt failed.
  bool get hasError => status == SyncStatus.error;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields overridden.
  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingChanges,
    Object? error,
    double? progress,
    bool clearError = false,
    bool clearProgress = false,
    bool clearLastSyncedAt = false,
  }) => SyncState(
    status: status ?? this.status,
    lastSyncedAt: clearLastSyncedAt
        ? null
        : (lastSyncedAt ?? this.lastSyncedAt),
    pendingChanges: pendingChanges ?? this.pendingChanges,
    error: clearError ? null : (error ?? this.error),
    progress: clearProgress ? null : (progress ?? this.progress),
  );

  @override
  String toString() =>
      'SyncState(status: ${status.name}, pendingChanges: $pendingChanges, '
      'lastSyncedAt: $lastSyncedAt, progress: $progress, error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastSyncedAt == other.lastSyncedAt &&
          pendingChanges == other.pendingChanges &&
          error == other.error &&
          progress == other.progress;

  @override
  int get hashCode =>
      Object.hash(status, lastSyncedAt, pendingChanges, error, progress);
}

// ---------------------------------------------------------------------------
// SyncStateManager
// ---------------------------------------------------------------------------

/// Manages [SyncState] transitions and broadcasts changes to listeners.
///
/// Implements [ChangeNotifier] for Widget-tree integration and also exposes a
/// [stateStream] for purely reactive pipelines.
///
/// Owned and driven internally by [SyncRepository]; consumers should only
/// read from it, never write.
final class SyncStateManager extends ChangeNotifier {
  SyncStateManager({SyncState? initialState})
    : _state = initialState ?? const SyncState();

  // ---------------------------------------------------------------------------
  // Internal stream infrastructure
  // ---------------------------------------------------------------------------

  // sync: true so that events are delivered immediately to existing listeners,
  // making state transitions observable without requiring an extra await cycle.
  final StreamController<SyncState> _controller =
      StreamController<SyncState>.broadcast(sync: true);

  SyncState _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The most recent sync state snapshot.
  SyncState get state => _state;

  /// A broadcast stream that emits a new [SyncState] on every transition.
  Stream<SyncState> get stateStream => _controller.stream;

  // ---------------------------------------------------------------------------
  // Internal transition API (used by SyncRepository)
  // ---------------------------------------------------------------------------

  /// Transitions to [newState], notifying all listeners.
  ///
  /// No-ops when the new state is identical to the current state to avoid
  /// spurious rebuilds.
  void transition(SyncState newState) {
    if (_state == newState) return;
    _state = newState;
    _controller.add(_state);
    notifyListeners();
  }

  /// Convenience: transition only the [SyncStatus].
  void transitionStatus(SyncStatus status) => transition(
    _state.copyWith(status: status, clearError: status != SyncStatus.error),
  );

  /// Convenience: record a successful sync completion.
  void markSyncComplete({required int pendingChanges}) => transition(
    _state.copyWith(
      status: SyncStatus.idle,
      lastSyncedAt: DateTime.now().toUtc(),
      pendingChanges: pendingChanges,
      clearError: true,
      clearProgress: true,
    ),
  );

  /// Convenience: record a sync failure.
  void markSyncError(Object error) => transition(
    _state.copyWith(
      status: SyncStatus.error,
      error: error,
      clearProgress: true,
    ),
  );

  /// Convenience: update batch progress (0.0 – 1.0).
  void updateProgress(double progress) =>
      transition(_state.copyWith(progress: progress));

  /// Convenience: update pending changes count without changing status.
  void updatePendingChanges(int count) =>
      transition(_state.copyWith(pendingChanges: count));

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
