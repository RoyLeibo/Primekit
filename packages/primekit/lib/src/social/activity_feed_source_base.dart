// Abstract backend for fetching and publishing activity feed items.
//
// This file has NO Firebase / cloud_firestore import so it can be re-exported
// from the social barrel without blocking any platform.
// FirebaseActivityFeedSource requires cloud_firestore — import directly:
//   import 'package:primekit/src/social/activity_feed_source.dart'
//       show FirebaseActivityFeedSource;

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
