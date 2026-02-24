import 'package:flutter_permission_handler_plus/flutter_permission_handler_plus.dart'
    as fphp;

import '../core/logger.dart';
import 'pk_permission.dart';

export 'pk_permission.dart';

/// Static utility methods for querying and requesting device permissions.
///
/// This implementation wraps [flutter_permission_handler_plus], which supports
/// Android, iOS, macOS, Windows, Linux, and Web via a single cross-platform API.
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
    final type = _toPermissionType(permission);
    if (type == null) return PkPermissionStatus.granted;
    try {
      final s = await fphp.PermissionHandlerPlus().checkPermissionStatus(type);
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
    final type = _toPermissionType(permission);
    if (type == null) return true;
    try {
      final s = await fphp.PermissionHandlerPlus().requestPermission(type);
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
    for (final p in permissions) {
      final type = _toPermissionType(p);
      if (type == null) {
        result[p] = PkPermissionStatus.granted;
        continue;
      }
      try {
        final s = await fphp.PermissionHandlerPlus().requestPermission(type);
        result[p] = _fromStatus(s);
        PrimekitLogger.info(
          'requestMultiple ${p.name}: granted=${s.isGranted}',
          tag: _tag,
        );
      } catch (e) {
        result[p] = PkPermissionStatus.denied;
        PrimekitLogger.warning(
          'requestMultiple failed for ${p.name}: $e',
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
      await fphp.PermissionHandlerPlus().openAppSettings();
      PrimekitLogger.info('openSettings: opened', tag: _tag);
    } catch (e) {
      PrimekitLogger.warning('openSettings failed: $e', tag: _tag);
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion helpers
  // ---------------------------------------------------------------------------

  static fphp.PermissionType? _toPermissionType(PkPermission p) => switch (p) {
    PkPermission.camera => fphp.PermissionType.camera,
    PkPermission.microphone => fphp.PermissionType.microphone,
    PkPermission.location => fphp.PermissionType.locationWhenInUse,
    PkPermission.locationAlways => fphp.PermissionType.locationAlways,
    PkPermission.notifications => fphp.PermissionType.notification,
    PkPermission.storage => fphp.PermissionType.storage,
    PkPermission.contacts => fphp.PermissionType.contacts,
    PkPermission.calendar => fphp.PermissionType.calendar,
    PkPermission.photos => fphp.PermissionType.photos,
    // No equivalent in flutter_permission_handler_plus — treated as granted.
    PkPermission.bluetooth => null,
    PkPermission.phone => null,
    PkPermission.sensors => null,
  };

  static PkPermissionStatus _fromStatus(fphp.PermissionStatus s) {
    if (s.isGranted) return PkPermissionStatus.granted;
    if (s.isPermanentlyDenied) return PkPermissionStatus.permanentlyDenied;
    if (s.isRestricted) return PkPermissionStatus.restricted;
    if (s.isNotApplicable) return PkPermissionStatus.granted;
    if (s.isDenied) return PkPermissionStatus.denied;
    return PkPermissionStatus.notDetermined; // undetermined
  }
}
