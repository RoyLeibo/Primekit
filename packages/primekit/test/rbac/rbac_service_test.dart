import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/rbac/permission.dart';
import 'package:primekit/src/rbac/rbac_context.dart';
import 'package:primekit/src/rbac/rbac_policy.dart';
import 'package:primekit/src/rbac/rbac_provider.dart';
import 'package:primekit/src/rbac/rbac_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockRbacProvider extends Mock implements RbacProvider {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockRbacProvider mockProvider;
  late RbacPolicy policy;

  final viewerRole = Role(
    id: 'viewer',
    name: 'Viewer',
    permissions: const [Permission.read('posts')],
  );

  setUp(() {
    RbacService.resetForTesting();
    policy = RbacPolicy(roles: [viewerRole]);
    mockProvider = MockRbacProvider();
  });

  group('RbacService', () {
    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------

    group('initial state', () {
      test('context is null before loadForUser', () {
        expect(RbacService.instance.context, isNull);
      });

      test('isLoaded is false before loadForUser', () {
        expect(RbacService.instance.isLoaded, isFalse);
      });

      test('can() returns false before loading', () {
        expect(
          RbacService.instance.can(const Permission.read('posts')),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // loadForUser
    // -------------------------------------------------------------------------

    group('loadForUser', () {
      test('sets context after successful load', () async {
        const userId = 'user_1';
        final expectedCtx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => expectedCtx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);

        expect(RbacService.instance.context, isNotNull);
        expect(RbacService.instance.context!.userId, userId);
      });

      test('sets isLoaded to true after successful load', () async {
        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);

        expect(RbacService.instance.isLoaded, isTrue);
      });

      test('can() returns true for granted permission after load', () async {
        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);

        expect(
          RbacService.instance.can(const Permission.read('posts')),
          isTrue,
        );
      });
    });

    // -------------------------------------------------------------------------
    // clear
    // -------------------------------------------------------------------------

    group('clear()', () {
      test('resets context to null', () async {
        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);
        RbacService.instance.clear();

        expect(RbacService.instance.context, isNull);
      });

      test('sets isLoaded to false', () async {
        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);
        RbacService.instance.clear();

        expect(RbacService.instance.isLoaded, isFalse);
      });

      test('can() returns false after clear', () async {
        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);
        RbacService.instance.clear();

        expect(
          RbacService.instance.can(const Permission.read('posts')),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // Notifications
    // -------------------------------------------------------------------------

    group('ChangeNotifier', () {
      test('notifies listeners after loadForUser', () async {
        var notified = false;
        RbacService.instance.addListener(() => notified = true);

        const userId = 'user_1';
        final ctx = RbacContext(
          userId: userId,
          roleIds: const ['viewer'],
          policy: policy,
        );

        when(
          () => mockProvider.loadContext(userId: userId),
        ).thenAnswer((_) async => ctx);

        RbacService.instance.configure(provider: mockProvider, policy: policy);
        await RbacService.instance.loadForUser(userId);

        expect(notified, isTrue);

        RbacService.instance.removeListener(() {});
      });
    });
  });
}
