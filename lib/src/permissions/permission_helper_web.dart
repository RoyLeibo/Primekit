import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../core/logger.dart';
import 'pk_permission.dart';

export 'pk_permission.dart';

/// Web implementation of [PermissionHelper] using the browser Permissions API
/// and `navigator.mediaDevices.getUserMedia()` where applicable.
abstract final class PermissionHelper {
  static const String _tag = 'PermissionHelper';

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns `true` if [permission] is currently granted by the browser.
  static Future<bool> isGranted(PkPermission permission) async {
    final s = await status(permission);
    PrimekitLogger.verbose(
      'isGranted(${permission.name}): ${s.name}',
      tag: _tag,
    );
    return s == PkPermissionStatus.granted;
  }

  /// Returns the current [PkPermissionStatus] for [permission].
  static Future<PkPermissionStatus> status(PkPermission permission) async {
    final name = _toBrowserPermissionName(permission);
    if (name == null) {
      // Permissions without a browser equivalent are considered granted.
      return PkPermissionStatus.granted;
    }
    try {
      final permissionsApi = _permissionsApi;
      if (permissionsApi == null) return PkPermissionStatus.notDetermined;

      final descriptor = {'name': name}.jsify()! as JSObject;
      final status = await permissionsApi
          .callMethod<JSPromise>('query'.toJS, descriptor)
          .toDart;
      final state = (status as JSObject)
          .getProperty<JSString>('state'.toJS)
          .toDart;
      return _fromBrowserState(state);
    } catch (e) {
      PrimekitLogger.warning(
        'PermissionHelper.status failed for ${permission.name}: $e',
        tag: _tag,
      );
      return PkPermissionStatus.notDetermined;
    }
  }

  /// Returns `true` if [status] is [PkPermissionStatus.permanentlyDenied].
  static bool isPermanentlyDenied(PkPermissionStatus status) =>
      status == PkPermissionStatus.permanentlyDenied;

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Requests [permission] in the browser and returns `true` if granted.
  static Future<bool> request(PkPermission permission) async {
    final s = await _request(permission);
    PrimekitLogger.info('request(${permission.name}): ${s.name}', tag: _tag);
    return s == PkPermissionStatus.granted;
  }

  /// Requests all [permissions] and returns a status map.
  static Future<Map<PkPermission, PkPermissionStatus>> requestMultiple(
    List<PkPermission> permissions,
  ) async {
    final result = <PkPermission, PkPermissionStatus>{};
    for (final p in permissions) {
      result[p] = await _request(p);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// No-op on Web — browser permissions are managed by the browser itself.
  static Future<void> openSettings() async {
    debugPrint(
      '[Primekit] PermissionHelper: '
      'System settings manage permissions on web. '
      'Direct the user to browser site settings.',
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<PkPermissionStatus> _request(PkPermission permission) async {
    switch (permission) {
      case PkPermission.camera:
        return _requestMediaDevice(video: true, audio: false);
      case PkPermission.microphone:
        return _requestMediaDevice(video: false, audio: true);
      case PkPermission.notifications:
        return _requestNotificationPermission();
      case PkPermission.location:
      case PkPermission.locationAlways:
        return _requestGeolocation();
      default:
        // Permissions with no browser equivalent — treat as granted.
        return PkPermissionStatus.granted;
    }
  }

  static Future<PkPermissionStatus> _requestMediaDevice({
    required bool video,
    required bool audio,
  }) async {
    try {
      if (!_hasMediaDevices) return PkPermissionStatus.denied;
      final constraints = web.MediaStreamConstraints(
        video: video.toJS,
        audio: audio.toJS,
      );
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      // Stop all tracks immediately — we only needed the permission dialog.
      final tracks = stream.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
      return PkPermissionStatus.granted;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('NotAllowedError') || msg.contains('Permission')) {
        return PkPermissionStatus.denied;
      }
      return PkPermissionStatus.denied;
    }
  }

  static Future<PkPermissionStatus> _requestNotificationPermission() async {
    try {
      if (!globalContext.hasProperty('Notification'.toJS).toDart) {
        return PkPermissionStatus.denied;
      }
      final result = await web.Notification.requestPermission().toDart;
      return _fromNotificationPermission(result.toDart);
    } catch (e) {
      return PkPermissionStatus.denied;
    }
  }

  static Future<PkPermissionStatus> _requestGeolocation() async {
    try {
      if (!_hasGeolocation) return PkPermissionStatus.denied;
      final completer = Completer<PkPermissionStatus>();
      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition _) {
          completer.complete(PkPermissionStatus.granted);
        }.toJS,
        (web.GeolocationPositionError error) {
          completer.complete(PkPermissionStatus.denied);
        }.toJS,
      );
      return completer.future;
    } catch (e) {
      return PkPermissionStatus.denied;
    }
  }

  static JSObject? get _permissionsApi {
    try {
      final nav = web.window.navigator;
      if (!(nav as JSObject).hasProperty('permissions'.toJS).toDart) {
        return null;
      }
      return (nav as JSObject).getProperty<JSObject>('permissions'.toJS);
    } catch (_) {
      return null;
    }
  }

  static bool get _hasMediaDevices {
    try {
      final nav = web.window.navigator;
      return (nav as JSObject).hasProperty('mediaDevices'.toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  static bool get _hasGeolocation {
    try {
      final nav = web.window.navigator;
      return (nav as JSObject).hasProperty('geolocation'.toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  static String? _toBrowserPermissionName(PkPermission p) => switch (p) {
    PkPermission.camera => 'camera',
    PkPermission.microphone => 'microphone',
    PkPermission.notifications => 'notifications',
    PkPermission.location => 'geolocation',
    PkPermission.locationAlways => 'geolocation',
    _ => null, // Not queryable via Permissions API
  };

  static PkPermissionStatus _fromBrowserState(String state) => switch (state) {
    'granted' => PkPermissionStatus.granted,
    'denied' => PkPermissionStatus.permanentlyDenied,
    _ => PkPermissionStatus.notDetermined,
  };

  static PkPermissionStatus _fromNotificationPermission(String p) =>
      switch (p) {
        'granted' => PkPermissionStatus.granted,
        'denied' => PkPermissionStatus.permanentlyDenied,
        _ => PkPermissionStatus.notDetermined,
      };
}
