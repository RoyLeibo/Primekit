// Platform-agnostic notification channel configuration.
// Android channel registration is performed inside LocalNotifier.initialize()
// on the IO platform branch (local_notifier_io.dart).

/// Controls how prominently a notification is displayed.
///
/// Maps to Android's [NotificationManager importance levels][1] and
/// [flutter_local_notifications' Importance enum][2] at runtime.
///
/// [1]: https://developer.android.com/develop/ui/views/notifications#importance
/// [2]: https://pub.dev/documentation/flutter_local_notifications
enum PkNotificationImportance {
  /// Silent, no visual interruption.
  none,

  /// Low priority — shows in the shade but no sound or vibration.
  low,

  /// Default priority — sound and vibration at default volume.
  defaultImportance,

  /// High priority — heads-up notification that temporarily overlays the UI.
  high,

  /// Maximum priority — urgent alerts (use sparingly).
  max,
}

/// Describes an Android notification channel.
///
/// Notification channels are required on Android 8.0+ (API 26+). Each channel
/// defines a display name, importance level, and audio/vibration behaviour
/// that users can customise in system settings.
///
/// Pre-defined channels are provided as static constants. Create custom
/// channels via the constructor:
///
/// ```dart
/// const myChannel = NotificationChannel(
///   id: 'order_updates',
///   name: 'Order Updates',
///   description: 'Notifications about your orders.',
///   importance: PkNotificationImportance.high,
/// );
/// ```
final class NotificationChannel {
  /// Creates a notification channel definition.
  const NotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = PkNotificationImportance.defaultImportance,
    this.playSound = true,
    this.enableVibration = true,
    this.enableLights = false,
  });

  /// Unique channel identifier. Must be stable across app versions.
  final String id;

  /// User-visible channel name shown in system notification settings.
  final String name;

  /// Optional user-visible description of this channel's purpose.
  final String? description;

  /// The channel importance level, controlling how prominently notifications
  /// are shown. Defaults to [PkNotificationImportance.defaultImportance].
  final PkNotificationImportance importance;

  /// Whether notifications on this channel play a sound.
  final bool playSound;

  /// Whether notifications on this channel trigger vibration.
  final bool enableVibration;

  /// Whether notifications on this channel flash the device LED.
  final bool enableLights;

  // ---------------------------------------------------------------------------
  // Standard channels
  // ---------------------------------------------------------------------------

  /// General-purpose notifications (news, reminders, non-urgent updates).
  static const NotificationChannel general = NotificationChannel(
    id: 'general',
    name: 'General',
    description: 'General app notifications.',
    importance: PkNotificationImportance.defaultImportance,
    playSound: true,
    enableVibration: true,
  );

  /// Marketing and promotional messages.
  static const NotificationChannel marketing = NotificationChannel(
    id: 'marketing',
    name: 'Promotions',
    description: 'Offers, deals, and promotional content.',
    importance: PkNotificationImportance.low,
    playSound: false,
    enableVibration: false,
  );

  /// High-importance alerts requiring immediate attention.
  static const NotificationChannel alerts = NotificationChannel(
    id: 'alerts',
    name: 'Alerts',
    description: 'Critical alerts that require immediate attention.',
    importance: PkNotificationImportance.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  NotificationChannel copyWith({
    String? id,
    String? name,
    String? description,
    PkNotificationImportance? importance,
    bool? playSound,
    bool? enableVibration,
    bool? enableLights,
  }) => NotificationChannel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    importance: importance ?? this.importance,
    playSound: playSound ?? this.playSound,
    enableVibration: enableVibration ?? this.enableVibration,
    enableLights: enableLights ?? this.enableLights,
  );

  @override
  String toString() =>
      'NotificationChannel(id: $id, name: $name, '
      'importance: ${importance.name})';
}
