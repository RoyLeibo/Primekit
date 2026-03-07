/// Base contract for any document that participates in offline sync.
///
/// All domain models stored in a [SyncRepository] must implement this
/// interface so the repository can track identity, timestamps, and
/// soft-deletion state.
abstract interface class SyncDocument {
  /// Unique document identifier (UUID or remote database ID).
  String get id;

  /// UTC timestamp of the most recent local or remote write.
  DateTime get updatedAt;

  /// Serialises the document to a JSON-encodable map.
  Map<String, dynamic> toJson();
}

// ---------------------------------------------------------------------------
// SyncMeta
// ---------------------------------------------------------------------------

/// Immutable metadata attached to every synced document.
///
/// Tracks identity, timestamps, device authorship, optimistic-locking version,
/// and soft-deletion state so the sync engine can detect and resolve conflicts
/// without permanently erasing data.
final class SyncMeta {
  /// Creates an immutable [SyncMeta] instance.
  const SyncMeta({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.syncedBy,
    this.version = 1,
    this.isDeleted = false,
  });

  /// Deserialises from a JSON map produced by [toJson].
  factory SyncMeta.fromJson(Map<String, dynamic> json) => SyncMeta(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    syncedBy: json['syncedBy'] as String?,
    version: (json['version'] as num?)?.toInt() ?? 1,
    isDeleted: (json['isDeleted'] as bool?) ?? false,
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Unique document identifier.
  final String id;

  /// UTC timestamp when the document was first created.
  final DateTime createdAt;

  /// UTC timestamp of the most recent mutation.
  final DateTime updatedAt;

  /// Device ID of the client that last wrote this document.
  ///
  /// Used to attribute changes and skip echoed remote pushes.
  final String? syncedBy;

  /// Monotonically increasing version counter.
  ///
  /// Incremented on every write; used for optimistic locking so the remote
  /// backend can detect out-of-order updates.
  final int version;

  /// Whether this document has been soft-deleted.
  ///
  /// Soft deletes are propagated to remote during the next sync cycle and
  /// allow conflict resolvers to handle delete–update races cleanly.
  final bool isDeleted;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy of this [SyncMeta] with the given fields overridden.
  SyncMeta copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncedBy,
    int? version,
    bool? isDeleted,
  }) => SyncMeta(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedBy: syncedBy ?? this.syncedBy,
    version: version ?? this.version,
    isDeleted: isDeleted ?? this.isDeleted,
  );

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Serialises to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (syncedBy != null) 'syncedBy': syncedBy,
    'version': version,
    'isDeleted': isDeleted,
  };

  @override
  String toString() =>
      'SyncMeta(id: $id, version: $version, isDeleted: $isDeleted, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMeta &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version &&
          isDeleted == other.isDeleted &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, version, isDeleted, updatedAt);
}
