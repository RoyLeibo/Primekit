import 'activity_feed_source_base.dart';

// ---------------------------------------------------------------------------
// FeedItem — sealed hierarchy
// ---------------------------------------------------------------------------

/// Base type for all activity feed items.
///
/// The five concrete subtypes cover the most common social actions:
/// - [PostFeedItem] — user published a post.
/// - [LikeFeedItem] — user liked something.
/// - [FollowFeedItem] — user followed another user.
/// - [CommentFeedItem] — user commented on something.
/// - [CustomFeedItem] — arbitrary event type.
///
/// ```dart
/// final item = FeedItem.post(
///   id: 'feed_1',
///   actorId: 'user_1',
///   timestamp: DateTime.now(),
/// );
/// ```
sealed class FeedItem {
  /// Base constructor shared by all subtypes.
  const FeedItem({
    required this.id,
    required this.actorId,
    required this.timestamp,
    this.actorName,
    this.actorAvatarUrl,
    this.metadata = const {},
  });

  /// Creates a [PostFeedItem].
  const factory FeedItem.post({
    required String id,
    required String actorId,
    required DateTime timestamp,
    String? actorName,
    String? actorAvatarUrl,
    Map<String, dynamic> metadata,
  }) = PostFeedItem;

  /// Creates a [LikeFeedItem].
  const factory FeedItem.like({
    required String id,
    required String actorId,
    required DateTime timestamp,
    required String targetId,
    String? actorName,
    String? actorAvatarUrl,
    Map<String, dynamic> metadata,
  }) = LikeFeedItem;

  /// Creates a [FollowFeedItem].
  const factory FeedItem.follow({
    required String id,
    required String actorId,
    required DateTime timestamp,
    required String targetUserId,
    String? actorName,
    String? actorAvatarUrl,
    Map<String, dynamic> metadata,
  }) = FollowFeedItem;

  /// Creates a [CommentFeedItem].
  const factory FeedItem.comment({
    required String id,
    required String actorId,
    required DateTime timestamp,
    required String targetId,
    required String text,
    String? actorName,
    String? actorAvatarUrl,
    Map<String, dynamic> metadata,
  }) = CommentFeedItem;

  /// Creates a [CustomFeedItem].
  const factory FeedItem.custom({
    required String id,
    required String actorId,
    required DateTime timestamp,
    required String type,
    String? actorName,
    String? actorAvatarUrl,
    Map<String, dynamic> metadata,
  }) = CustomFeedItem;

  /// Unique feed item ID.
  final String id;

  /// ID of the user who performed the action.
  final String actorId;

  /// When the activity occurred.
  final DateTime timestamp;

  /// Display name of the actor at the time of the action.
  final String? actorName;

  /// Avatar URL of the actor at the time of the action.
  final String? actorAvatarUrl;

  /// Arbitrary extra data for rendering or analytics.
  final Map<String, dynamic> metadata;
}

// ---------------------------------------------------------------------------
// Concrete subtypes
// ---------------------------------------------------------------------------

/// A post-publication feed event.
final class PostFeedItem extends FeedItem {
  /// Creates a [PostFeedItem].
  const PostFeedItem({
    required super.id,
    required super.actorId,
    required super.timestamp,
    super.actorName,
    super.actorAvatarUrl,
    super.metadata,
  });
}

/// A like event on a target item.
final class LikeFeedItem extends FeedItem {
  /// Creates a [LikeFeedItem].
  const LikeFeedItem({
    required super.id,
    required super.actorId,
    required super.timestamp,
    required this.targetId,
    super.actorName,
    super.actorAvatarUrl,
    super.metadata,
  });

  /// ID of the item that was liked.
  final String targetId;
}

/// A follow event.
final class FollowFeedItem extends FeedItem {
  /// Creates a [FollowFeedItem].
  const FollowFeedItem({
    required super.id,
    required super.actorId,
    required super.timestamp,
    required this.targetUserId,
    super.actorName,
    super.actorAvatarUrl,
    super.metadata,
  });

  /// ID of the user who was followed.
  final String targetUserId;
}

/// A comment event on a target item.
final class CommentFeedItem extends FeedItem {
  /// Creates a [CommentFeedItem].
  const CommentFeedItem({
    required super.id,
    required super.actorId,
    required super.timestamp,
    required this.targetId,
    required this.text,
    super.actorName,
    super.actorAvatarUrl,
    super.metadata,
  });

  /// ID of the item that was commented on.
  final String targetId;

  /// The comment text.
  final String text;
}

/// A custom / arbitrary feed event.
final class CustomFeedItem extends FeedItem {
  /// Creates a [CustomFeedItem].
  const CustomFeedItem({
    required super.id,
    required super.actorId,
    required super.timestamp,
    required this.type,
    super.actorName,
    super.actorAvatarUrl,
    super.metadata,
  });

  /// Application-defined event type string.
  final String type;
}

// ---------------------------------------------------------------------------
// ActivityFeed
// ---------------------------------------------------------------------------

/// Manages paginated loading and real-time streaming of [FeedItem]s.
///
/// ```dart
/// final feed = ActivityFeed(source: FirebaseActivityFeedSource());
/// final page0 = await feed.loadPage(0);
/// feed.newItems.listen((item) => print('New: ${item.actorId}'));
/// ```
class ActivityFeed {
  /// Creates an [ActivityFeed] backed by [source].
  ///
  /// [pageSize] — number of items returned per [loadPage] call.
  ActivityFeed({required ActivityFeedSource source, this.pageSize = 20})
    : _source = source;

  final ActivityFeedSource _source;

  /// Number of items returned per page.
  final int pageSize;

  // ---------------------------------------------------------------------------
  // loadPage
  // ---------------------------------------------------------------------------

  /// Loads a page of [FeedItem]s.
  ///
  /// [page] — zero-based page index.
  Future<List<FeedItem>> loadPage(int page) async {
    final rawList = await _source.fetchPage(page: page, pageSize: pageSize);
    return rawList.map(_fromMap).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // newItems
  // ---------------------------------------------------------------------------

  /// Stream of new [FeedItem]s arriving in real time.
  Stream<FeedItem> get newItems => _source.watchNewItems().map(_fromMap);

  // ---------------------------------------------------------------------------
  // publishItem
  // ---------------------------------------------------------------------------

  /// Publishes [item] to the backend.
  Future<void> publishItem(FeedItem item) => _source.publish(_toMap(item));

  // ---------------------------------------------------------------------------
  // Private serialisation helpers
  // ---------------------------------------------------------------------------

  static FeedItem _fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    final actorId = map['actorId'] as String? ?? '';
    final actorName = map['actorName'] as String?;
    final actorAvatarUrl = map['actorAvatarUrl'] as String?;
    final timestamp = map['timestamp'] is String
        ? DateTime.parse(map['timestamp'] as String)
        : DateTime.now();
    final metadata = (map['metadata'] as Map<String, dynamic>?) ?? {};
    final type = map['type'] as String? ?? 'custom';

    switch (type) {
      case 'post':
        return FeedItem.post(
          id: id,
          actorId: actorId,
          timestamp: timestamp,
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          metadata: metadata,
        );
      case 'like':
        return FeedItem.like(
          id: id,
          actorId: actorId,
          timestamp: timestamp,
          targetId: map['targetId'] as String? ?? '',
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          metadata: metadata,
        );
      case 'follow':
        return FeedItem.follow(
          id: id,
          actorId: actorId,
          timestamp: timestamp,
          targetUserId: map['targetUserId'] as String? ?? '',
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          metadata: metadata,
        );
      case 'comment':
        return FeedItem.comment(
          id: id,
          actorId: actorId,
          timestamp: timestamp,
          targetId: map['targetId'] as String? ?? '',
          text: map['text'] as String? ?? '',
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          metadata: metadata,
        );
      default:
        return FeedItem.custom(
          id: id,
          actorId: actorId,
          timestamp: timestamp,
          type: type,
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          metadata: metadata,
        );
    }
  }

  static Map<String, dynamic> _toMap(FeedItem item) {
    final base = <String, dynamic>{
      'id': item.id,
      'actorId': item.actorId,
      'timestamp': item.timestamp.toIso8601String(),
      'metadata': item.metadata,
      if (item.actorName != null) 'actorName': item.actorName,
      if (item.actorAvatarUrl != null) 'actorAvatarUrl': item.actorAvatarUrl,
    };

    switch (item) {
      case PostFeedItem():
        return {...base, 'type': 'post'};
      case LikeFeedItem():
        return {...base, 'type': 'like', 'targetId': item.targetId};
      case FollowFeedItem():
        return {...base, 'type': 'follow', 'targetUserId': item.targetUserId};
      case CommentFeedItem():
        return {
          ...base,
          'type': 'comment',
          'targetId': item.targetId,
          'text': item.text,
        };
      case CustomFeedItem():
        return {...base, 'type': item.type};
    }
  }
}
