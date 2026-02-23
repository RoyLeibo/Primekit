import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract backend for fetching and publishing activity feed items.
///
/// Implement this interface to connect `ActivityFeed` to any data source.
abstract interface class ActivityFeedSource {
  /// Fetches a page of raw feed item maps, ordered by timestamp descending.
  ///
  /// [page] — zero-based page index.
  /// [pageSize] — number of items per page.
  /// [userId] — when non-null, filters items by actor or target user.
  Future<List<Map<String, dynamic>>> fetchPage({
    required int page,
    required int pageSize,
    String? userId,
  });

  /// Returns a stream that emits raw maps for new items as they arrive.
  ///
  /// [userId] — when non-null, limits the stream to items for that user.
  Stream<Map<String, dynamic>> watchNewItems({String? userId});

  /// Publishes a raw feed item map to the backend.
  Future<void> publish(Map<String, dynamic> item);
}

// ---------------------------------------------------------------------------
// Firebase implementation
// ---------------------------------------------------------------------------

/// [ActivityFeedSource] backed by Cloud Firestore.
///
/// Items are stored in a Firestore `collection` ordered by
/// `timestamp` descending.
///
/// ```dart
/// final source = FirebaseActivityFeedSource();
/// ```
final class FirebaseActivityFeedSource implements ActivityFeedSource {
  /// Creates a [FirebaseActivityFeedSource].
  ///
  /// [firestore] defaults to [FirebaseFirestore.instance].
  FirebaseActivityFeedSource({
    FirebaseFirestore? firestore,
    String collection = 'activity_feed',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _collection = collection;

  final FirebaseFirestore _firestore;
  final String _collection;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ---------------------------------------------------------------------------
  // fetchPage
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> fetchPage({
    required int page,
    required int pageSize,
    String? userId,
  }) async {
    try {
      var query = _ref.orderBy('timestamp', descending: true).limit(pageSize);

      if (userId != null) {
        query = query.where('actorId', isEqualTo: userId);
      }

      // Simple offset pagination: skip `page * pageSize` docs.
      if (page > 0) {
        final previousSnapshot = await _ref
            .orderBy('timestamp', descending: true)
            .limit(page * pageSize)
            .get();
        if (previousSnapshot.docs.isNotEmpty) {
          query = query.startAfterDocument(previousSnapshot.docs.last);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList(growable: false);
    } catch (error) {
      throw Exception(
        'FirebaseActivityFeedSource.fetchPage failed (page: $page): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // watchNewItems
  // ---------------------------------------------------------------------------

  @override
  Stream<Map<String, dynamic>> watchNewItems({String? userId}) {
    final now = DateTime.now();
    var query = _ref
        .where('timestamp', isGreaterThan: now.toIso8601String())
        .orderBy('timestamp', descending: true);

    if (userId != null) {
      query = query.where('actorId', isEqualTo: userId);
    }

    return query.snapshots().expand(
      (qs) => qs.docChanges
          .where((c) => c.type == DocumentChangeType.added)
          .map((c) => {'id': c.doc.id, ...?c.doc.data()}),
    );
  }

  // ---------------------------------------------------------------------------
  // publish
  // ---------------------------------------------------------------------------

  @override
  Future<void> publish(Map<String, dynamic> item) async {
    try {
      await _ref.add(item);
    } catch (error) {
      throw Exception('FirebaseActivityFeedSource.publish failed: $error');
    }
  }
}
