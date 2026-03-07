// Conditional export router for [BiometricAuth].
//
// - On Web (`dart.library.html`): uses the WebAuthn
//   `PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()` API
//   to detect platform authenticator availability.
// - On platforms with `dart:io` (Android, iOS, macOS, Windows): uses
//   `local_auth` for fingerprint / face / iris authentication.
// - On all other platforms (Linux): a no-op stub returns `notAvailable`
//   for all operations.
//
// The platform-agnostic [BiometricType] and [BiometricResult] enums are
// re-exported by every branch via `biometric_types.dart`.
export 'biometric_auth_stub.dart'
    if (dart.library.html) 'biometric_auth_web.dart'
    if (dart.library.io) 'biometric_auth_io.dart';
