/// Tracks when a user last read messages in a group.
class MessageReadStatus {
  const MessageReadStatus({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.lastReadAt,
    this.unreadCount = 0,
  });

  final String id;
  final String groupId;
  final String userId;
  final DateTime lastReadAt;
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MessageReadStatus && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
