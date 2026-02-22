import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/social/activity_feed.dart';

void main() {
  final now = DateTime.utc(2025, 1, 15, 12, 0, 0);

  group('FeedItem sealed variants', () {
    // -------------------------------------------------------------------------
    // All five variants constructable
    // -------------------------------------------------------------------------

    test('FeedItem.post is constructable', () {
      final item = FeedItem.post(
        id: 'post_1',
        actorId: 'user_1',
        timestamp: now,
        actorName: 'Alice',
      );
      expect(item, isA<PostFeedItem>());
      expect(item.id, 'post_1');
      expect(item.actorId, 'user_1');
      expect(item.timestamp, now);
      expect(item.actorName, 'Alice');
    });

    test('FeedItem.like is constructable', () {
      final item = FeedItem.like(
        id: 'like_1',
        actorId: 'user_1',
        timestamp: now,
        targetId: 'post_abc',
      );
      expect(item, isA<LikeFeedItem>());
      final like = item as LikeFeedItem;
      expect(like.targetId, 'post_abc');
    });

    test('FeedItem.follow is constructable', () {
      final item = FeedItem.follow(
        id: 'follow_1',
        actorId: 'user_1',
        timestamp: now,
        targetUserId: 'user_2',
      );
      expect(item, isA<FollowFeedItem>());
      final follow = item as FollowFeedItem;
      expect(follow.targetUserId, 'user_2');
    });

    test('FeedItem.comment is constructable', () {
      final item = FeedItem.comment(
        id: 'comment_1',
        actorId: 'user_1',
        timestamp: now,
        targetId: 'post_abc',
        text: 'Nice post!',
      );
      expect(item, isA<CommentFeedItem>());
      final comment = item as CommentFeedItem;
      expect(comment.targetId, 'post_abc');
      expect(comment.text, 'Nice post!');
    });

    test('FeedItem.custom is constructable', () {
      final item = FeedItem.custom(
        id: 'custom_1',
        actorId: 'user_1',
        timestamp: now,
        type: 'achievement_unlocked',
        metadata: const {'badge': 'gold'},
      );
      expect(item, isA<CustomFeedItem>());
      final custom = item as CustomFeedItem;
      expect(custom.type, 'achievement_unlocked');
      expect(custom.metadata['badge'], 'gold');
    });

    // -------------------------------------------------------------------------
    // Base fields accessible from sealed type
    // -------------------------------------------------------------------------

    test('base fields accessible on all variants', () {
      final items = <FeedItem>[
        FeedItem.post(id: 'p', actorId: 'a', timestamp: now),
        FeedItem.like(
          id: 'l',
          actorId: 'a',
          timestamp: now,
          targetId: 't',
        ),
        FeedItem.follow(
          id: 'f',
          actorId: 'a',
          timestamp: now,
          targetUserId: 'u2',
        ),
        FeedItem.comment(
          id: 'c',
          actorId: 'a',
          timestamp: now,
          targetId: 't',
          text: 'Hi',
        ),
        FeedItem.custom(
          id: 'cu',
          actorId: 'a',
          timestamp: now,
          type: 'evt',
        ),
      ];

      for (final item in items) {
        expect(item.actorId, 'a');
        expect(item.timestamp, now);
        expect(item.metadata, isEmpty);
      }
    });

    // -------------------------------------------------------------------------
    // Pattern matching
    // -------------------------------------------------------------------------

    test('pattern matching on sealed type is exhaustive', () {
      final FeedItem item = FeedItem.post(
        id: 'p1',
        actorId: 'u1',
        timestamp: now,
      );

      final label = switch (item) {
        PostFeedItem() => 'post',
        LikeFeedItem() => 'like',
        FollowFeedItem() => 'follow',
        CommentFeedItem() => 'comment',
        CustomFeedItem() => 'custom',
      };

      expect(label, 'post');
    });
  });
}
