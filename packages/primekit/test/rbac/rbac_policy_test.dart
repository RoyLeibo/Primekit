import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/rbac/permission.dart';
import 'package:primekit/src/rbac/rbac_policy.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test data
  // ---------------------------------------------------------------------------

  const readPosts = Permission.read('posts');
  const writePosts = Permission.write('posts');
  const deletePosts = Permission.delete('posts');
  const allPosts = Permission.all('posts');
  const readComments = Permission.read('comments');

  final viewerRole = Role(
    id: 'viewer',
    name: 'Viewer',
    permissions: const [readPosts],
  );
  final editorRole = Role(
    id: 'editor',
    name: 'Editor',
    permissions: const [readPosts, writePosts],
  );
  final adminRole = Role(
    id: 'admin',
    name: 'Admin',
    permissions: const [deletePosts, allPosts],
    inherits: const ['editor'],
  );
  final wildcardRole = Role(
    id: 'superadmin',
    name: 'Super Admin',
    permissions: const [allPosts],
  );

  group('RbacPolicy', () {
    late RbacPolicy policy;

    setUp(() {
      policy = RbacPolicy(
        roles: [viewerRole, editorRole, adminRole, wildcardRole],
      );
    });

    // -------------------------------------------------------------------------
    // hasPermission — direct match
    // -------------------------------------------------------------------------

    group('hasPermission — direct match', () {
      test('viewer has posts:read', () {
        expect(policy.hasPermission('viewer', readPosts), isTrue);
      });

      test('viewer does not have posts:write', () {
        expect(policy.hasPermission('viewer', writePosts), isFalse);
      });

      test('editor has posts:write', () {
        expect(policy.hasPermission('editor', writePosts), isTrue);
      });

      test('unknown role returns false', () {
        expect(policy.hasPermission('ghost', readPosts), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // hasPermission — wildcard
    // -------------------------------------------------------------------------

    group('hasPermission — wildcard', () {
      test('superadmin with posts:* has posts:read', () {
        expect(policy.hasPermission('superadmin', readPosts), isTrue);
      });

      test('superadmin with posts:* has posts:write', () {
        expect(policy.hasPermission('superadmin', writePosts), isTrue);
      });

      test('superadmin with posts:* has posts:delete', () {
        expect(policy.hasPermission('superadmin', deletePosts), isTrue);
      });

      test('superadmin with posts:* does not have unrelated '
          'comments:read', () {
        expect(policy.hasPermission('superadmin', readComments), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // hasPermission — inheritance
    // -------------------------------------------------------------------------

    group('hasPermission — inheritance', () {
      test('admin inherits editor posts:read', () {
        expect(policy.hasPermission('admin', readPosts), isTrue);
      });

      test('admin inherits editor posts:write', () {
        expect(policy.hasPermission('admin', writePosts), isTrue);
      });

      test('admin has its own direct posts:delete', () {
        expect(policy.hasPermission('admin', deletePosts), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // anyRoleHasPermission
    // -------------------------------------------------------------------------

    group('anyRoleHasPermission', () {
      test('returns true when any role has permission', () {
        expect(
          policy.anyRoleHasPermission(['viewer', 'editor'], writePosts),
          isTrue,
        );
      });

      test('returns false when no role has permission', () {
        expect(policy.anyRoleHasPermission(['viewer'], writePosts), isFalse);
      });

      test('returns false for empty role list', () {
        expect(policy.anyRoleHasPermission([], readPosts), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // permissionsFor
    // -------------------------------------------------------------------------

    group('permissionsFor', () {
      test('returns all direct permissions for viewer', () {
        final perms = policy.permissionsFor('viewer');
        expect(perms, contains(readPosts));
        expect(perms.length, 1);
      });

      test('includes inherited permissions for admin', () {
        final perms = policy.permissionsFor('admin');
        // direct: deletePosts, allPosts; inherited from editor: readPosts, writePosts
        expect(perms, containsAll([readPosts, writePosts, deletePosts]));
      });

      test('returns empty set for unknown role', () {
        final perms = policy.permissionsFor('ghost');
        expect(perms, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // addRole / removeRole
    // -------------------------------------------------------------------------

    group('addRole / removeRole', () {
      test('addRole makes new role queryable', () {
        final policy2 = RbacPolicy(roles: [viewerRole]);
        const newRole = Role(
          id: 'moderator',
          name: 'Moderator',
          permissions: [Permission.delete('comments')],
        );
        policy2.addRole(newRole);

        expect(policy2.getRole('moderator'), isNotNull);
      });

      test('removeRole makes role unavailable', () {
        final policy2 = RbacPolicy(roles: [viewerRole, editorRole]);
        policy2.removeRole('viewer');

        expect(policy2.getRole('viewer'), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // rolesWithPermission
    // -------------------------------------------------------------------------

    group('rolesWithPermission', () {
      test('finds all roles that have posts:read', () {
        final roles = policy.rolesWithPermission(readPosts);
        final ids = roles.map((r) => r.id).toList();
        expect(ids, containsAll(['viewer', 'editor', 'admin', 'superadmin']));
      });
    });
  });
}
