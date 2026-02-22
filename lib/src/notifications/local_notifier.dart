// Requires flutter_local_notifications (already in pubspec.yaml).
// Platform setup:
//   iOS:  Add UNUserNotificationCenter delegate in AppDelegate
//   Android: No extra setup beyond the manifest permissions added by the plugin

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/logger.dart';
import 'notification_channel.dart';

// ---------------------------------------------------------------------------
// Supporting types
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

// ---------------------------------------------------------------------------
// LocalNotifier
// ---------------------------------------------------------------------------

/// Schedules and delivers local notifications via [flutter_local_notifications].
///
/// ## Quick-start
///
/// ```dart
/// // 1. Initialize once (typically in main()):
/// await LocalNotifier.instance.initialize();
///
/// // 2. Show an immediate notification:
/// await LocalNotifier.instance.show(
///   id: 1,
///   title: 'Hello',
///   body: 'You have a new message.',
/// );
///
/// // 3. Schedule a future notification:
/// await LocalNotifier.instance.schedule(
///   id: 2,
///   title: 'Daily Reminder',
///   body: "Don't forget to check in!",
///   scheduledAt: DateTime.now().add(const Duration(hours: 1)),
/// );
///
/// // 4. Listen for taps:
/// LocalNotifier.instance.onTap.listen((tap) {
///   navigateTo(tap.payload);
/// });
/// ```
class LocalNotifier {
  LocalNotifier._();

  static final LocalNotifier _instance = LocalNotifier._();

  /// The shared singleton instance.
  static LocalNotifier get instance => _instance;

  static const String _tag = 'LocalNotifier';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final StreamController<NotificationTap> _tapController =
      StreamController<NotificationTap>.broadcast();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the notification plugin and registers Android channels.
  ///
  /// [channels] registers Android notification channels. Defaults to
  /// [NotificationChannel.general], [NotificationChannel.alerts], and
  /// [NotificationChannel.marketing].
  ///
  /// [requestPermission] controls whether iOS/macOS permission is requested
  /// on initialization (default `true`).
  Future<void> initialize({
    List<NotificationChannel> channels = const [
      NotificationChannel.general,
      NotificationChannel.alerts,
      NotificationChannel.marketing,
    ],
    bool requestPermission = true,
  }) async {
    if (_initialized) {
      PrimekitLogger.warning(
        'LocalNotifier.initialize() called more than once. Ignoring.',
        tag: _tag,
      );
      return;
    }

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: requestPermission,
      requestBadgePermission: requestPermission,
      requestSoundPermission: requestPermission,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    // Register Android notification channels.
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        for (final channel in channels) {
          await androidPlugin
              .createNotificationChannel(channel.toAndroidChannel());
        }
      }
    }

    _initialized = true;
    PrimekitLogger.info('LocalNotifier initialized.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Show
  // ---------------------------------------------------------------------------

  /// Shows an immediate notification.
  ///
  /// [id] must be unique per notification; reuse the same ID to update an
  /// existing notification.
  /// [channel] controls the Android channel (defaults to [NotificationChannel.general]).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationDetails? details,
  }) async {
    _assertInitialized('show');

    final notificationDetails = details ?? _buildDetails(channel);

    await _plugin.show(id, title, body, notificationDetails, payload: payload);
    PrimekitLogger.debug(
      'LocalNotifier: showed notification id=$id title="$title"',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  /// Schedules a notification for a future [scheduledAt] time.
  ///
  /// [repeats] + [repeatInterval] controls recurring notifications.
  /// When [repeats] is `true`, [repeatInterval] must be provided.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    bool repeats = false,
    RepeatInterval? repeatInterval,
    NotificationChannel channel = NotificationChannel.general,
    NotificationDetails? details,
  }) async {
    _assertInitialized('schedule');

    final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);
    final notificationDetails = details ?? _buildDetails(channel);

    if (repeats && repeatInterval != null) {
      await _plugin.periodicallyShowWithDuration(
        id,
        title,
        body,
        _toNativeDuration(repeatInterval),
        notificationDetails,
        payload: payload,
      );
    } else {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledAt,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    PrimekitLogger.debug(
      'LocalNotifier: scheduled notification id=$id '
      'at=${scheduledAt.toIso8601String()}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  /// Cancels the notification with [id].
  Future<void> cancel(int id) async {
    _assertInitialized('cancel');
    await _plugin.cancel(id);
    PrimekitLogger.debug(
      'LocalNotifier: cancelled notification id=$id',
      tag: _tag,
    );
  }

  /// Cancels all pending and displayed notifications.
  Future<void> cancelAll() async {
    _assertInitialized('cancelAll');
    await _plugin.cancelAll();
    PrimekitLogger.info('LocalNotifier: cancelled all notifications.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns all currently pending (scheduled) notifications.
  Future<List<PendingNotification>> getPending() async {
    _assertInitialized('getPending');

    final rawList = await _plugin.pendingNotificationRequests();
    return rawList
        .map(
          (r) => PendingNotification(
            id: r.id,
            title: r.title ?? '',
            body: r.body ?? '',
            payload: r.payload,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Tap stream
  // ---------------------------------------------------------------------------

  /// Emits a [NotificationTap] whenever the user taps a local notification.
  Stream<NotificationTap> get onTap => _tapController.stream;

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _onNotificationResponse(NotificationResponse response) {
    final tap = NotificationTap(
      id: response.id ?? -1,
      payload: response.payload,
    );
    _tapController.add(tap);
    PrimekitLogger.debug(
      'LocalNotifier: notification tapped id=${tap.id}',
      tag: _tag,
    );
  }

  NotificationDetails _buildDetails(NotificationChannel channel) =>
      NotificationDetails(
        android: channel.toAndroidDetails(),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Duration _toNativeDuration(RepeatInterval interval) => switch (interval) {
        RepeatInterval.everyMinute => const Duration(minutes: 1),
        RepeatInterval.hourly => const Duration(hours: 1),
        RepeatInterval.daily => const Duration(days: 1),
        RepeatInterval.weekly => const Duration(days: 7),
      };

  void _assertInitialized(String caller) {
    if (!_initialized) {
      throw StateError(
        'LocalNotifier.$caller() called before initialize(). '
        'Await LocalNotifier.instance.initialize() first.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets to uninitialised state.
  ///
  /// For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
  }
}

// Top-level background notification handler — must be a top-level function.
@pragma('vm:entry-point')
void _onBackgroundResponse(NotificationResponse response) {
  // Background tap handling — forward to your app's deep-link router.
  // This runs in a separate isolate so it cannot access singletons.
  // Typically you would store the payload and process it on next foreground.
}
