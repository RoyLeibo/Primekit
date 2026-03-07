import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'biometric_types.dart';

export 'biometric_types.dart';

/// Web implementation of [BiometricAuth] using the WebAuthn
/// `PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()` API.
///
/// Full WebAuthn authentication requires pre-registered credentials.
/// This implementation checks availability and returns [BiometricResult.notAvailable]
/// with a clear debug message explaining the requirement.
abstract final class BiometricAuth {
  // ---------------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------------

  /// Returns `true` if the browser has a platform authenticator
  /// (e.g. Windows Hello, Touch ID in Safari) available.
  static Future<bool> get isAvailable async {
    try {
      if (!_publicKeyCredentialSupported) return false;
      final available = await _checkPlatformAuthenticator();
      return available;
    } catch (_) {
      return false;
    }
  }

  /// Returns [BiometricType.any] if a platform authenticator is available,
  /// otherwise returns an empty list.
  static Future<List<BiometricType>> get availableTypes async {
    final avail = await isAvailable;
    return avail ? const [BiometricType.any] : const [];
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Checks platform authenticator availability.
  ///
  /// Note: Full WebAuthn authentication requires pre-registered credentials
  /// obtained via `navigator.credentials.create()`. Call this method after
  /// credential registration to trigger biometric verification.
  ///
  /// Returns [BiometricResult.notAvailable] with a debug message until a
  /// full registration + authentication flow is implemented.
  static Future<BiometricResult> authenticate({
    required String reason,
    String? cancelButtonText,
    bool stickyAuth = true,
  }) async {
    try {
      final avail = await isAvailable;
      if (!avail) return BiometricResult.notAvailable;

      debugPrint(
        '[Primekit] BiometricAuth (web): A platform authenticator is available. '
        'Full WebAuthn authentication requires credential registration. '
        'Implement navigator.credentials.create() before calling authenticate().',
      );
      return BiometricResult.notAvailable;
    } catch (_) {
      return BiometricResult.failed;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool get _publicKeyCredentialSupported {
    try {
      return (web.window as JSObject)
          .hasProperty('PublicKeyCredential'.toJS)
          .toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _checkPlatformAuthenticator() async {
    try {
      // PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
      // is a static method — call it via JS interop.
      final pkc = (web.window as JSObject).getProperty<JSObject>(
        'PublicKeyCredential'.toJS,
      );
      final promise = pkc.callMethod<JSPromise>(
        'isUserVerifyingPlatformAuthenticatorAvailable'.toJS,
      );
      final result = await promise.toDart;
      return (result as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }
}
