import 'message.dart';
import 'message_read_status.dart';

/// Abstract repository interface for chat message operations.
///
/// Implementations handle error mapping and data transformation.
/// See [FirestoreMessageRepository] for the Firestore-backed implementation.
abstract class MessageRepository {
  /// Sends a text message in a group.
  Future<Message> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  });

  /// Sends a system message in a group.
  Future<Message> sendSystemMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String systemType,
    Map<String, dynamic>? metadata,
  });

  /// Toggles a reaction emoji on a message.
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// Real-time stream of messages for a group, newest first.
  Stream<List<Message>> watchGroupMessages(String groupId, {int limit = 50});

  /// Fetches older messages before a timestamp for pagination.
  Future<List<Message>> fetchMessagesBefore({
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
  Stream<MessageReadStatus?> watchReadStatus({
    required String groupId,
    required String userId,
  });

  /// Returns the unread message count for a user in a group.
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  });
}
