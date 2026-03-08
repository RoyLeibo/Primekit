import 'package:permission_handler/permission_handler.dart' as ph;

import '../../core.dart';
import 'pk_permission.dart';

export 'pk_permission.dart';

/// Static utility methods for querying and requesting device permissions.
///
/// This implementation wraps [permission_handler], which supports Android,
/// iOS, and macOS via a single cross-platform API.
abstract final class PermissionHelper {
  static const String _tag = 'PermissionHelper';

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns `true` if [permission] is currently granted.
  static Future<bool> isGranted(PkPermission permission) async {
    final s = await status(permission);
    PrimekitLogger.verbose(
      'isGranted(${permission.name}): ${s.name}',
      tag: _tag,
    );
    return s == PkPermissionStatus.granted;
  }

  /// Returns the current [PkPermissionStatus] for [permission].
  static Future<PkPermissionStatus> status(PkPermission permission) async {
    final p = _toPermission(permission);
    if (p == null) return PkPermissionStatus.granted;
    try {
      final s = await p.status;
      return _fromStatus(s);
    } catch (e) {
      PrimekitLogger.warning(
        'PermissionHelper.status failed for ${permission.name}: $e',
        tag: _tag,
      );
      return PkPermissionStatus.notDetermined;
    }
  }

  /// Returns `true` if [status] is [PkPermissionStatus.permanentlyDenied].
  static bool isPermanentlyDenied(PkPermissionStatus status) =>
      status == PkPermissionStatus.permanentlyDenied;

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Requests [permission] and returns `true` if the user grants it.
  static Future<bool> request(PkPermission permission) async {
    final p = _toPermission(permission);
    if (p == null) return true;
    try {
      final s = await p.request();
      PrimekitLogger.info(
        'request(${permission.name}): granted=${s.isGranted}',
        tag: _tag,
      );
      return s.isGranted;
    } catch (e) {
      PrimekitLogger.warning(
        'PermissionHelper.request failed for ${permission.name}: $e',
        tag: _tag,
      );
      return false;
    }
  }

  /// Requests all [permissions] and returns a map of
  /// [PkPermission] → [PkPermissionStatus].
  static Future<Map<PkPermission, PkPermissionStatus>> requestMultiple(
    List<PkPermission> permissions,
  ) async {
    final result = <PkPermission, PkPermissionStatus>{};
    for (final permission in permissions) {
      final p = _toPermission(permission);
      if (p == null) {
        result[permission] = PkPermissionStatus.granted;
        continue;
      }
      try {
        final s = await p.request();
        result[permission] = _fromStatus(s);
        PrimekitLogger.info(
          'requestMultiple ${permission.name}: granted=${s.isGranted}',
          tag: _tag,
        );
      } catch (e) {
        result[permission] = PkPermissionStatus.denied;
        PrimekitLogger.warning(
          'requestMultiple failed for ${permission.name}: $e',
          tag: _tag,
        );
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Opens the application's settings page so the user can manually change
  /// permissions that have been permanently denied.
  static Future<void> openSettings() async {
    try {
      await ph.openAppSettings();
      PrimekitLogger.info('openSettings: opened', tag: _tag);
    } catch (e) {
      PrimekitLogger.warning('openSettings failed: $e', tag: _tag);
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion helpers
  // ---------------------------------------------------------------------------

  static ph.Permission? _toPermission(PkPermission p) => switch (p) {
    PkPermission.camera => ph.Permission.camera,
    PkPermission.microphone => ph.Permission.microphone,
    PkPermission.location => ph.Permission.locationWhenInUse,
    PkPermission.locationAlways => ph.Permission.locationAlways,
    PkPermission.notifications => ph.Permission.notification,
    PkPermission.storage => ph.Permission.storage,
    PkPermission.contacts => ph.Permission.contacts,
    PkPermission.calendar => ph.Permission.calendarWriteOnly,
    PkPermission.photos => ph.Permission.photos,
    PkPermission.bluetooth => ph.Permission.bluetooth,
    PkPermission.phone => ph.Permission.phone,
    PkPermission.sensors => ph.Permission.sensors,
  };

  static PkPermissionStatus _fromStatus(ph.PermissionStatus s) {
    if (s.isGranted) return PkPermissionStatus.granted;
    if (s.isPermanentlyDenied) return PkPermissionStatus.permanentlyDenied;
    if (s.isRestricted) return PkPermissionStatus.restricted;
    if (s.isLimited) return PkPermissionStatus.granted;
    if (s.isDenied) return PkPermissionStatus.denied;
    return PkPermissionStatus.notDetermined;
  }
}
