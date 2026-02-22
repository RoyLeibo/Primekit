import 'rbac_context.dart';

/// Abstract backend for loading and mutating user role assignments.
///
/// Implement this interface to connect RBAC to any data source
/// (Firestore, MongoDB, REST API, etc.).
///
/// ```dart
/// class MyRbacProvider implements RbacProvider { ... }
/// RbacService.instance.configure(
///   provider: MyRbacProvider(),
///   policy: myPolicy,
/// );
/// ```
abstract interface class RbacProvider {
  /// Loads the [RbacContext] for [userId].
  ///
  /// Reads the user's current role assignments from the backend and wraps
  /// them in an [RbacContext] backed by the current policy.
  Future<RbacContext> loadContext({required String userId});

  /// Assigns [roleId] to [userId] on the backend.
  Future<void> assignRole({required String userId, required String roleId});

  /// Removes [roleId] from [userId] on the backend.
  Future<void> removeRole({required String userId, required String roleId});

  /// Returns the IDs of all users that have [roleId] assigned.
  Future<List<String>> usersWithRole(String roleId);
}
