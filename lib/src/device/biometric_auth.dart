import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as la;
import 'package:local_auth/error_codes.dart' as la_error;
import 'package:local_auth_android/local_auth_android.dart' show AndroidAuthMessages;
import 'package:local_auth_darwin/local_auth_darwin.dart' show IOSAuthMessages;
import 'package:local_auth_platform_interface/types/auth_messages.dart';

import '../core/logger.dart';

/// The types of biometric authentication supported by the device.
enum BiometricType {
  /// Fingerprint / Touch ID.
  fingerprint,

  /// Face / Face ID.
  face,

  /// Iris recognition.
  iris,

  /// Any biometric (fingerprint, face, or iris).
  any,
}

/// The outcome of a biometric authentication attempt.
enum BiometricResult {
  /// The user was successfully authenticated.
  success,

  /// Authentication failed (wrong fingerprint / face not recognised).
  failed,

  /// The user cancelled the authentication dialog.
  cancelled,

  /// Biometric authentication is not available on this device.
  notAvailable,

  /// Too many failed attempts; biometrics are temporarily locked out.
  lockedOut,

  /// A permanent lockout requiring PIN/password to unlock biometrics.
  permanentlyLockedOut,
}

/// Static helpers for biometric / local authentication.
///
/// Wraps `local_auth` with a cleaner enum-based API.
///
/// ```dart
/// final available = await BiometricAuth.isAvailable;
/// if (available) {
///   final result = await BiometricAuth.authenticate(
///     reason: 'Confirm your identity to continue',
///   );
///   switch (result) {
///     case BiometricResult.success:  proceed(); break;
///     case BiometricResult.cancelled: break;
///     default: showError();
///   }
/// }
/// ```
abstract final class BiometricAuth {
  static final la.LocalAuthentication _auth = la.LocalAuthentication();
  static const String _tag = 'BiometricAuth';

  // ---------------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------------

  /// Returns `true` if the device can perform biometric authentication.
  ///
  /// This checks both hardware availability and enrolled credentials.
  static Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (error) {
      PrimekitLogger.warning(
        'isAvailable check failed: ${error.message}',
        tag: _tag,
      );
      return false;
    }
  }

  /// Returns the list of biometric types enrolled on the device.
  ///
  /// Returns an empty list when biometrics are unavailable.
  static Future<List<BiometricType>> get availableTypes async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.map(_mapBiometricType).toList();
    } on PlatformException catch (error) {
      PrimekitLogger.warning(
        'availableTypes failed: ${error.message}',
        tag: _tag,
      );
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Presents the system biometric prompt with the given [reason].
  ///
  /// [reason] is displayed in the system-provided dialog.
  /// [cancelButtonText] customises the dismiss button label (Android / iOS).
  /// [stickyAuth] keeps the prompt alive when the app is backgrounded.
  static Future<BiometricResult> authenticate({
    required String reason,
    String? cancelButtonText,
    bool stickyAuth = true,
  }) async {
    try {
      final authMessages = cancelButtonText != null
          ? <AuthMessages>[
              AndroidAuthMessages(cancelButton: cancelButtonText),
              IOSAuthMessages(cancelButton: cancelButtonText),
            ]
          : <AuthMessages>[
              const AndroidAuthMessages(),
              const IOSAuthMessages(),
            ];

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        authMessages: authMessages,
        options: la.AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      PrimekitLogger.info(
        'authenticate: ${authenticated ? "success" : "failed"}',
        tag: _tag,
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (error) {
      PrimekitLogger.warning(
        'authenticate PlatformException: ${error.code} — ${error.message}',
        tag: _tag,
      );
      return _mapPlatformException(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal mapping helpers
  // ---------------------------------------------------------------------------

  static BiometricType _mapBiometricType(la.BiometricType type) =>
      switch (type) {
        la.BiometricType.fingerprint => BiometricType.fingerprint,
        la.BiometricType.face => BiometricType.face,
        la.BiometricType.iris => BiometricType.iris,
        _ => BiometricType.any,
      };

  static BiometricResult _mapPlatformException(PlatformException error) {
    if (error.message?.toLowerCase().contains('cancel') == true) {
      return BiometricResult.cancelled;
    }
    return switch (error.code) {
      la_error.notAvailable => BiometricResult.notAvailable,
      la_error.notEnrolled => BiometricResult.notAvailable,
      la_error.lockedOut => BiometricResult.lockedOut,
      la_error.permanentlyLockedOut => BiometricResult.permanentlyLockedOut,
      la_error.otherOperatingSystem => BiometricResult.notAvailable,
      _ => BiometricResult.failed,
    };
  }
}
