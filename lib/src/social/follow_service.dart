import 'package:cloud_firestore/cloud_firestore.dart';

import 'follow_service_base.dart';

export 'follow_service_base.dart';

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
        ..set(_followersDoc(targetId, followerId), {
          'followerId': followerId,
          'createdAt': now,
        })
        ..set(_followingDoc(followerId, targetId), {
          'targetId': targetId,
          'createdAt': now,
        })
        ..set(_followsCollection().doc('${followerId}_$targetId'), {
          'followerId': followerId,
          'targetId': targetId,
          'createdAt': now,
        });

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
        ..delete(_followsCollection().doc('${followerId}_$targetId'));
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
      var query = _followersCollection(
        userId,
      ).orderBy('createdAt', descending: true);
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
      var query = _followingCollection(
        userId,
      ).orderBy('createdAt', descending: true);
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
  ) => _firestore.collection('users').doc(userId).collection('followers');

  CollectionReference<Map<String, dynamic>> _followingCollection(
    String userId,
  ) => _firestore.collection('users').doc(userId).collection('following');

  DocumentReference<Map<String, dynamic>> _followersDoc(
    String userId,
    String followerId,
  ) => _followersCollection(userId).doc(followerId);

  DocumentReference<Map<String, dynamic>> _followingDoc(
    String userId,
    String targetId,
  ) => _followingCollection(userId).doc(targetId);
}
