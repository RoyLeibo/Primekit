import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core.dart';

/// Manages the FCM token lifecycle: permission, acquisition, refresh, removal.
///
/// Token *storage* is intentionally left to the caller via callbacks so each
/// app can persist tokens in whatever Firestore structure it uses.
///
/// ## Usage
///
/// ```dart
/// // After Firebase.initializeApp() and user sign-in:
/// await FcmTokenService.instance.init(
///   onTokenReceived: (token) async {
///     await firestore.collection('users').doc(uid).set(
///       {'fcm_tokens': FieldValue.arrayUnion([token])},
///       SetOptions(merge: true),
///     );
///   },
/// );
///
/// // On sign-out:
/// await FcmTokenService.instance.removeToken(
///   onTokenRemoved: (token) async {
///     await firestore.collection('users').doc(uid).update({
///       'fcm_tokens': FieldValue.arrayRemove([token]),
///     });
///   },
/// );
/// ```
class FcmTokenService {
  FcmTokenService._();
  static final FcmTokenService instance = FcmTokenService._();

  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _refreshSub;

  static const _tag = 'FcmTokenService';

  /// Request notification permission, fetch the current FCM token, and listen
  /// for refreshes.
  ///
  /// [onTokenReceived] is called with each new or refreshed token. Use it to
  /// persist the token in your app's storage.
  ///
  /// Safe to call before a user is signed in — [onTokenReceived] will be
  /// invoked with the token when it becomes available.
  ///
  /// On web, FCM requires a VAPID key; [getToken] is not called automatically.
  /// Pass the [webVapidKey] if your web app uses FCM.
  Future<void> init({
    required Future<void> Function(String token) onTokenReceived,
    String? webVapidKey,
  }) async {
    // Request permission (required on iOS; advisory on Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      PrimekitLogger.warning(
        'Notification permission denied — FCM tokens will not be registered',
        tag: _tag,
      );
      return;
    }

    // Fetch and persist the current token
    try {
      final token = await _messaging.getToken(vapidKey: webVapidKey);
      if (token != null) {
        PrimekitLogger.debug('FCM token obtained', tag: _tag);
        await onTokenReceived(token);
      }
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to fetch FCM token',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }

    // Cancel any existing refresh listener before registering a new one
    await _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen(
      (newToken) async {
        PrimekitLogger.debug('FCM token refreshed', tag: _tag);
        try {
          await onTokenReceived(newToken);
        } catch (e, st) {
          PrimekitLogger.error(
            'onTokenReceived threw during token refresh',
            tag: _tag,
            error: e,
            stackTrace: st,
          );
        }
      },
      onError: (Object e, StackTrace st) {
        PrimekitLogger.error(
          'FCM onTokenRefresh stream error',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  /// Remove the current FCM token from the device and call [onTokenRemoved]
  /// so the app can clean up its storage (e.g. remove from Firestore).
  ///
  /// Call this on sign-out so the device stops receiving push notifications
  /// for the signed-out user.
  Future<void> removeToken({
    Future<void> Function(String token)? onTokenRemoved,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && onTokenRemoved != null) {
        await onTokenRemoved(token);
      }
      await _messaging.deleteToken();
      PrimekitLogger.debug('FCM token removed', tag: _tag);
    } catch (e, st) {
      PrimekitLogger.error(
        'Failed to remove FCM token',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
    // Cancel refresh listener so stale callbacks are not triggered post-logout
    await _refreshSub?.cancel();
    _refreshSub = null;
  }

  /// Cancel the token refresh listener without deleting the token.
  ///
  /// Useful when the app is disposing resources but the user is still
  /// signed in.
  Future<void> dispose() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }

  /// Returns the current FCM token, or null if unavailable.
  Future<String?> getToken({String? webVapidKey}) =>
      _messaging.getToken(vapidKey: webVapidKey);

  /// Whether push notification permission has been granted.
  Future<bool> get hasPermission async {
    if (kIsWeb) return true; // Web does not have the same permission model
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
