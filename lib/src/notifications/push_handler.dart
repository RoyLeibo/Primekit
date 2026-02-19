// DEPENDENCY NOTE: PushHandler requires `firebase_messaging`.
//
// Add to pubspec.yaml:
//   firebase_messaging: ^15.0.0
//   firebase_core: ^3.0.0
//
// Platform setup:
//   iOS: Add push notifications capability + APNs key in Firebase console
//   Android: Download google-services.json and add to android/app/
//
// See: https://firebase.google.com/docs/cloud-messaging/flutter/client

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/logger.dart';

// ---------------------------------------------------------------------------
// PushMessage
// ---------------------------------------------------------------------------

/// A normalised push notification message received from FCM / APNs.
final class PushMessage {
  const PushMessage({
    this.title,
    this.body,
    this.data = const {},
    this.collapseKey,
    this.messageId,
  });

  /// Notification title from the payload.
  final String? title;

  /// Notification body from the payload.
  final String? body;

  /// Arbitrary data map attached to the message.
  final Map<String, dynamic> data;

  /// Collapse key (Android) used to replace similar pending messages.
  final String? collapseKey;

  /// Unique message identifier assigned by FCM.
  final String? messageId;

  @override
  String toString() =>
      'PushMessage(title: $title, body: $body, '
      'messageId: $messageId, data: $data)';
}

// ---------------------------------------------------------------------------
// PushHandler
// ---------------------------------------------------------------------------

/// Handles FCM / APNs push messages using `firebase_messaging`.
///
/// **Required dependency:** `firebase_messaging` — see the comment at the top
/// of this file for setup instructions.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Initialize Firebase in main():
/// await Firebase.initializeApp();
///
/// // 2. Set up the handler:
/// await PushHandler.instance.initialize(
///   onMessage: (msg) {
///     // Foreground message — show an in-app banner
///     InAppBannerService.show(context, InAppBannerConfig(
///       message: msg.body ?? '',
///     ));
///   },
///   onMessageOpenedApp: (msg) {
///     // User tapped notification — navigate
///     router.push(msg.data['route'] as String? ?? '/');
///   },
///   onTokenRefresh: (token) {
///     if (token != null) api.updateDevicePushToken(token);
///   },
/// );
///
/// // 3. Get the current FCM token:
/// final token = await PushHandler.instance.getToken();
/// ```
class PushHandler {
  PushHandler._();

  static final PushHandler _instance = PushHandler._();

  /// The shared singleton instance.
  static PushHandler get instance => _instance;

  static const String _tag = 'PushHandler';

  bool _initialized = false;

  // Callbacks stored for re-use after re-initialization.
  void Function(PushMessage message)? _onMessage;
  void Function(PushMessage message)? _onMessageOpenedApp;
  void Function(String? token)? _onTokenRefresh;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes FCM message handling.
  ///
  /// [onMessage] is called when a push arrives while the app is in the
  /// foreground.
  ///
  /// [onMessageOpenedApp] is called when the user taps a notification that
  /// was displayed while the app was in the background or terminated.
  ///
  /// [onTokenRefresh] is called when the FCM token is created or rotated.
  /// Use this to send the updated token to your backend.
  ///
  /// When `firebase_messaging` is installed, replace the body of this method
  /// with the real SDK integration shown in the inline comment.
  Future<void> initialize({
    required void Function(PushMessage message) onMessage,
    required void Function(PushMessage message) onMessageOpenedApp,
    void Function(String? token)? onTokenRefresh,
  }) async {
    if (_initialized) {
      PrimekitLogger.warning(
        'PushHandler.initialize() called more than once. Ignoring.',
        tag: _tag,
      );
      return;
    }

    _onMessage = onMessage;
    _onMessageOpenedApp = onMessageOpenedApp;
    _onTokenRefresh = onTokenRefresh;

    // When firebase_messaging is installed, replace this comment block with:
    //
    // // Request permission (iOS / web):
    // await FirebaseMessaging.instance.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );
    //
    // // Foreground messages:
    // FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    //   onMessage(_fromRemote(msg));
    // });
    //
    // // Background → foreground tap:
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
    //   onMessageOpenedApp(_fromRemote(msg));
    // });
    //
    // // Token refresh:
    // FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    //   onTokenRefresh?.call(token);
    // });
    //
    // // Check for notification that launched the app from terminated state:
    // final initial = await FirebaseMessaging.instance.getInitialMessage();
    // if (initial != null) {
    //   onMessageOpenedApp(_fromRemote(initial));
    // }

    _initialized = true;
    PrimekitLogger.info('PushHandler initialized.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Token
  // ---------------------------------------------------------------------------

  /// Returns the current FCM registration token.
  ///
  /// Returns `null` when `firebase_messaging` is not installed or the device
  /// has no token yet.
  ///
  /// When `firebase_messaging` is installed, replace this with:
  /// ```dart
  /// return FirebaseMessaging.instance.getToken();
  /// ```
  Future<String?> getToken() async {
    if (!_initialized) {
      PrimekitLogger.warning(
        'PushHandler.getToken() called before initialize().',
        tag: _tag,
      );
      return null;
    }
    // Replace with: return FirebaseMessaging.instance.getToken();
    PrimekitLogger.debug(
      'PushHandler.getToken(): firebase_messaging not installed.',
      tag: _tag,
    );
    return null;
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests push notification permission (iOS / web).
  ///
  /// Returns `true` if permission was granted.
  ///
  /// On Android 13+ (API 33), the plugin handles the runtime permission
  /// automatically; this method is a no-op on older Android.
  ///
  /// When `firebase_messaging` is installed, replace this with:
  /// ```dart
  /// final settings = await FirebaseMessaging.instance.requestPermission();
  /// return settings.authorizationStatus == AuthorizationStatus.authorized;
  /// ```
  Future<bool> requestPermission() async {
    if (!_initialized) {
      PrimekitLogger.warning(
        'PushHandler.requestPermission() called before initialize().',
        tag: _tag,
      );
      return false;
    }
    // Replace with real permission request.
    return false;
  }

  // ---------------------------------------------------------------------------
  // Background handler registration
  // ---------------------------------------------------------------------------

  /// Registers a top-level function as the background message handler.
  ///
  /// Call this from `main()` BEFORE `runApp()`:
  ///
  /// ```dart
  /// PushHandler.handleBackground(); // registers _firebaseBackgroundHandler
  /// ```
  ///
  /// When `firebase_messaging` is installed, replace this with:
  /// ```dart
  /// FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  /// ```
  static void handleBackground() {
    // Replace with: FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    PrimekitLogger.debug(
      'PushHandler.handleBackground(): firebase_messaging not installed.',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  // When firebase_messaging is installed, add this helper:
  //
  // static PushMessage _fromRemote(RemoteMessage msg) => PushMessage(
  //   title: msg.notification?.title,
  //   body: msg.notification?.body,
  //   data: msg.data,
  //   collapseKey: msg.collapseKey,
  //   messageId: msg.messageId,
  // );

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets to uninitialised state.
  ///
  /// For use in tests only.
  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _onMessage = null;
    _onMessageOpenedApp = null;
    _onTokenRefresh = null;
  }

  /// Simulates an incoming foreground push message.
  ///
  /// Useful in tests and during development to verify message handling without
  /// a real device or FCM connection.
  @visibleForTesting
  void simulateMessage(PushMessage message) {
    _onMessage?.call(message);
  }

  /// Simulates the user tapping a notification to open the app.
  @visibleForTesting
  void simulateOpenedApp(PushMessage message) {
    _onMessageOpenedApp?.call(message);
  }
}

// Top-level background message handler — must be a top-level function.
// When firebase_messaging is installed, uncomment and complete this:
//
// @pragma('vm:entry-point')
// Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   // Process the background message here.
//   // Keep work minimal — the OS may kill this isolate at any time.
// }
