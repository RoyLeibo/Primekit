import 'message.dart';
import 'message_model.dart';
import 'message_read_status_model.dart';

/// Abstract interface for remote message data operations.
///
/// Concrete implementations (e.g. [FirestoreMessageDataSource]) handle
/// the actual storage backend.
abstract class MessageRemoteDataSource {
  /// Creates a new text message.
  Future<MessageModel> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  });

  /// Creates a system message.
  Future<MessageModel> sendSystemMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String systemType,
    Map<String, dynamic>? metadata,
  });

  /// Toggles a reaction on a message.
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// Real-time stream of messages for a group, newest first.
  Stream<List<MessageModel>> watchGroupMessages(
    String groupId, {
    int limit = 50,
  });

  /// Fetches older messages for pagination.
  Future<List<MessageModel>> fetchMessagesBefore({
    required String groupId,
    required DateTime before,
    int limit = 20,
  });

  /// Marks a group's chat as read for a user.
  Future<void> markAsRead({
    required String groupId,
    required String userId,
  });

  /// Real-time stream of read status for a user in a group.
  Stream<MessageReadStatusModel?> watchReadStatus({
    required String groupId,
    required String userId,
  });

  /// Returns the unread message count for a user in a group.
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  });

  /// Real-time stream of unread counts across multiple groups.
  Stream<Map<String, int>> watchUnreadCounts({
    required String userId,
    required List<String> groupIds,
  });
}

/// Abstract interface for typing indicator operations.
abstract class TypingIndicatorDataSource {
  /// Sets a user as typing in a group.
  Future<void> setTyping({
    required String groupId,
    required String userId,
  });

  /// Clears a user's typing status.
  Future<void> clearTyping({
    required String groupId,
    required String userId,
  });

  /// Real-time stream of user IDs currently typing (excludes current user).
  Stream<List<String>> watchTypingUsers({
    required String groupId,
    required String currentUserId,
  });
}
