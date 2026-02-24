import 'package:flutter/foundation.dart';

import 'pk_permission.dart';

export 'pk_permission.dart';

/// Stub [PermissionHelper] for platforms where the OS handles permissions at
/// the system level (Windows, Linux, and other unsupported platforms).
///
/// All permissions are assumed to be granted. `openSettings()` logs a message.
abstract final class PermissionHelper {
  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Always returns `true` on this platform.
  static Future<bool> isGranted(PkPermission permission) async => true;

  /// Always returns [PkPermissionStatus.granted] on this platform.
  static Future<PkPermissionStatus> status(PkPermission permission) async =>
      PkPermissionStatus.granted;

  /// Always returns `false` — permissions are always granted on this platform.
  static bool isPermanentlyDenied(PkPermissionStatus status) => false;

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Always returns `true` on this platform.
  static Future<bool> request(PkPermission permission) async => true;

  /// Returns a map with all permissions set to [PkPermissionStatus.granted].
  static Future<Map<PkPermission, PkPermissionStatus>> requestMultiple(
    List<PkPermission> permissions,
  ) async => {for (final p in permissions) p: PkPermissionStatus.granted};

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Logs a message — system settings manage permissions on this platform.
  static Future<void> openSettings() async {
    debugPrint(
      '[Primekit] PermissionHelper: '
      'System settings manage permissions on this platform.',
    );
  }
}
