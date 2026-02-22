import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../rbac_context.dart';
import '../rbac_policy.dart';
import '../rbac_provider.dart';

/// [RbacProvider] implementation backed by Cloud Firestore and Firebase Auth.
///
/// Role assignments are stored in a Firestore user document under
/// `rolesField`.
/// Firebase Auth custom claims are also checked when available, with Firestore
/// taking precedence.
///
/// ```dart
/// final provider = FirebaseRbacProvider(policy: myPolicy);
/// final context = await provider.loadContext(userId: 'user_123');
/// ```
final class FirebaseRbacProvider implements RbacProvider {
  /// Creates a [FirebaseRbacProvider].
  ///
  /// [policy] — the RBAC policy used when constructing [RbacContext].
  /// [firestore] — defaults to [FirebaseFirestore.instance].
  /// [auth] — defaults to [FirebaseAuth.instance].
  /// [usersCollection] — Firestore collection name for user documents.
  /// [rolesField] — field name that holds the list of role IDs.
  FirebaseRbacProvider({
    required RbacPolicy policy,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String usersCollection = 'users',
    String rolesField = 'roles',
  })  : _policy = policy,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _usersCollection = usersCollection,
        _rolesField = rolesField;

  final RbacPolicy _policy;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _usersCollection;
  final String _rolesField;

  // ---------------------------------------------------------------------------
  // loadContext
  // ---------------------------------------------------------------------------

  @override
  Future<RbacContext> loadContext({required String userId}) async {
    try {
      // Try Firestore first.
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      var roleIds = <String>[];

      if (doc.exists) {
        final data = doc.data();
        final raw = data?[_rolesField];
        if (raw is List) {
          roleIds = raw.whereType<String>().toList();
        }
      }

      // Fall back to Firebase Auth custom claims when Firestore has no roles.
      if (roleIds.isEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          final idToken = await user.getIdTokenResult();
          final claims = idToken.claims ?? {};
          final rawClaims = claims[_rolesField];
          if (rawClaims is List) {
            roleIds = rawClaims.whereType<String>().toList();
          }
        }
      }

      return RbacContext(
        userId: userId,
        roleIds: roleIds,
        policy: _policy,
      );
    } catch (error) {
      throw Exception(
        'FirebaseRbacProvider.loadContext failed for user "$userId": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // assignRole
  // ---------------------------------------------------------------------------

  @override
  Future<void> assignRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(
        {
          _rolesField: FieldValue.arrayUnion([roleId]),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      throw Exception(
        'FirebaseRbacProvider.assignRole failed '
        '(user: $userId, role: $roleId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // removeRole
  // ---------------------------------------------------------------------------

  @override
  Future<void> removeRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        _rolesField: FieldValue.arrayRemove([roleId]),
      });
    } catch (error) {
      throw Exception(
        'FirebaseRbacProvider.removeRole failed '
        '(user: $userId, role: $roleId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // usersWithRole
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> usersWithRole(String roleId) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where(_rolesField, arrayContains: roleId)
          .get();

      return query.docs.map((d) => d.id).toList(growable: false);
    } catch (error) {
      throw Exception(
        'FirebaseRbacProvider.usersWithRole failed for role "$roleId": $error',
      );
    }
  }
}
