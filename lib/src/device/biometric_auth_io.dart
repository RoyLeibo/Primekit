import 'package:local_auth/local_auth.dart' as la;
import 'package:local_auth_android/local_auth_android.dart'
    show AndroidAuthMessages;
import 'package:local_auth_darwin/local_auth_darwin.dart' show IOSAuthMessages;
import 'package:local_auth_platform_interface/types/auth_messages.dart';

import '../core/logger.dart';
import 'biometric_types.dart';

export 'biometric_types.dart';

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
    } on Exception catch (error) {
      PrimekitLogger.warning('isAvailable check failed: $error', tag: _tag);
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
    } on Exception catch (error) {
      PrimekitLogger.warning('availableTypes failed: $error', tag: _tag);
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
        biometricOnly: false,
        persistAcrossBackgrounding: stickyAuth,
      );

      PrimekitLogger.info(
        'authenticate: ${authenticated ? "success" : "failed"}',
        tag: _tag,
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on la.LocalAuthException catch (error) {
      PrimekitLogger.warning(
        'authenticate LocalAuthException: ${error.code} — ${error.description}',
        tag: _tag,
      );
      return _mapLocalAuthException(error);
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

  static BiometricResult _mapLocalAuthException(la.LocalAuthException error) =>
      switch (error.code) {
        la.LocalAuthExceptionCode.userCanceled ||
        la.LocalAuthExceptionCode.systemCanceled => BiometricResult.cancelled,
        la.LocalAuthExceptionCode.noBiometricsEnrolled ||
        la.LocalAuthExceptionCode.noBiometricHardware ||
        la.LocalAuthExceptionCode.noCredentialsSet =>
          BiometricResult.notAvailable,
        la.LocalAuthExceptionCode.temporaryLockout => BiometricResult.lockedOut,
        la.LocalAuthExceptionCode.biometricLockout =>
          BiometricResult.permanentlyLockedOut,
        _ => BiometricResult.failed,
      };
}
