import 'package:flutter/foundation.dart';

/// Represents a member of a shared document.
///
/// ```dart
/// final member = PkMember(
///   userId: 'user_123',
///   role: 'editor',
///   joinedAt: DateTime.now(),
/// );
/// ```
@immutable
class PkMember {
  /// Creates a [PkMember].
  const PkMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  /// Creates a [PkMember] from a Firestore-compatible map.
  factory PkMember.fromMap(Map<String, dynamic> map) {
    return PkMember(
      userId: map['userId'] as String,
      role: map['role'] as String,
      joinedAt: map['joinedAt'] is DateTime
          ? map['joinedAt'] as DateTime
          : DateTime.parse(map['joinedAt'] as String),
    );
  }

  /// The member's user ID.
  final String userId;

  /// The role assigned to this member (e.g. `'owner'`, `'editor'`, `'viewer'`).
  final String role;

  /// When this member was added.
  final DateTime joinedAt;

  /// Returns a new [PkMember] with the given fields replaced.
  PkMember copyWith({String? userId, String? role, DateTime? joinedAt}) {
    return PkMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Serializes to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'PkMember(userId: $userId, role: $role)';
}

/// Defines a named role with a list of permissions for sharing contexts.
///
/// ```dart
/// const ownerRole = PkShareRole(
///   name: 'owner',
///   permissions: ['read', 'write', 'delete', 'manage_members'],
/// );
/// ```
@immutable
class PkShareRole {
  /// Creates a [PkShareRole].
  const PkShareRole({required this.name, required this.permissions});

  /// The role identifier (e.g. `'owner'`, `'editor'`, `'viewer'`).
  final String name;

  /// Permissions granted by this role.
  final List<String> permissions;

  /// Returns `true` if this role includes [permission].
  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkShareRole &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'PkShareRole($name, ${permissions.length} permissions)';
}

/// Configuration for how sharing fields are stored in Firestore documents.
///
/// Allows customization of the field names used for member arrays and role
/// maps, since different collections may use different naming conventions.
///
/// ```dart
/// const config = PkSharingConfig(); // defaults: 'memberIds', 'roles'
/// const custom = PkSharingConfig(
///   memberIdsField: 'sharedWith',
///   rolesField: 'accessRoles',
/// );
/// ```
@immutable
class PkSharingConfig {
  /// Creates a [PkSharingConfig].
  const PkSharingConfig({
    this.memberIdsField = 'memberIds',
    this.rolesField = 'roles',
  });

  /// The Firestore field name for the member IDs array.
  final String memberIdsField;

  /// The Firestore field name for the roles map.
  final String rolesField;

  @override
  String toString() =>
      'PkSharingConfig(memberIds: $memberIdsField, roles: $rolesField)';
}
