import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_types.dart';

export 'notification_types.dart';

// ---------------------------------------------------------------------------
// LocalNotifier (stub)
// ---------------------------------------------------------------------------

/// No-op [LocalNotifier] stub for platforms that do not support
/// `flutter_local_notifications` (Windows, Linux).
///
/// All methods log a warning and return safe defaults.
class LocalNotifier {
  LocalNotifier._();

  static final LocalNotifier _instance = LocalNotifier._();

  /// The shared singleton instance.
  static LocalNotifier get instance => _instance;

  final StreamController<NotificationTap> _tapController =
      StreamController<NotificationTap>.broadcast();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// No-op on this platform.
  Future<void> initialize({
    List<Object> channels = const [],
    bool requestPermission = true,
  }) async {
    debugPrint(
      '[Primekit] LocalNotifier: notifications not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Show / Schedule
  // ---------------------------------------------------------------------------

  /// No-op on this platform.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    Object? channel,
    Object? details,
  }) async {
    debugPrint(
      '[Primekit] LocalNotifier.show: notifications not supported on this platform.',
    );
  }

  /// No-op on this platform.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    bool repeats = false,
    Object? repeatInterval,
    Object? channel,
    Object? details,
  }) async {
    debugPrint(
      '[Primekit] LocalNotifier.schedule: notifications not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  /// No-op on this platform.
  Future<void> cancel(int id) async {
    debugPrint(
      '[Primekit] LocalNotifier.cancel: notifications not supported on this platform.',
    );
  }

  /// No-op on this platform.
  Future<void> cancelAll() async {
    debugPrint(
      '[Primekit] LocalNotifier.cancelAll: notifications not supported on this platform.',
    );
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Always returns an empty list on this platform.
  Future<List<PendingNotification>> getPending() async => const [];

  // ---------------------------------------------------------------------------
  // Tap stream
  // ---------------------------------------------------------------------------

  /// Never emits on this platform.
  Stream<NotificationTap> get onTap => _tapController.stream;

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void resetForTesting() {}
}
