import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/auth/protected_route_guard.dart';
import 'package:primekit/src/auth/session_manager.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSessionStateProvider extends Mock implements SessionStateProvider {}

class MockGoRouterState extends Mock implements GoRouterState {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

/// A minimal [StatelessWidget] used to obtain a real [BuildContext]
/// inside [testWidgets].
class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}

void main() {
  late MockSessionStateProvider mockSession;
  late MockGoRouterState mockRouterState;

  setUp(() {
    mockSession = MockSessionStateProvider();
    mockRouterState = MockGoRouterState();
  });

  ProtectedRouteGuard makeGuard({
    String loginPath = '/login',
    String? loadingPath,
    List<String>? publicPaths,
  }) => ProtectedRouteGuard(
    sessionManager: mockSession,
    loginPath: loginPath,
    loadingPath: loadingPath,
    publicPaths: publicPaths,
  );

  void setLocation(String path) {
    when(() => mockRouterState.uri).thenReturn(Uri.parse(path));
  }

  void setSessionState(SessionState state) {
    when(() => mockSession.state).thenReturn(state);
  }

  // ---------------------------------------------------------------------------
  // publicPaths (no BuildContext needed)
  // ---------------------------------------------------------------------------

  group('publicPaths', () {
    test('always includes loginPath', () {
      final guard = makeGuard(loginPath: '/login');
      expect(guard.publicPaths, contains('/login'));
    });

    test('includes additional paths supplied at construction', () {
      final guard = makeGuard(publicPaths: ['/about', '/terms']);
      expect(guard.publicPaths, containsAll(['/login', '/about', '/terms']));
    });
  });

  // ---------------------------------------------------------------------------
  // SessionLoading
  // ---------------------------------------------------------------------------

  group('SessionLoading', () {
    testWidgets('redirects to loadingPath when not already there', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(const SessionLoading());
            setLocation('/home');
            final guard = makeGuard(loadingPath: '/loading');
            final result = guard.redirect(context, mockRouterState);
            expect(result, '/loading');
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('returns null when already on loadingPath', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(const SessionLoading());
            setLocation('/loading');
            final guard = makeGuard(loadingPath: '/loading');
            expect(guard.redirect(context, mockRouterState), isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('returns null when loadingPath is not set', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(const SessionLoading());
            setLocation('/home');
            expect(makeGuard().redirect(context, mockRouterState), isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SessionAuthenticated
  // ---------------------------------------------------------------------------

  group('SessionAuthenticated', () {
    final authenticated = SessionAuthenticated(userId: 'u1');

    testWidgets('allows navigation to a protected route', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(authenticated);
            setLocation('/dashboard');
            expect(makeGuard().redirect(context, mockRouterState), isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('redirects authenticated user away from loginPath to /', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(authenticated);
            setLocation('/login');
            expect(makeGuard().redirect(context, mockRouterState), '/');
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('allows access to public paths when authenticated', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(authenticated);
            setLocation('/about');
            final result = makeGuard(
              publicPaths: ['/about'],
            ).redirect(context, mockRouterState);
            expect(result, isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SessionUnauthenticated
  // ---------------------------------------------------------------------------

  group('SessionUnauthenticated', () {
    const unauthenticated = SessionUnauthenticated();

    testWidgets('redirects to loginPath for a protected route', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(unauthenticated);
            setLocation('/dashboard');
            expect(makeGuard().redirect(context, mockRouterState), '/login');
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('allows access to loginPath', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(unauthenticated);
            setLocation('/login');
            expect(makeGuard().redirect(context, mockRouterState), isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('allows access to explicitly listed public paths', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(unauthenticated);
            setLocation('/terms');
            final result = makeGuard(
              publicPaths: ['/terms'],
            ).redirect(context, mockRouterState);
            expect(result, isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('allows access to sub-path of public parent', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            setSessionState(unauthenticated);
            setLocation('/login/forgot-password');
            expect(makeGuard().redirect(context, mockRouterState), isNull);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets(
      'blocks access to path that only shares a prefix with a public path',
      (tester) async {
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              setSessionState(unauthenticated);
              // /loginextra is not /login and does not start with /login/
              setLocation('/loginextra');
              expect(makeGuard().redirect(context, mockRouterState), '/login');
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  });
}
