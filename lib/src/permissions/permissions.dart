/// Permissions — device permission checking, requesting, and UI gating.
///
/// Thin wrappers around `permission_handler` with Flutter UI for rationale
/// dialogs, permanently-denied states, and multi-step permission flows.
///
/// ```dart
/// // Simple gate
/// PermissionGate(
///   permission: Permission.camera,
///   child: CameraPreview(),
/// )
///
/// // Programmatic helper
/// final granted = await PermissionHelper.isGranted(Permission.location);
///
/// // Multi-step flow
/// final result = await PermissionFlow.request(context, [
///   PermissionRequest(
///     permission: Permission.camera,
///     title: 'Camera access',
///     message: 'Needed to scan documents.',
///   ),
/// ]);
/// ```
library primekit_permissions;

export 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionStatus;

export 'permission_helper.dart';
export 'permission_gate.dart';
export 'permission_flow.dart';
