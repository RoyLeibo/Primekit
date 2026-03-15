import '../core/exceptions.dart';
import '../core/logger.dart';
import 'message.dart';
import 'message_repository.dart';

/// High-level chat operations with validation.
///
/// Delegates to [MessageRepository] for persistence. Apps can extend this
/// to add domain-specific system messages (e.g. expense notifications).
class ChatService {
  const ChatService({required MessageRepository repository})
      : _repository = repository;

  final MessageRepository _repository;

  static const _tag = 'ChatService';

  /// Sends a validated text message.
  Future<Message> sendTextMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) async {
    final trimmed = content.trim();
    if (!Message.isValidContent(trimmed)) {
      throw const MessageValidationException(
        message: 'Message content is empty or too long',
      );
    }

    return _repository.sendMessage(
      groupId: groupId,
      senderId: senderId,
      content: trimmed,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderId: replyToSenderId,
    );
  }

  /// Sends a generic system message. Apps define their own system types.
  Future<Message> sendSystemMessage({
    required String groupId,
    required String senderId,
    required String content,
    required String systemType,
    Map<String, dynamic>? metadata,
  }) {
    return _repository.sendSystemMessage(
      groupId: groupId,
      senderId: senderId,
      content: content,
      systemType: systemType,
      metadata: metadata,
    );
  }

  /// Convenience: sends a "member joined" system message.
  Future<Message> sendMemberJoinedMessage({
    required String groupId,
    required String userId,
    String? displayName,
  }) {
    PrimekitLogger.debug('Sending member joined message', tag: _tag);
    final name = displayName ?? 'A member';
    return sendSystemMessage(
      groupId: groupId,
      senderId: userId,
      content: '$name joined the group',
      systemType: SystemMessageTypes.memberJoined,
    );
  }

  /// Convenience: sends a "member left" system message.
  Future<Message> sendMemberLeftMessage({
    required String groupId,
    required String userId,
    String? displayName,
  }) {
    PrimekitLogger.debug('Sending member left message', tag: _tag);
    final name = displayName ?? 'A member';
    return sendSystemMessage(
      groupId: groupId,
      senderId: userId,
      content: '$name left the group',
      systemType: SystemMessageTypes.memberLeft,
    );
  }
}
