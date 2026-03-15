import 'message_read_status.dart';

/// Data-transfer model for [MessageReadStatus] with map serialization.
class MessageReadStatusModel {
  const MessageReadStatusModel({
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

  factory MessageReadStatusModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return MessageReadStatusModel(
      id: documentId,
      groupId: data['group_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      lastReadAt: _parseDateTime(data['last_read_at']),
      unreadCount: data['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'last_read_at': lastReadAt,
      'unread_count': unreadCount,
    };
  }

  MessageReadStatus toEntity() {
    return MessageReadStatus(
      id: id,
      groupId: groupId,
      userId: userId,
      lastReadAt: lastReadAt,
      unreadCount: unreadCount,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now().toUtc();
  }
}
