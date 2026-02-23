// ---------------------------------------------------------------------------
// ConflictResolver interface
// ---------------------------------------------------------------------------

/// Strategy for resolving write conflicts between a local and a remote
/// version of the same document.
///
/// When [SyncRepository] detects that both a local write and a remote write
/// have occurred for the same document ID since the last sync, it delegates
/// to the active [ConflictResolver] to pick the winning document.
///
/// Implement this interface to create a custom resolution strategy.
///
/// ```dart
/// final repo = SyncRepository<Todo>(
///   collection: 'todos',
///   remoteSource: mySource,
///   fromJson: Todo.fromJson,
///   conflictResolver: LastWriteWinsResolver(),
/// );
/// ```
abstract interface class ConflictResolver<T> {
  /// Resolves a conflict between [local] and [remote] versions.
  ///
  /// Both maps are full JSON representations of the document (as produced by
  /// `SyncDocument.toJson()`). Implementations must return the JSON map that
  /// should become the canonical document — either [local], [remote], a
  /// merge, or a completely new map.
  ///
  /// The returned map is written back to local storage and queued for the next
  /// remote push.
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  });
}

// ---------------------------------------------------------------------------
// LastWriteWinsResolver
// ---------------------------------------------------------------------------

/// Resolves conflicts by comparing the `updatedAt` ISO-8601 timestamp field.
///
/// The document with the later timestamp wins. When timestamps are equal,
/// [preferLocal] controls the tiebreaker (defaults to `false`, favouring the
/// remote).
///
/// Both documents must contain an `updatedAt` field parseable by
/// [DateTime.parse]. Documents missing the field are treated as having the
/// epoch as their timestamp.
final class LastWriteWinsResolver<T> implements ConflictResolver<T> {
  /// Creates a [LastWriteWinsResolver].
  ///
  /// Set [preferLocal] to `true` to break ties in favour of the local copy.
  const LastWriteWinsResolver({this.preferLocal = false});

  /// When `true`, the local document is chosen on timestamp ties.
  ///
  /// Defaults to `false` (remote wins ties).
  final bool preferLocal;

  @override
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async {
    final localTime = _parseTimestamp(local['updatedAt']);
    final remoteTime = _parseTimestamp(remote['updatedAt']);

    if (localTime.isAfter(remoteTime)) return local;
    if (remoteTime.isAfter(localTime)) return remote;

    // Tie-break
    return preferLocal ? local : remote;
  }

  DateTime _parseTimestamp(Object? raw) {
    if (raw is String) {
      try {
        return DateTime.parse(raw).toUtc();
      } catch (_) {
        return DateTime.utc(1970);
      }
    }
    return DateTime.utc(1970);
  }
}

// ---------------------------------------------------------------------------
// FieldMergeResolver
// ---------------------------------------------------------------------------

/// Resolves conflicts at the field level using per-field timestamps.
///
/// This resolver expects each document to contain a `_fieldTimestamps` map
/// of the shape `{ fieldName: iso8601String }`. For every field present in
/// either document, the value from the document with the more recent
/// field-level timestamp is chosen.
///
/// Fields without an entry in `_fieldTimestamps` fall back to the remote
/// value.
///
/// This strategy is ideal when multiple users or devices edit different parts
/// of the same document concurrently (e.g. a collaborative profile form).
final class FieldMergeResolver<T> implements ConflictResolver<T> {
  /// Creates a [FieldMergeResolver].
  const FieldMergeResolver();

  static const String _tsKey = '_fieldTimestamps';

  @override
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async {
    final localTs = _parseFieldTimestamps(local[_tsKey]);
    final remoteTs = _parseFieldTimestamps(remote[_tsKey]);

    final allKeys = {...local.keys, ...remote.keys}.where((k) => k != _tsKey);

    final mergedFields = <String, dynamic>{};
    final mergedTs = <String, String>{};

    for (final field in allKeys) {
      final localTime = localTs[field] ?? DateTime.utc(1970);
      final remoteTime = remoteTs[field] ?? DateTime.utc(1970);

      if (localTime.isAfter(remoteTime)) {
        mergedFields[field] = local[field];
        mergedTs[field] = localTime.toIso8601String();
      } else {
        mergedFields[field] = remote[field];
        mergedTs[field] = remoteTime.toIso8601String();
      }
    }

    return {...mergedFields, _tsKey: mergedTs};
  }

  Map<String, DateTime> _parseFieldTimestamps(Object? raw) {
    if (raw is! Map) return {};
    return raw.cast<String, String>().map(
      (k, v) =>
          MapEntry(k, DateTime.tryParse(v)?.toUtc() ?? DateTime.utc(1970)),
    );
  }
}

// ---------------------------------------------------------------------------
// ServerWinsResolver
// ---------------------------------------------------------------------------

/// Always chooses the remote document, making the server authoritative.
///
/// Use this strategy when the server is the single source of truth and local
/// edits should never override a remote version (e.g. a read-mostly config
/// document managed by admins).
final class ServerWinsResolver<T> implements ConflictResolver<T> {
  /// Creates a [ServerWinsResolver].
  const ServerWinsResolver();

  @override
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async => remote;
}

// ---------------------------------------------------------------------------
// ClientWinsResolver
// ---------------------------------------------------------------------------

/// Always chooses the local document, making the client authoritative.
///
/// Use this strategy with fully optimistic UIs where any local edit is
/// considered final and remote changes should not overwrite in-progress work
/// (e.g. a draft editor).
final class ClientWinsResolver<T> implements ConflictResolver<T> {
  /// Creates a [ClientWinsResolver].
  const ClientWinsResolver();

  @override
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async => local;
}

// ---------------------------------------------------------------------------
// ManualConflictResolver
// ---------------------------------------------------------------------------

/// Defers conflict resolution to a user-supplied callback.
///
/// The [onConflict] callback receives both the local and remote maps and must
/// return the winning document. Use this to surface a conflict-resolution UI
/// (e.g. a diff dialog) to the end user.
///
/// ```dart
/// ManualConflictResolver(
///   onConflict: (local, remote) async {
///     final choice = await showConflictDialog(local, remote);
///     return choice == ConflictChoice.local ? local : remote;
///   },
/// )
/// ```
final class ManualConflictResolver<T> implements ConflictResolver<T> {
  /// Creates a [ManualConflictResolver] with the given [onConflict] callback.
  const ManualConflictResolver({required this.onConflict});

  /// Called whenever the sync engine detects a conflict.
  ///
  /// Must return the JSON map of the winning document.
  final Future<Map<String, dynamic>> Function(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  )
  onConflict;

  @override
  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) => onConflict(local, remote);
}
