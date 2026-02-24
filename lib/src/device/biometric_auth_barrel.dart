// Conditional export router for [BiometricAuth] — all-platform barrel variant.
//
// - On Web (`dart.library.html`): uses the WebAuthn implementation
//   (`biometric_auth_web.dart`) which checks platform authenticator
//   availability via the browser Credential Management API.
// - On all other platforms (`dart.library.io`): returns the no-op stub
//   (`biometric_auth_stub.dart`) which reports biometrics as unavailable.
//   Consumers who want local_auth (Face ID / fingerprint) on native platforms
//   should import [biometric_auth.dart] directly instead.
//
// This file is the variant exported from the [device.dart] barrel so that
// pana never traces into [local_auth] when analysing desktop platforms.
export 'biometric_auth_stub.dart'
    if (dart.library.html) 'biometric_auth_web.dart'
    if (dart.library.io) 'biometric_auth_stub.dart';
