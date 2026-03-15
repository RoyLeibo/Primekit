import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../chat/message_datasource.dart';

/// Firestore-backed typing indicator implementation.
///
/// Typing state stored at: `groups/{groupId}/typing/{userId}`
/// Users whose `typing_at` is within [_typingTimeout] are considered typing.
class FirestoreTypingDataSource implements TypingIndicatorDataSource {
  const FirestoreTypingDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  static const _typingTimeout = Duration(seconds: 5);

  CollectionReference<Map<String, dynamic>> _typingCollection(
    String groupId,
  ) =>
      firestore.collection('groups/$groupId/typing');

  @override
  Future<void> setTyping({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _typingCollection(groupId).doc(userId).set({
        'typing_at': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } on TimeoutException {
      // Write cached locally
    }
  }

  @override
  Future<void> clearTyping({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _typingCollection(groupId).doc(userId).delete().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } on TimeoutException {
      // Write cached locally
    }
  }

  @override
  Stream<List<String>> watchTypingUsers({
    required String groupId,
    required String currentUserId,
  }) {
    return _typingCollection(groupId).snapshots().map((snapshot) {
      final now = DateTime.now().toUtc();
      final typingUserIds = <String>[];

      for (final doc in snapshot.docs) {
        final userId = doc.id;
        if (userId == currentUserId) continue;

        final data = doc.data();
        final typingAt = data['typing_at'];
        if (typingAt == null) continue;

        DateTime typingTime;
        if (typingAt is Timestamp) {
          typingTime = typingAt.toDate().toUtc();
        } else {
          continue;
        }

        if (now.difference(typingTime) < _typingTimeout) {
          typingUserIds.add(userId);
        }
      }

      return typingUserIds;
    });
  }
}
