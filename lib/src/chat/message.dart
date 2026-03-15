/// The type of a chat message.
enum MessageType {
  text,
  system;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Known system message types. Apps can define additional types as strings.
abstract final class SystemMessageTypes {
  static const String memberJoined = 'member_joined';
  static const String memberLeft = 'member_left';
  static const String groupCreated = 'group_created';
}

/// An immutable chat message.
class Message {
  const Message({
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

  /// For system messages, the type string (e.g. 'member_joined').
  /// Apps can define custom types beyond [SystemMessageTypes].
  final String? systemType;

  /// Optional metadata attached to the message (e.g. amount, currency).
  final Map<String, dynamic>? metadata;

  /// Emoji → list of user IDs who reacted.
  final Map<String, List<String>> reactions;

  /// Reply-to fields for threaded replies.
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;

  bool get isSystem => type == MessageType.system;
  bool get isReply => replyToId != null;
  bool get hasReactions => reactions.isNotEmpty;

  int get totalReactions =>
      reactions.values.fold(0, (sum, users) => sum + users.length);

  /// Validates that message content is non-empty and within limits.
  static bool isValidContent(String content) {
    final trimmed = content.trim();
    return trimmed.isNotEmpty && trimmed.length <= 5000;
  }

  Message copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? systemType,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      systemType: systemType ?? this.systemType,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Message && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
