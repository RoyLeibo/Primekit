import '../../core/exceptions.dart';
import '../../chat/message.dart';
import '../../chat/message_datasource.dart';
import '../../chat/message_read_status.dart';
import '../../chat/message_repository.dart';
import '../../core/logger.dart';

/// Firestore-backed [MessageRepository] with error mapping.
class FirestoreMessageRepository implements MessageRepository {
  const FirestoreMessageRepository({required this.dataSource});

  final MessageRemoteDataSource dataSource;

  static const _tag = 'ChatRepository';

  @override
  Future<Message> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) async {
    try {
      final model = await dataSource.sendMessage(
        groupId: groupId,
        senderId: senderId,
        content: content,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderId: replyToSenderId,
      );
      return model.toEntity();
    } catch (e, st) {
      PrimekitLogger.error('Failed to send message', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to send message', cause: e);
    }
  }

  @override
  Future<Message> sendSystemMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String systemType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final model = await dataSource.sendSystemMessage(
        groupId: groupId,
        senderId: senderId,
        content: content,
        systemType: systemType,
        metadata: metadata,
      );
      return model.toEntity();
    } catch (e, st) {
      PrimekitLogger.error('Failed to send system message', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to send system message', cause: e);
    }
  }

  @override
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await dataSource.toggleReaction(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
    } catch (e, st) {
      PrimekitLogger.error('Failed to toggle reaction', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to toggle reaction', cause: e);
    }
  }

  @override
  Stream<List<Message>> watchGroupMessages(String groupId, {int limit = 50}) {
    return dataSource.watchGroupMessages(groupId, limit: limit).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<List<Message>> fetchMessagesBefore({
    required String groupId,
    required DateTime before,
    int limit = 20,
  }) async {
    try {
      final models = await dataSource.fetchMessagesBefore(
        groupId: groupId,
        before: before,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (e, st) {
      PrimekitLogger.error('Failed to fetch messages', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to fetch messages', cause: e);
    }
  }

  @override
  Future<void> markAsRead({
    required String groupId,
    required String userId,
  }) async {
    try {
      await dataSource.markAsRead(groupId: groupId, userId: userId);
    } catch (e, st) {
      PrimekitLogger.error('Failed to mark as read', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to mark as read', cause: e);
    }
  }

  @override
  Stream<MessageReadStatus?> watchReadStatus({
    required String groupId,
    required String userId,
  }) {
    return dataSource
        .watchReadStatus(groupId: groupId, userId: userId)
        .map((model) => model?.toEntity());
  }

  @override
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  }) async {
    try {
      return await dataSource.getUnreadCount(
        groupId: groupId,
        userId: userId,
      );
    } catch (e, st) {
      PrimekitLogger.error('Failed to get unread count', tag: _tag, error: e, stackTrace: st);
      throw ChatException(message: 'Failed to get unread count', cause: e);
    }
  }
}
