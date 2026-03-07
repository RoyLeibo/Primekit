import 'dart:async';

// ---------------------------------------------------------------------------
// SyncOperation
// ---------------------------------------------------------------------------

/// The type of write operation applied to a document.
enum SyncOperation {
  /// A new document was inserted.
  create,

  /// An existing document was updated.
  update,

  /// A document was deleted (soft or hard).
  delete,
}

// ---------------------------------------------------------------------------
// SyncChange
// ---------------------------------------------------------------------------

/// A single pending change waiting to be pushed to the remote backend.
///
/// Changes are persisted locally in [PendingChangeStore] so they survive
/// app restarts and can be replayed once connectivity is restored.
final class SyncChange {
  /// Creates an immutable [SyncChange].
  const SyncChange({
    required this.id,
    required this.document,
    required this.operation,
    required this.timestamp,
  });

  /// Deserialises from a JSON map produced by [toJson].
  factory SyncChange.fromJson(Map<String, dynamic> json) => SyncChange(
    id: json['id'] as String,
    document: (json['document'] as Map<String, dynamic>)
        .cast<String, dynamic>(),
    operation: SyncOperation.values.byName(json['operation'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Document ID that this change targets.
  final String id;

  /// Full serialised document payload at the time of the change.
  final Map<String, dynamic> document;

  /// The write operation type.
  final SyncOperation operation;

  /// UTC timestamp when the change was created locally.
  final DateTime timestamp;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Serialises to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'document': document,
    'operation': operation.name,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() =>
      'SyncChange(id: $id, operation: ${operation.name}, '
      'timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncChange &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          operation == other.operation &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, operation, timestamp);
}

// ---------------------------------------------------------------------------
// SyncDataSource
// ---------------------------------------------------------------------------

/// Abstract remote backend used by [SyncRepository].
///
/// Implement this interface to connect the offline-first repository to any
/// cloud storage system. Concrete implementations ship for Firestore
/// ([FirestoreSyncSource]) and MongoDB Atlas ([MongoSyncSource]).
///
/// ```dart
/// final repo = SyncRepository<Todo>(
///   collection: 'todos',
///   remoteSource: FirestoreSyncSource(),
///   fromJson: Todo.fromJson,
/// );
/// ```
abstract interface class SyncDataSource {
  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Fetches all documents in [collection] that have changed since [since].
  ///
  /// When [since] is `null` a full collection fetch is performed (used on
  /// first launch or after [SyncRepository.fullSync]).
  ///
  /// Pass [userId] to scope the query to a single user's documents when the
  /// backend enforces user-level isolation.
  Future<List<Map<String, dynamic>>> fetchChanges({
    required String collection,
    DateTime? since,
    String? userId,
  });

  /// Opens a real-time stream of documents in [collection].
  ///
  /// The stream emits the full current list every time any document in the
  /// collection changes. Implementations backed by REST APIs (e.g.
  /// [MongoSyncSource]) fall back to periodic polling.
  ///
  /// Pass [userId] to scope the stream to a single user's documents.
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String collection,
    String? userId,
  });

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Pushes a single document change to the remote backend.
  ///
  /// [operation] determines whether the backend performs an insert, update/
  /// merge, or delete.
  Future<void> pushChange({
    required String collection,
    required Map<String, dynamic> document,
    required SyncOperation operation,
  });

  /// Pushes multiple changes to the remote backend in a single call.
  ///
  /// Implementations should use a batch/transaction API where available to
  /// minimise round-trips and ensure atomicity.
  Future<void> pushBatch({
    required String collection,
    required List<SyncChange> changes,
  });

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  /// Identifies the backend provider.
  ///
  /// Examples: `'firestore'`, `'mongodb'`, `'custom'`.
  String get providerId;
}
