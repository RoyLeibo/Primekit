// Shared biometric authentication types, platform-agnostic.

// ---------------------------------------------------------------------------
// BiometricType
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// BiometricResult
// ---------------------------------------------------------------------------

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
