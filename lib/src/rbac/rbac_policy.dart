import 'permission.dart';

/// Manages the full set of [Role]s and their [Permission]s.
///
/// Supports:
/// - Direct permission matching.
/// - Wildcard matching (`'posts:*'` grants `'posts:read'`,
///   `'posts:write'`, etc.).
/// - Role inheritance via [Role.inherits].
///
/// ```dart
/// final policy = RbacPolicy(roles: [viewerRole, editorRole, adminRole]);
/// print(policy.hasPermission('editor', Permission.write('posts'))); // true
/// print(policy.hasPermission('viewer', Permission.write('posts'))); // false
/// ```
class RbacPolicy {
  /// Creates an [RbacPolicy] from [roles].
  RbacPolicy({required List<Role> roles})
    : _roles = {for (final r in roles) r.id: r};

  final Map<String, Role> _roles;

  // ---------------------------------------------------------------------------
  // Mutations (kept minimal — use for dynamic role management)
  // ---------------------------------------------------------------------------

  /// Adds or replaces a [role] in the policy.
  void addRole(Role role) => _roles[role.id] = role;

  /// Removes the role with [roleId] from the policy.
  void removeRole(String roleId) => _roles.remove(roleId);

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns `true` when the role identified by [roleId] has [permission].
  ///
  /// Considers inherited roles and wildcard permissions.
  bool hasPermission(String roleId, Permission permission) {
    final visited = <String>{};
    return _hasPermissionRecursive(roleId, permission, visited);
  }

  /// Returns `true` when any role in [roleIds] has [permission].
  bool anyRoleHasPermission(List<String> roleIds, Permission permission) =>
      roleIds.any((id) => hasPermission(id, permission));

  /// Returns the flattened set of all permissions for [roleId],
  /// including permissions from inherited roles.
  Set<Permission> permissionsFor(String roleId) {
    final visited = <String>{};
    return _collectPermissions(roleId, visited);
  }

  /// Returns all roles that directly or transitively grant [permission].
  List<Role> rolesWithPermission(Permission permission) => _roles.values
      .where((r) => hasPermission(r.id, permission))
      .toList(growable: false);

  /// Looks up a [Role] by its [id]. Returns `null` if not found.
  Role? getRole(String id) => _roles[id];

  /// All roles registered in this policy.
  List<Role> get allRoles => _roles.values.toList(growable: false);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _hasPermissionRecursive(
    String roleId,
    Permission target,
    Set<String> visited,
  ) {
    if (visited.contains(roleId)) return false;
    visited.add(roleId);

    final role = _roles[roleId];
    if (role == null) return false;

    for (final perm in role.permissions) {
      if (_permissionMatches(perm, target)) return true;
    }

    // Recurse into inherited roles.
    for (final parentId in role.inherits) {
      if (_hasPermissionRecursive(parentId, target, visited)) return true;
    }

    return false;
  }

  bool _permissionMatches(Permission granted, Permission target) {
    if (granted.key == target.key) return true;
    // Wildcard: 'posts:*' matches 'posts:read', 'posts:write', etc.
    if (granted.isWildcard && granted.resource == target.resource) return true;
    return false;
  }

  Set<Permission> _collectPermissions(String roleId, Set<String> visited) {
    if (visited.contains(roleId)) return {};
    visited.add(roleId);

    final role = _roles[roleId];
    if (role == null) return {};

    final result = <Permission>{...role.permissions};
    for (final parentId in role.inherits) {
      result.addAll(_collectPermissions(parentId, visited));
    }
    return result;
  }
}
