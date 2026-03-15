import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../chat/message.dart';
import '../../chat/message_datasource.dart';
import '../../chat/message_model.dart';
import '../../chat/message_read_status_model.dart';

/// Firestore-backed implementation of [MessageRemoteDataSource].
///
/// Messages: `groups/{groupId}/messages/{messageId}`
/// Read status: `message_read_status/{groupId}_{userId}`
class FirestoreMessageDataSource implements MessageRemoteDataSource {
  const FirestoreMessageDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String groupId,
  ) =>
      firestore.collection('groups/$groupId/messages');

  CollectionReference<Map<String, dynamic>> get _readStatusCollection =>
      firestore.collection('message_read_status');

  String _readStatusDocId(String groupId, String userId) =>
      '${groupId}_$userId';

  @override
  Future<MessageModel> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) async {
    final now = DateTime.now().toUtc();
    final docRef = _messagesCollection(groupId).doc();

    final model = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: senderId,
      content: content.trim(),
      type: MessageType.text,
      createdAt: now,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderId: replyToSenderId,
    );

    final data = model.toMap();
    data['created_at'] = Timestamp.fromDate(now);

    try {
      await docRef.set(data).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } on TimeoutException {
      // Write cached locally by Firestore, will sync later
    }

    return model;
  }

  @override
  Future<MessageModel> sendSystemMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String systemType,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now().toUtc();
    final docRef = _messagesCollection(groupId).doc();

    final model = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: senderId,
      content: content,
      type: MessageType.system,
      createdAt: now,
      systemType: systemType,
      metadata: metadata,
    );

    final data = model.toMap();
    data['created_at'] = Timestamp.fromDate(now);

    try {
      await docRef.set(data).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } on TimeoutException {
      // Write cached locally
    }

    return model;
  }

  @override
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final docRef = _messagesCollection(groupId).doc(messageId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reactions = Map<String, dynamic>.from(
        (data['reactions'] as Map<String, dynamic>?) ?? {},
      );

      final userList = List<String>.from(
        (reactions[emoji] as List?)?.cast<String>() ?? [],
      );

      if (userList.contains(userId)) {
        userList.remove(userId);
      } else {
        userList.add(userId);
      }

      if (userList.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = userList;
      }

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  @override
  Stream<List<MessageModel>> watchGroupMessages(
    String groupId, {
    int limit = 50,
  }) {
    return _messagesCollection(groupId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        // Convert Timestamp → DateTime for the model
        final createdAt = data['created_at'];
        if (createdAt is Timestamp) {
          data['created_at'] = createdAt.toDate().toUtc();
        }
        return MessageModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  @override
  Future<List<MessageModel>> fetchMessagesBefore({
    required String groupId,
    required DateTime before,
    int limit = 20,
  }) async {
    final snapshot = await _messagesCollection(groupId)
        .orderBy('created_at', descending: true)
        .where('created_at', isLessThan: Timestamp.fromDate(before))
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      final createdAt = data['created_at'];
      if (createdAt is Timestamp) {
        data['created_at'] = createdAt.toDate().toUtc();
      }
      return MessageModel.fromMap(data, doc.id);
    }).toList();
  }

  @override
  Future<void> markAsRead({
    required String groupId,
    required String userId,
  }) async {
    final docId = _readStatusDocId(groupId, userId);
    final now = DateTime.now().toUtc();

    try {
      await _readStatusCollection.doc(docId).set(
        {
          'group_id': groupId,
          'user_id': userId,
          'last_read_at': Timestamp.fromDate(now),
          'unread_count': 0,
        },
        SetOptions(merge: true),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } on TimeoutException {
      // Write cached locally
    }
  }

  @override
  Stream<MessageReadStatusModel?> watchReadStatus({
    required String groupId,
    required String userId,
  }) {
    final docId = _readStatusDocId(groupId, userId);

    return _readStatusCollection.doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      final lastReadAt = data['last_read_at'];
      if (lastReadAt is Timestamp) {
        data['last_read_at'] = lastReadAt.toDate().toUtc();
      }
      return MessageReadStatusModel.fromMap(data, snapshot.id);
    });
  }

  @override
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  }) async {
    final docId = _readStatusDocId(groupId, userId);
    final doc = await _readStatusCollection.doc(docId).get();

    if (!doc.exists || doc.data() == null) {
      final messagesSnapshot =
          await _messagesCollection(groupId).count().get();
      return messagesSnapshot.count ?? 0;
    }

    final data = doc.data()!;
    final lastReadAt = (data['last_read_at'] as Timestamp).toDate().toUtc();

    final unreadSnapshot = await _messagesCollection(groupId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(lastReadAt))
        .count()
        .get();

    return unreadSnapshot.count ?? 0;
  }

  @override
  Stream<Map<String, int>> watchUnreadCounts({
    required String userId,
    required List<String> groupIds,
  }) {
    if (groupIds.isEmpty) return Stream.value({});

    final docIds = groupIds
        .map((groupId) => _readStatusDocId(groupId, userId))
        .toList();

    final query = _readStatusCollection.where(
      FieldPath.documentId,
      whereIn: docIds.take(30).toList(),
    );

    return query.snapshots().map((snapshot) {
      final readStatusMap = <String, DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final groupId = data['group_id'] as String;
        final lastReadAt =
            (data['last_read_at'] as Timestamp).toDate().toUtc();
        readStatusMap[groupId] = lastReadAt;
      }

      final result = <String, int>{};
      for (final groupId in groupIds) {
        result[groupId] = readStatusMap.containsKey(groupId) ? 0 : -1;
      }
      return result;
    });
  }
}
