// Requires flutter_local_notifications (already in pubspec.yaml).
// Android channel configuration is applied during LocalNotifier.initialize().

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
///   importance: Importance.high,
/// );
/// ```
final class NotificationChannel {
  /// Creates a notification channel definition.
  const NotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = Importance.defaultImportance,
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
  /// are shown. Defaults to [Importance.defaultImportance].
  final Importance importance;

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
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
  );

  /// Marketing and promotional messages.
  static const NotificationChannel marketing = NotificationChannel(
    id: 'marketing',
    name: 'Promotions',
    description: 'Offers, deals, and promotional content.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  /// High-importance alerts requiring immediate attention.
  static const NotificationChannel alerts = NotificationChannel(
    id: 'alerts',
    name: 'Alerts',
    description: 'Critical alerts that require immediate attention.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  /// Converts this definition to an [AndroidNotificationChannel] for
  /// registration via [FlutterLocalNotificationsPlugin].
  AndroidNotificationChannel toAndroidChannel() => AndroidNotificationChannel(
    id,
    name,
    description: description,
    importance: importance,
    playSound: playSound,
    enableVibration: enableVibration,
    enableLights: enableLights,
  );

  /// Returns an [AndroidNotificationDetails] preset for this channel.
  AndroidNotificationDetails toAndroidDetails({
    String? ticker,
    StyleInformation? styleInformation,
  }) => AndroidNotificationDetails(
    id,
    name,
    channelDescription: description,
    importance: importance,
    priority: importance == Importance.high
        ? Priority.high
        : Priority.defaultPriority,
    playSound: playSound,
    enableVibration: enableVibration,
    enableLights: enableLights,
    ticker: ticker,
    styleInformation: styleInformation,
  );

  /// Returns a copy with the given fields replaced.
  NotificationChannel copyWith({
    String? id,
    String? name,
    String? description,
    Importance? importance,
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
