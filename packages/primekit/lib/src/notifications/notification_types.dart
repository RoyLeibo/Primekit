// Shared notification value types used across all platform implementations.

// ---------------------------------------------------------------------------
// PendingNotification
// ---------------------------------------------------------------------------

/// A pending scheduled notification.
final class PendingNotification {
  const PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.scheduledAt,
  });

  /// The notification ID.
  final int id;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// Optional payload string.
  final String? payload;

  /// When the notification is scheduled to fire. `null` for repeating ones
  /// where the next fire time is computed by the OS.
  final DateTime? scheduledAt;

  @override
  String toString() =>
      'PendingNotification(id: $id, title: $title, '
      'scheduledAt: $scheduledAt)';
}

// ---------------------------------------------------------------------------
// NotificationTap
// ---------------------------------------------------------------------------

/// Delivered when the user taps a local notification.
final class NotificationTap {
  const NotificationTap({required this.id, this.payload});

  /// ID of the notification that was tapped.
  final int id;

  /// The payload string set when the notification was scheduled.
  final String? payload;

  @override
  String toString() => 'NotificationTap(id: $id, payload: $payload)';
}
