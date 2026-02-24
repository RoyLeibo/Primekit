import 'package:permission_handler/permission_handler.dart' as ph;

import '../core/logger.dart';
import 'pk_permission.dart';

export 'pk_permission.dart';

/// Static utility methods for querying and requesting device permissions.
///
/// This implementation wraps `permission_handler` for Android / iOS / macOS.
abstract final class PermissionHelper {
  static const String _tag = 'PermissionHelper';

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns `true` if [permission] is currently granted.
  static Future<bool> isGranted(PkPermission permission) async {
    final s = await _toPhPermission(permission).status;
    PrimekitLogger.verbose(
      'isGranted(${permission.name}): ${s.name}',
      tag: _tag,
    );
    return s.isGranted;
  }

  /// Returns the current [PkPermissionStatus] for [permission].
  static Future<PkPermissionStatus> status(PkPermission permission) async {
    final s = await _toPhPermission(permission).status;
    return _fromPhStatus(s);
  }

  /// Returns `true` if [status] is [PkPermissionStatus.permanentlyDenied].
  static bool isPermanentlyDenied(PkPermissionStatus status) =>
      status == PkPermissionStatus.permanentlyDenied;

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Requests [permission] and returns `true` if the user grants it.
  static Future<bool> request(PkPermission permission) async {
    final result = await _toPhPermission(permission).request();
    PrimekitLogger.info(
      'request(${permission.name}): ${result.name}',
      tag: _tag,
    );
    return result.isGranted;
  }

  /// Requests all [permissions] and returns a map of
  /// [PkPermission] → [PkPermissionStatus].
  static Future<Map<PkPermission, PkPermissionStatus>> requestMultiple(
    List<PkPermission> permissions,
  ) async {
    final phPerms = permissions.map(_toPhPermission).toList();
    final statuses = await phPerms.request();
    final result = <PkPermission, PkPermissionStatus>{};
    for (var i = 0; i < permissions.length; i++) {
      final pkPerm = permissions[i];
      final phPerm = phPerms[i];
      final s = statuses[phPerm] ?? ph.PermissionStatus.denied;
      result[pkPerm] = _fromPhStatus(s);
      PrimekitLogger.info(
        'requestMultiple ${pkPerm.name}: ${s.name}',
        tag: _tag,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Opens the application's settings page so the user can manually change
  /// permissions that have been permanently denied.
  static Future<void> openSettings() async {
    final opened = await ph.openAppSettings();
    PrimekitLogger.info(
      'openSettings: ${opened ? "opened" : "could not open"}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Conversion helpers
  // ---------------------------------------------------------------------------

  static ph.Permission _toPhPermission(PkPermission p) => switch (p) {
    PkPermission.camera => ph.Permission.camera,
    PkPermission.microphone => ph.Permission.microphone,
    PkPermission.location => ph.Permission.location,
    PkPermission.locationAlways => ph.Permission.locationAlways,
    PkPermission.notifications => ph.Permission.notification,
    PkPermission.storage => ph.Permission.storage,
    PkPermission.contacts => ph.Permission.contacts,
    PkPermission.calendar => ph.Permission.calendarFullAccess,
    PkPermission.bluetooth => ph.Permission.bluetooth,
    PkPermission.phone => ph.Permission.phone,
    PkPermission.photos => ph.Permission.photos,
    PkPermission.sensors => ph.Permission.sensors,
  };

  static PkPermissionStatus _fromPhStatus(ph.PermissionStatus s) => switch (s) {
    ph.PermissionStatus.granted => PkPermissionStatus.granted,
    ph.PermissionStatus.denied => PkPermissionStatus.denied,
    ph.PermissionStatus.permanentlyDenied =>
      PkPermissionStatus.permanentlyDenied,
    ph.PermissionStatus.restricted => PkPermissionStatus.restricted,
    ph.PermissionStatus.limited => PkPermissionStatus.limited,
    ph.PermissionStatus.provisional => PkPermissionStatus.notDetermined,
  };
}
