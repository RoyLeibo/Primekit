import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../sync_data_source.dart';

/// A [SyncDataSource] backed by Google Cloud Firestore.
///
/// Leverages Firestore's native offline persistence for additional resilience
/// on top of Primekit's own offline-first layer.
///
/// **Setup**
///
/// 1. Add `firebase_core` and `cloud_firestore` to your `pubspec.yaml`.
/// 2. Call `await Firebase.initializeApp()` in `main()`.
/// 3. Pass a [FirestoreSyncSource] instance to [SyncRepository].
///
/// ```dart
/// final repo = SyncRepository<Todo>(
///   collection: 'todos',
///   remoteSource: FirestoreSyncSource(),
///   fromJson: Todo.fromJson,
/// );
/// ```
///
/// **User-scoped collections**
///
/// When [userId] is provided to read/write methods, every document is
/// written under `users/{userId}/{collection}/{documentId}` so that
/// Firestore security rules can enforce row-level user isolation.
final class FirestoreSyncSource implements SyncDataSource {
  /// Creates a [FirestoreSyncSource].
  ///
  /// [firestore] defaults to [FirebaseFirestore.instance]; supply a custom
  /// instance for testing.
  ///
  /// [timestampField] is the Firestore field name that stores the
  /// last-modified timestamp on each document (default: `'updatedAt'`).
  FirestoreSyncSource({
    FirebaseFirestore? firestore,
    this.timestampField = 'updatedAt',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore field name used for incremental fetch queries.
  final String timestampField;

  @override
  String get providerId => 'firestore';

  // ---------------------------------------------------------------------------
  // Collection resolution
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _collectionRef(
    String collection, {
    String? userId,
  }) {
    if (userId != null && userId.isNotEmpty) {
      return _firestore.collection('users').doc(userId).collection(collection);
    }
    return _firestore.collection(collection);
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> fetchChanges({
    required String collection,
    DateTime? since,
    String? userId,
  }) async {
    final ref = _collectionRef(collection, userId: userId);

    Query<Map<String, dynamic>> query = ref;
    if (since != null) {
      query = query.where(
        timestampField,
        isGreaterThan: Timestamp.fromDate(since),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_docToMap).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String collection,
    String? userId,
  }) {
    return _collectionRef(
      collection,
      userId: userId,
    ).snapshots().map((snap) => snap.docs.map(_docToMap).toList());
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<void> pushChange({
    required String collection,
    required Map<String, dynamic> document,
    required SyncOperation operation,
  }) async {
    final id = document['id'] as String?;
    if (id == null) {
      throw ArgumentError(
        'FirestoreSyncSource.pushChange: document must contain an "id" field.',
      );
    }

    // Extract userId from the document if present for user-scoped collections
    final userId = document['userId'] as String?;
    final ref = _collectionRef(collection, userId: userId).doc(id);

    switch (operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        final payload = _preparePayload(document);
        await ref.set(payload, SetOptions(merge: true));
      case SyncOperation.delete:
        // Honour soft-delete flag if present; hard-delete otherwise
        final isDeleted = document['isDeleted'] as bool? ?? false;
        if (isDeleted) {
          // Write the soft-delete marker so other clients can sync the deletion
          await ref.set({
            'isDeleted': true,
            timestampField: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await ref.delete();
        }
    }
  }

  @override
  Future<void> pushBatch({
    required String collection,
    required List<SyncChange> changes,
  }) async {
    // Firestore batches are limited to 500 operations; split if needed.
    const batchLimit = 500;
    final batches = <WriteBatch>[];

    for (var i = 0; i < changes.length; i += batchLimit) {
      final chunk = changes.sublist(
        i,
        (i + batchLimit).clamp(0, changes.length),
      );
      final batch = _firestore.batch();

      for (final change in chunk) {
        final id = change.id;
        final doc = change.document;
        final userId = doc['userId'] as String?;
        final ref = _collectionRef(collection, userId: userId).doc(id);

        switch (change.operation) {
          case SyncOperation.create:
          case SyncOperation.update:
            batch.set(ref, _preparePayload(doc), SetOptions(merge: true));
          case SyncOperation.delete:
            final isDeleted = doc['isDeleted'] as bool? ?? false;
            if (isDeleted) {
              batch.set(ref, {
                'isDeleted': true,
                timestampField: FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } else {
              batch.delete(ref);
            }
        }
      }

      batches.add(batch);
    }

    await Future.wait(batches.map((b) => b.commit()));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _docToMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // Normalise Firestore Timestamp → ISO-8601 string for portability
    return _normaliseTimestamps({...data, 'id': doc.id});
  }

  Map<String, dynamic> _normaliseTimestamps(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toUtc().toIso8601String());
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _normaliseTimestamps(value));
      }
      return MapEntry(key, value);
    });
  }

  Map<String, dynamic> _preparePayload(Map<String, dynamic> document) {
    // Replace 'updatedAt' with a server timestamp for accuracy
    return {...document, timestampField: FieldValue.serverTimestamp()};
  }
}
