// Conditional export router for [PermissionHelper].
//
// - On Web (`dart.library.html`): uses the browser Permissions API and
//   `navigator.mediaDevices.getUserMedia()`.
// - On platforms with `dart:io` (Android, iOS, macOS, Windows, Linux): uses
//   `permission_handler` on mobile/macOS; falls back to the stub on desktop.
// - On all other platforms: a no-op stub that returns `granted` for all.
//
// The Primekit-owned [PkPermission] and [PkPermissionStatus] enums are
// re-exported by every branch so callers never import `permission_handler`
// directly.
export 'permission_helper_stub.dart'
    if (dart.library.html) 'permission_helper_web.dart'
    if (dart.library.io) 'permission_helper_io.dart';
