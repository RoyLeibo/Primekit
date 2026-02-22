import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Abstract data source
// ---------------------------------------------------------------------------

/// Abstract backend for follow/unfollow operations.
abstract interface class FollowDataSource {
  /// Records that [followerId] is following [targetId].
  Future<void> follow({
    required String followerId,
    required String targetId,
  });

  /// Removes the follow relationship from [followerId] to [targetId].
  Future<void> unfollow({
    required String followerId,
    required String targetId,
  });

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
  Future<void> follow({
    required String followerId,
    required String targetId,
  }) =>
      _source.follow(followerId: followerId, targetId: targetId);

  /// Removes the follow from [followerId] to [targetId].
  Future<void> unfollow({
    required String followerId,
    required String targetId,
  }) =>
      _source.unfollow(followerId: followerId, targetId: targetId);

  /// Returns `true` when [followerId] is following [targetId].
  Future<bool> isFollowing({
    required String followerId,
    required String targetId,
  }) =>
      _source.isFollowing(followerId: followerId, targetId: targetId);

  /// Returns the list of user IDs following [userId].
  Future<List<String>> getFollowers(String userId, {int? limit}) =>
      _source.getFollowers(userId, limit: limit);

  /// Returns the list of user IDs that [userId] is following.
  Future<List<String>> getFollowing(String userId, {int? limit}) =>
      _source.getFollowing(userId, limit: limit);
}

// ---------------------------------------------------------------------------
// Firebase implementation
// ---------------------------------------------------------------------------

/// [FollowDataSource] backed by Cloud Firestore.
///
/// Follow documents are stored in two sub-collections per user:
/// - `users/{userId}/followers/{followerId}` — who follows the user.
/// - `users/{userId}/following/{targetId}` — who the user follows.
///
/// A root `follows` collection is also maintained for easy querying.
final class FirebaseFollowSource implements FollowDataSource {
  /// Creates a [FirebaseFollowSource].
  ///
  /// [firestore] defaults to [FirebaseFirestore.instance].
  FirebaseFollowSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // follow
  // ---------------------------------------------------------------------------

  @override
  Future<void> follow({
    required String followerId,
    required String targetId,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // users/{targetId}/followers/{followerId}
      // users/{followerId}/following/{targetId}
      // Root collection for cross-user queries.
      batch
        ..set(
          _followersDoc(targetId, followerId),
          {'followerId': followerId, 'createdAt': now},
        )
        ..set(
          _followingDoc(followerId, targetId),
          {'targetId': targetId, 'createdAt': now},
        )
        ..set(
          _followsCollection().doc('${followerId}_$targetId'),
          {
            'followerId': followerId,
            'targetId': targetId,
            'createdAt': now,
          },
        );

      await batch.commit();
    } catch (error) {
      throw Exception(
        'FirebaseFollowSource.follow failed '
        '($followerId → $targetId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // unfollow
  // ---------------------------------------------------------------------------

  @override
  Future<void> unfollow({
    required String followerId,
    required String targetId,
  }) async {
    try {
      final batch = _firestore.batch()
        ..delete(_followersDoc(targetId, followerId))
        ..delete(_followingDoc(followerId, targetId))
        ..delete(
          _followsCollection().doc('${followerId}_$targetId'),
        );
      await batch.commit();
    } catch (error) {
      throw Exception(
        'FirebaseFollowSource.unfollow failed '
        '($followerId → $targetId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // isFollowing
  // ---------------------------------------------------------------------------

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String targetId,
  }) async {
    try {
      final doc = await _followingDoc(followerId, targetId).get();
      return doc.exists;
    } catch (error) {
      throw Exception(
        'FirebaseFollowSource.isFollowing failed '
        '($followerId → $targetId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // getFollowers / getFollowing
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> getFollowers(String userId, {int? limit}) async {
    try {
      var query = _followersCollection(userId)
          .orderBy('createdAt', descending: true);
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs.map((d) => d.id).toList(growable: false);
    } catch (error) {
      throw Exception(
        'FirebaseFollowSource.getFollowers failed for "$userId": $error',
      );
    }
  }

  @override
  Future<List<String>> getFollowing(String userId, {int? limit}) async {
    try {
      var query = _followingCollection(userId)
          .orderBy('createdAt', descending: true);
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs.map((d) => d.id).toList(growable: false);
    } catch (error) {
      throw Exception(
        'FirebaseFollowSource.getFollowing failed for "$userId": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _followsCollection() =>
      _firestore.collection('follows');

  CollectionReference<Map<String, dynamic>> _followersCollection(
    String userId,
  ) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('followers');

  CollectionReference<Map<String, dynamic>> _followingCollection(
    String userId,
  ) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('following');

  DocumentReference<Map<String, dynamic>> _followersDoc(
    String userId,
    String followerId,
  ) =>
      _followersCollection(userId).doc(followerId);

  DocumentReference<Map<String, dynamic>> _followingDoc(
    String userId,
    String targetId,
  ) =>
      _followingCollection(userId).doc(targetId);
}
