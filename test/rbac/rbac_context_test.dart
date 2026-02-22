import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/rbac/permission.dart';
import 'package:primekit/src/rbac/rbac_context.dart';
import 'package:primekit/src/rbac/rbac_policy.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared fixtures
  // ---------------------------------------------------------------------------

  final viewerRole = Role(
    id: 'viewer',
    name: 'Viewer',
    permissions: const [Permission.read('posts')],
  );
  final editorRole = Role(
    id: 'editor',
    name: 'Editor',
    permissions: const [
      Permission.read('posts'),
      Permission.write('posts'),
    ],
  );
  final policy = RbacPolicy(roles: [viewerRole, editorRole]);

  RbacContext makeContext(List<String> roleIds) => RbacContext(
        userId: 'user_1',
        roleIds: roleIds,
        policy: policy,
      );

  group('RbacContext', () {
    // -------------------------------------------------------------------------
    // can()
    // -------------------------------------------------------------------------

    group('can()', () {
      test('returns true when any role grants permission', () {
        final ctx = makeContext(['viewer']);
        expect(ctx.can(const Permission.read('posts')), isTrue);
      });

      test('returns false when no role grants permission', () {
        final ctx = makeContext(['viewer']);
        expect(ctx.can(const Permission.write('posts')), isFalse);
      });

      test('delegates to policy via roleIds', () {
        final ctx = makeContext(['editor']);
        expect(ctx.can(const Permission.write('posts')), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // canAll()
    // -------------------------------------------------------------------------

    group('canAll()', () {
      test('returns true when user has all permissions', () {
        final ctx = makeContext(['editor']);
        expect(
          ctx.canAll(const [
            Permission.read('posts'),
            Permission.write('posts'),
          ]),
          isTrue,
        );
      });

      test('returns false when user is missing one permission', () {
        final ctx = makeContext(['viewer']);
        expect(
          ctx.canAll(const [
            Permission.read('posts'),
            Permission.write('posts'),
          ]),
          isFalse,
        );
      });

      test('returns true for empty list', () {
        final ctx = makeContext(['viewer']);
        expect(ctx.canAll(const []), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // canAny()
    // -------------------------------------------------------------------------

    group('canAny()', () {
      test('returns true when user has at least one permission', () {
        final ctx = makeContext(['viewer']);
        expect(
          ctx.canAny(const [
            Permission.read('posts'),
            Permission.delete('posts'),
          ]),
          isTrue,
        );
      });

      test('returns false when user has none of the permissions', () {
        final ctx = makeContext(['viewer']);
        expect(
          ctx.canAny(const [
            Permission.write('posts'),
            Permission.delete('posts'),
          ]),
          isFalse,
        );
      });

      test('returns false for empty list', () {
        final ctx = makeContext(['viewer']);
        expect(ctx.canAny(const []), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // allPermissionKeys
    // -------------------------------------------------------------------------

    group('allPermissionKeys', () {
      test('includes permissions from all roles', () {
        final ctx = makeContext(['viewer', 'editor']);
        final keys = ctx.allPermissionKeys;
        expect(keys, contains('posts:read'));
        expect(keys, contains('posts:write'));
      });

      test('deduplicates permissions shared across roles', () {
        // viewer and editor both have posts:read
        final ctx = makeContext(['viewer', 'editor']);
        final readCount =
            ctx.allPermissionKeys.where((k) => k == 'posts:read').length;
        expect(readCount, 1);
      });
    });
  });
}
