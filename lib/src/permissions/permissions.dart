// Primekit permissions module.
//
// Uses Primekit-owned [PkPermission] and [PkPermissionStatus] types so that
// your app never takes a direct compile-time dependency on `permission_handler`
// or any other platform-specific permission SDK.
//
// Firebase-backed and platform-specific implementations are selected
// automatically via conditional exports.
export 'pk_permission.dart';

// permission_helper.dart, permission_gate.dart, permission_flow.dart are NOT
// exported here — permission_handler 12.x does not declare macOS/Linux platform
// support. Import the files directly when needed:
//   import 'package:primekit/src/permissions/permission_helper.dart';
//   import 'package:primekit/src/permissions/permission_gate.dart';
//   import 'package:primekit/src/permissions/permission_flow.dart';
