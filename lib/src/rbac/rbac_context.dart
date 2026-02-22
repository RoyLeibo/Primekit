import 'package:flutter/foundation.dart';

import 'permission.dart';
import 'rbac_policy.dart';

/// Captures the RBAC state for the currently authenticated user.
///
/// Constructed once per authentication session (typically after loading from
/// the backend) and held by `RbacService`.
///
/// ```dart
/// final ctx = RbacContext(
///   userId: 'user_123',
///   roleIds: ['editor', 'moderator'],
///   policy: policy,
/// );
/// print(ctx.can(Permission.write('posts'))); // true if editor has it
/// ```
@immutable
final class RbacContext {
  /// Creates an [RbacContext].
  const RbacContext({
    required this.userId,
    required this.roleIds,
    required this.policy,
    this.metadata = const {},
  });

  /// The authenticated user's ID.
  final String userId;

  /// Role IDs assigned to the user (e.g. `['editor', 'moderator']`).
  final List<String> roleIds;

  /// The policy used to resolve permissions.
  final RbacPolicy policy;

  /// Arbitrary metadata (custom claims, attributes, etc.).
  final Map<String, dynamic> metadata;

  // ---------------------------------------------------------------------------
  // Permission checks
  // ---------------------------------------------------------------------------

  /// Returns `true` when the user has [permission] via any of their roles.
  bool can(Permission permission) =>
      policy.anyRoleHasPermission(roleIds, permission);

  /// Returns `true` when the user has **all** [permissions].
  bool canAll(List<Permission> permissions) => permissions.every(can);

  /// Returns `true` when the user has **at least one** of [permissions].
  bool canAny(List<Permission> permissions) => permissions.any(can);

  // ---------------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------------

  /// All permission keys the user holds, flattened across all roles.
  List<String> get allPermissionKeys {
    final perms = <Permission>{};
    for (final roleId in roleIds) {
      perms.addAll(policy.permissionsFor(roleId));
    }
    return perms.map((p) => p.key).toList(growable: false);
  }

  @override
  String toString() =>
      'RbacContext(userId: $userId, roles: $roleIds)';
}
