import 'package:permission_handler/permission_handler.dart';

import '../core/logger.dart';

/// Static utility methods for querying and requesting device permissions.
///
/// For multi-step UI flows prefer [PermissionFlow]. For declarative gating
/// in the widget tree prefer [PermissionGate].
///
/// ```dart
/// final granted = await PermissionHelper.isGranted(Permission.camera);
/// if (!granted) {
///   final ok = await PermissionHelper.request(Permission.camera);
///   if (!ok) await PermissionHelper.openSettings();
/// }
/// ```
abstract final class PermissionHelper {
  static const String _tag = 'PermissionHelper';

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns `true` if [permission] is currently granted.
  static Future<bool> isGranted(Permission permission) async {
    final s = await permission.status;
    PrimekitLogger.verbose(
      'isGranted(${permission.toString()}): ${s.name}',
      tag: _tag,
    );
    return s.isGranted;
  }

  /// Returns the current [PermissionStatus] for [permission].
  static Future<PermissionStatus> status(Permission permission) =>
      permission.status;

  /// Returns `true` if [status] is [PermissionStatus.permanentlyDenied].
  static bool isPermanentlyDenied(PermissionStatus status) =>
      status.isPermanentlyDenied;

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Requests [permission] and returns `true` if the user grants it.
  ///
  /// On Android this shows the system dialog. On iOS the system dialog is
  /// shown only the first time; subsequent calls return the stored status.
  static Future<bool> request(Permission permission) async {
    final result = await permission.request();
    PrimekitLogger.info(
      'request(${permission.toString()}): ${result.name}',
      tag: _tag,
    );
    return result.isGranted;
  }

  /// Requests all [permissions] in a single system call and returns a map
  /// of [Permission] → [PermissionStatus].
  static Future<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) async {
    final statuses = await permissions.request();
    for (final entry in statuses.entries) {
      PrimekitLogger.info(
        'requestMultiple ${entry.key}: ${entry.value.name}',
        tag: _tag,
      );
    }
    return statuses;
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Opens the application's settings page so the user can manually change
  /// permissions that have been permanently denied.
  static Future<void> openSettings() async {
    final opened = await openAppSettings();
    PrimekitLogger.info(
      'openSettings: ${opened ? "opened" : "could not open"}',
      tag: _tag,
    );
  }
}
