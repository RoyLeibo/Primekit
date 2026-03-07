import 'package:flutter/foundation.dart';

/// An immutable, namespaced permission token.
///
/// Permissions follow the format `<resource>:<action>`, e.g.:
/// - `'posts:read'`
/// - `'posts:write'`
/// - `'posts:*'` (wildcard — grants all actions on the resource)
///
/// ```dart
/// final perm = Permission.read('posts');
/// print(perm.key);        // 'posts:read'
/// print(perm.resource);   // 'posts'
/// print(perm.action);     // 'read'
/// print(perm.isWildcard); // false
/// ```
@immutable
final class Permission {
  /// Creates a [Permission] from a raw [key] string.
  const Permission(this.key);

  /// Returns a read permission for [resource], e.g. `'posts:read'`.
  const Permission.read(String resource) : key = '$resource:read';

  /// Returns a write permission for [resource], e.g. `'posts:write'`.
  const Permission.write(String resource) : key = '$resource:write';

  /// Returns a delete permission for [resource], e.g. `'posts:delete'`.
  const Permission.delete(String resource) : key = '$resource:delete';

  /// Returns a wildcard permission for [resource], e.g. `'posts:*'`.
  ///
  /// A wildcard grants all actions on the resource.
  const Permission.all(String resource) : key = '$resource:*';

  /// The raw permission key, e.g. `'posts:read'`.
  final String key;

  // ---------------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------------

  /// Whether this is a wildcard permission (action is `'*'`).
  bool get isWildcard => key.endsWith(':*');

  /// The resource segment, e.g. `'posts'` from `'posts:read'`.
  String get resource {
    final colon = key.indexOf(':');
    return colon == -1 ? key : key.substring(0, colon);
  }

  /// The action segment, e.g. `'read'` from `'posts:read'`.
  String get action {
    final colon = key.indexOf(':');
    return colon == -1 ? '' : key.substring(colon + 1);
  }

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Permission($key)';
}

// ---------------------------------------------------------------------------
// Role
// ---------------------------------------------------------------------------

/// An immutable role that bundles a set of [Permission]s.
///
/// Roles may inherit other roles via [inherits], forming a simple hierarchy.
///
/// ```dart
/// const editorRole = Role(
///   id: 'editor',
///   name: 'Editor',
///   permissions: [Permission.read('posts'), Permission.write('posts')],
/// );
/// const adminRole = Role(
///   id: 'admin',
///   name: 'Admin',
///   permissions: [Permission.all('settings')],
///   inherits: ['editor'],
/// );
/// ```
@immutable
final class Role {
  /// Creates a [Role].
  const Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.inherits = const [],
  });

  /// Unique identifier used to reference this role, e.g. `'editor'`.
  final String id;

  /// Human-readable display name, e.g. `'Editor'`.
  final String name;

  /// Permissions directly granted to this role.
  final List<Permission> permissions;

  /// IDs of roles whose permissions this role inherits.
  final List<String> inherits;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Role($id, permissions: ${permissions.length})';
}
