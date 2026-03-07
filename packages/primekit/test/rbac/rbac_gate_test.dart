import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/rbac/permission.dart';
import 'package:primekit/src/rbac/rbac_context.dart';
import 'package:primekit/src/rbac/rbac_policy.dart';
import 'package:primekit/src/rbac/rbac_provider.dart';
import 'package:primekit/src/rbac/rbac_service.dart';
import 'package:primekit/src/rbac/widgets/permission_gate.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final viewerRole = Role(
    id: 'viewer',
    name: 'Viewer',
    permissions: const [Permission.read('posts')],
  );
  final policy = RbacPolicy(roles: [viewerRole]);

  setUp(() => RbacService.resetForTesting());

  tearDown(() => RbacService.resetForTesting());

  group('RbacGate', () {
    // -------------------------------------------------------------------------
    // Renders child when permitted
    // -------------------------------------------------------------------------

    testWidgets('renders child when user has permission', (tester) async {
      // Set up context with viewer role.
      final ctx = RbacContext(
        userId: 'user_1',
        roleIds: const ['viewer'],
        policy: policy,
      );
      // Manually inject context via the backdoor.
      // Since RbacService.loadForUser requires a provider, we test via
      // a minimal _setContextForTesting pattern.
      // Instead, we configure + force via a stub provider.
      // Use a simpler approach: inject the context directly by calling
      // notifyListeners via a test provider stub.

      // We'll use the service's loadForUser via a mock. For simplicity, we
      // instead test via a stub that sets the context.
      final service = RbacService.instance;
      // Manually call internal helper by patching through configure + load.
      // Since we can't inject context without provider, let's use a no-op
      // provider pattern.
      service.configure(provider: _FakeRbacProvider(ctx), policy: policy);
      await service.loadForUser('user_1');

      await tester.pumpWidget(
        _wrap(
          RbacGate(
            permission: const Permission.read('posts'),
            child: const Text('SECRET CONTENT'),
          ),
        ),
      );

      expect(find.text('SECRET CONTENT'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Renders fallback when not permitted
    // -------------------------------------------------------------------------

    testWidgets('renders fallback when user lacks permission', (tester) async {
      // User has no roles.
      final ctx = RbacContext(
        userId: 'user_1',
        roleIds: const [],
        policy: policy,
      );
      RbacService.instance.configure(
        provider: _FakeRbacProvider(ctx),
        policy: policy,
      );
      await RbacService.instance.loadForUser('user_1');

      await tester.pumpWidget(
        _wrap(
          RbacGate(
            permission: const Permission.write('posts'),
            child: const Text('SECRET CONTENT'),
            fallback: const Text('ACCESS DENIED'),
          ),
        ),
      );

      expect(find.text('SECRET CONTENT'), findsNothing);
      expect(find.text('ACCESS DENIED'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Default fallback is SizedBox.shrink
    // -------------------------------------------------------------------------

    testWidgets('uses SizedBox.shrink as default fallback when not permitted', (
      tester,
    ) async {
      final ctx = RbacContext(
        userId: 'user_1',
        roleIds: const [],
        policy: policy,
      );
      RbacService.instance.configure(
        provider: _FakeRbacProvider(ctx),
        policy: policy,
      );
      await RbacService.instance.loadForUser('user_1');

      await tester.pumpWidget(
        _wrap(
          RbacGate(
            permission: const Permission.delete('posts'),
            child: const Text('HIDDEN'),
          ),
        ),
      );

      expect(find.text('HIDDEN'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub provider
// ---------------------------------------------------------------------------

class _FakeRbacProvider implements RbacProvider {
  const _FakeRbacProvider(this._context);

  final RbacContext _context;

  @override
  Future<RbacContext> loadContext({required String userId}) async => _context;

  @override
  Future<void> assignRole({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<void> removeRole({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<List<String>> usersWithRole(String roleId) async => [];
}
