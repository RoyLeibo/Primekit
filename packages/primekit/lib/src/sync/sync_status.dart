/// The current synchronisation state of the app.
enum PkSyncStatus {
  /// All local changes have been persisted to the server.
  synced,

  /// Changes are currently being sent to the server.
  syncing,

  /// Device is offline; changes are queued locally.
  offline,

  /// Sync failed with an error.
  error,
}

extension PkSyncStatusX on PkSyncStatus {
  bool get isOnline =>
      this == PkSyncStatus.synced || this == PkSyncStatus.syncing;
  bool get hasError => this == PkSyncStatus.error;
}
