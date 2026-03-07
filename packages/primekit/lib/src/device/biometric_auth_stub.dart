import 'biometric_types.dart';

export 'biometric_types.dart';

/// No-op [BiometricAuth] stub for platforms that do not support
/// `local_auth` (Linux and other unsupported platforms).
///
/// All operations indicate that biometrics are not available.
abstract final class BiometricAuth {
  // ---------------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------------

  /// Always returns `false` — biometric auth is not available on this platform.
  static Future<bool> get isAvailable async => false;

  /// Always returns an empty list — no biometrics available on this platform.
  static Future<List<BiometricType>> get availableTypes async => const [];

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Always returns [BiometricResult.notAvailable] on this platform.
  static Future<BiometricResult> authenticate({
    required String reason,
    String? cancelButtonText,
    bool stickyAuth = true,
  }) async => BiometricResult.notAvailable;
}
