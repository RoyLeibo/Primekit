import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'notification_types.dart';

export 'notification_types.dart';

// ---------------------------------------------------------------------------
// LocalNotifier (Web implementation)
// ---------------------------------------------------------------------------

/// Web implementation of [LocalNotifier] using the browser Notification API.
///
/// Requires the user to grant notification permission via
/// `Notification.requestPermission()`.
class LocalNotifier {
  LocalNotifier._();

  static final LocalNotifier _instance = LocalNotifier._();

  /// The shared singleton instance.
  static LocalNotifier get instance => _instance;

  bool _initialized = false;

  // Active browser notifications keyed by id for cancellation.
  final Map<int, web.Notification> _active = {};

  // Scheduled timers keyed by id for cancellation.
  final Map<int, Timer> _timers = {};

  // Pending notifications for getPending().
  final List<PendingNotification> _pending = [];

  final StreamController<NotificationTap> _tapController =
      StreamController<NotificationTap>.broadcast();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the web notifier and optionally requests permission.
  Future<void> initialize({
    List<Object> channels = const [],
    bool requestPermission = true,
  }) async {
    if (_initialized) {
      debugPrint('[Primekit] LocalNotifier: already initialized.');
      return;
    }
    if (requestPermission) {
      await _requestPermission();
    }
    _initialized = true;
    debugPrint('[Primekit] LocalNotifier (web): initialized.');
  }

  // ---------------------------------------------------------------------------
  // Permission helpers
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    try {
      if (!_notificationsSupported) return;
      // requestPermission() returns JSPromise<JSString> — await via .toDart
      final result = await web.Notification.requestPermission().toDart;
      debugPrint(
        '[Primekit] LocalNotifier (web): permission = ${result.toDart}',
      );
    } catch (e) {
      debugPrint(
        '[Primekit] LocalNotifier (web): requestPermission failed: $e',
      );
    }
  }

  bool get _notificationsSupported {
    try {
      // Use globalContext.hasProperty (from dart:js_interop_unsafe) to check
      // if the Notification API is defined in this browser environment.
      return globalContext.hasProperty('Notification'.toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  bool get _isPermissionGranted {
    if (!_notificationsSupported) return false;
    try {
      // NotificationPermission is a String typedef — no .toDart needed.
      return web.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Show
  // ---------------------------------------------------------------------------

  /// Shows an immediate browser notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    Object? channel,
    Object? details,
  }) async {
    if (!_isPermissionGranted) {
      debugPrint(
        '[Primekit] LocalNotifier (web): permission not granted — skipping show().',
      );
      return;
    }
    _cancelNotification(id); // replace existing notification with same id
    try {
      final options = web.NotificationOptions(body: body);
      final notification = web.Notification(title, options);
      _active[id] = notification;

      // Use the onclick setter — capture id and payload via closure.
      final capturedId = id;
      final capturedPayload = payload;
      notification.onclick = (web.Event _) {
        _tapController.add(
          NotificationTap(id: capturedId, payload: capturedPayload),
        );
      }.toJS;
    } catch (e) {
      debugPrint('[Primekit] LocalNotifier (web): show() failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  /// Schedules a future browser notification using a Dart [Timer].
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
    _cancelTimer(id);

    final now = DateTime.now();
    final delay = scheduledAt.isAfter(now)
        ? scheduledAt.difference(now)
        : Duration.zero;

    _pending.add(
      PendingNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledAt: scheduledAt,
      ),
    );

    _timers[id] = Timer(delay, () async {
      _pending.removeWhere((p) => p.id == id);
      _timers.remove(id);
      await show(id: id, title: title, body: body, payload: payload);
    });

    debugPrint(
      '[Primekit] LocalNotifier (web): scheduled id=$id at $scheduledAt',
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  /// Cancels both any active and any scheduled notification with [id].
  Future<void> cancel(int id) async {
    _cancelNotification(id);
    _cancelTimer(id);
    _pending.removeWhere((p) => p.id == id);
  }

  /// Cancels all active and scheduled notifications.
  Future<void> cancelAll() async {
    for (final id in List<int>.from(_active.keys)) {
      _cancelNotification(id);
    }
    for (final id in List<int>.from(_timers.keys)) {
      _cancelTimer(id);
    }
    _pending.clear();
  }

  void _cancelNotification(int id) {
    _active.remove(id)?.close();
  }

  void _cancelTimer(int id) {
    _timers.remove(id)?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns all pending (not yet shown) scheduled notifications.
  Future<List<PendingNotification>> getPending() async =>
      List.unmodifiable(_pending);

  // ---------------------------------------------------------------------------
  // Tap stream
  // ---------------------------------------------------------------------------

  /// Emits a [NotificationTap] when the user clicks a browser notification.
  Stream<NotificationTap> get onTap => _tapController.stream;

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _active.clear();
    _timers.clear();
    _pending.clear();
  }
}
