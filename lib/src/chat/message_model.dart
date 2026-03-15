import 'message.dart';

/// Data-transfer model for [Message] with map serialization.
///
/// Firestore-specific `Timestamp` conversion is handled in the
/// Firebase layer ([FirestoreMessageDataSource]).
class MessageModel {
  const MessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.systemType,
    this.metadata,
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? systemType;
  final Map<String, dynamic>? metadata;
  final Map<String, List<String>> reactions;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      groupId: data['group_id'] as String? ?? '',
      senderId: data['sender_id'] as String? ?? '',
      content: data['content'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String? ?? 'text'),
      createdAt: _parseDateTime(data['created_at']),
      systemType: data['system_type'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      reactions: _parseReactions(data['reactions']),
      replyToId: data['reply_to_id'] as String?,
      replyToContent: data['reply_to_content'] as String?,
      replyToSenderId: data['reply_to_sender_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'created_at': createdAt,
      if (systemType != null) 'system_type': systemType,
      if (metadata != null) 'metadata': metadata,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
      if (replyToSenderId != null) 'reply_to_sender_id': replyToSenderId,
    };
  }

  Message toEntity() {
    return Message(
      id: id,
      groupId: groupId,
      senderId: senderId,
      content: content,
      type: type,
      createdAt: createdAt,
      systemType: systemType,
      metadata: metadata,
      reactions: reactions,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderId: replyToSenderId,
    );
  }

  factory MessageModel.fromEntity(Message entity) {
    return MessageModel(
      id: entity.id,
      groupId: entity.groupId,
      senderId: entity.senderId,
      content: entity.content,
      type: entity.type,
      createdAt: entity.createdAt,
      systemType: entity.systemType,
      metadata: entity.metadata,
      reactions: entity.reactions,
      replyToId: entity.replyToId,
      replyToContent: entity.replyToContent,
      replyToSenderId: entity.replyToSenderId,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now().toUtc();
  }

  static Map<String, List<String>> _parseReactions(dynamic data) {
    if (data == null || data is! Map) return {};
    final result = <String, List<String>>{};
    for (final entry in (data as Map<String, dynamic>).entries) {
      if (entry.value is List) {
        result[entry.key] = List<String>.from(
          (entry.value as List).whereType<String>(),
        );
      }
    }
    return result;
  }
}
