// Abstract data source and service for follow/unfollow operations.
//
// This file has NO Firebase / cloud_firestore import so it can be re-exported
// from the social barrel without blocking any platform.
// FirebaseFollowSource requires cloud_firestore — import directly:
//   import 'package:primekit/src/social/follow_service.dart'
//       show FirebaseFollowSource;

// ---------------------------------------------------------------------------
// Abstract data source
// ---------------------------------------------------------------------------

/// Abstract backend for follow/unfollow operations.
abstract interface class FollowDataSource {
  /// Records that [followerId] is following [targetId].
  Future<void> follow({required String followerId, required String targetId});

  /// Removes the follow relationship from [followerId] to [targetId].
  Future<void> unfollow({required String followerId, required String targetId});

  /// Returns `true` when [followerId] is following [targetId].
  Future<bool> isFollowing({
    required String followerId,
    required String targetId,
  });

  /// Returns IDs of users following [userId].
  Future<List<String>> getFollowers(String userId, {int? limit});

  /// Returns IDs of users that [userId] is following.
  Future<List<String>> getFollowing(String userId, {int? limit});
}

// ---------------------------------------------------------------------------
// FollowService
// ---------------------------------------------------------------------------

/// High-level API for the follow/unfollow social graph.
///
/// ```dart
/// final service = FollowService(source: FirebaseFollowSource());
/// await service.follow(followerId: 'userA', targetId: 'userB');
/// final isFollowing = await service.isFollowing(
///   followerId: 'userA', targetId: 'userB',
/// );
/// ```
class FollowService {
  /// Creates a [FollowService] with the given [source].
  const FollowService({required FollowDataSource source}) : _source = source;

  final FollowDataSource _source;

  /// Records that [followerId] is following [targetId].
  Future<void> follow({required String followerId, required String targetId}) =>
      _source.follow(followerId: followerId, targetId: targetId);

  /// Removes the follow from [followerId] to [targetId].
  Future<void> unfollow({
    required String followerId,
    required String targetId,
  }) => _source.unfollow(followerId: followerId, targetId: targetId);

  /// Returns `true` when [followerId] is following [targetId].
  Future<bool> isFollowing({
    required String followerId,
    required String targetId,
  }) => _source.isFollowing(followerId: followerId, targetId: targetId);

  /// Returns the list of user IDs following [userId].
  Future<List<String>> getFollowers(String userId, {int? limit}) =>
      _source.getFollowers(userId, limit: limit);

  /// Returns the list of user IDs that [userId] is following.
  Future<List<String>> getFollowing(String userId, {int? limit}) =>
      _source.getFollowing(userId, limit: limit);
}
