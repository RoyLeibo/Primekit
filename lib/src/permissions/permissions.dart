// Primekit permissions module.
//
// Uses Primekit-owned [PkPermission] and [PkPermissionStatus] types so that
// your app never takes a direct compile-time dependency on the underlying
// permission SDK.
//
// Platform-specific implementations are selected automatically via conditional
// exports: flutter_permission_handler_plus on native, browser Permissions API
// on Web, and a "always granted" stub on unsupported platforms.
export 'permission_flow.dart'
    show PermissionFlow, PermissionFlowResult, PermissionRequest;
export 'permission_gate.dart' show PermissionGate;
export 'permission_helper.dart' show PermissionHelper;
export 'pk_permission.dart';
