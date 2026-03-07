import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/rbac/permission.dart';

void main() {
  group('Permission', () {
    // -------------------------------------------------------------------------
    // Named constructors
    // -------------------------------------------------------------------------

    group('named constructors', () {
      test('Permission.read produces key "posts:read"', () {
        const perm = Permission.read('posts');
        expect(perm.key, 'posts:read');
      });

      test('Permission.write produces key "posts:write"', () {
        const perm = Permission.write('posts');
        expect(perm.key, 'posts:write');
      });

      test('Permission.delete produces key "posts:delete"', () {
        const perm = Permission.delete('posts');
        expect(perm.key, 'posts:delete');
      });

      test('Permission.all produces key "posts:*"', () {
        const perm = Permission.all('posts');
        expect(perm.key, 'posts:*');
      });
    });

    // -------------------------------------------------------------------------
    // isWildcard
    // -------------------------------------------------------------------------

    group('isWildcard', () {
      test('returns true for Permission.all', () {
        const perm = Permission.all('resources');
        expect(perm.isWildcard, isTrue);
      });

      test('returns false for Permission.read', () {
        const perm = Permission.read('resources');
        expect(perm.isWildcard, isFalse);
      });

      test('returns false for Permission.write', () {
        const perm = Permission.write('resources');
        expect(perm.isWildcard, isFalse);
      });

      test('returns false for Permission.delete', () {
        const perm = Permission.delete('resources');
        expect(perm.isWildcard, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // resource / action
    // -------------------------------------------------------------------------

    group('resource', () {
      test('extracts resource from namespaced key', () {
        const perm = Permission('invoices:read');
        expect(perm.resource, 'invoices');
      });

      test('returns full key when no colon present', () {
        const perm = Permission('nocodon');
        expect(perm.resource, 'nocodon');
      });
    });

    group('action', () {
      test('extracts action from namespaced key', () {
        const perm = Permission('invoices:delete');
        expect(perm.action, 'delete');
      });

      test('returns wildcard for Permission.all', () {
        const perm = Permission.all('invoices');
        expect(perm.action, '*');
      });
    });

    // -------------------------------------------------------------------------
    // equality
    // -------------------------------------------------------------------------

    group('equality', () {
      test('equal when keys match', () {
        const a = Permission('posts:read');
        const b = Permission.read('posts');
        expect(a, b);
      });

      test('not equal for different keys', () {
        const a = Permission.read('posts');
        const b = Permission.write('posts');
        expect(a, isNot(b));
      });

      test('hashCode matches for equal permissions', () {
        const a = Permission.read('items');
        const b = Permission.read('items');
        expect(a.hashCode, b.hashCode);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Role
  // ---------------------------------------------------------------------------

  group('Role', () {
    test('id equality', () {
      const a = Role(id: 'admin', name: 'Admin', permissions: []);
      const b = Role(id: 'admin', name: 'Different Name', permissions: []);
      expect(a, b);
    });

    test('not equal for different ids', () {
      const a = Role(id: 'admin', name: 'Admin', permissions: []);
      const b = Role(id: 'viewer', name: 'Viewer', permissions: []);
      expect(a, isNot(b));
    });

    test('inherits defaults to empty list', () {
      const role = Role(id: 'r', name: 'R', permissions: []);
      expect(role.inherits, isEmpty);
    });
  });
}
