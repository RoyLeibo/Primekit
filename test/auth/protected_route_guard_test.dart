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
  }) =>
      ProtectedRouteGuard(
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
  // publicPaths
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
    test('redirects to loadingPath when not already there', () {
      setSessionState(const SessionLoading());
      setLocation('/home');
      final guard = makeGuard(loadingPath: '/loading');

      final result = guard.redirect(null as dynamic, mockRouterState);
      expect(result, '/loading');
    });

    test('returns null when already on loadingPath', () {
      setSessionState(const SessionLoading());
      setLocation('/loading');
      final guard = makeGuard(loadingPath: '/loading');

      final result = guard.redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });

    test('returns null when loadingPath is not set', () {
      setSessionState(const SessionLoading());
      setLocation('/home');
      final guard = makeGuard();

      final result = guard.redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SessionAuthenticated
  // ---------------------------------------------------------------------------

  group('SessionAuthenticated', () {
    final authenticated = SessionAuthenticated(userId: 'u1');

    test('allows navigation to a protected route', () {
      setSessionState(authenticated);
      setLocation('/dashboard');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });

    test('redirects authenticated user away from loginPath to /', () {
      setSessionState(authenticated);
      setLocation('/login');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      expect(result, '/');
    });

    test('allows access to public paths when authenticated', () {
      setSessionState(authenticated);
      setLocation('/about');

      final result = makeGuard(publicPaths: ['/about'])
          .redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SessionUnauthenticated
  // ---------------------------------------------------------------------------

  group('SessionUnauthenticated', () {
    const unauthenticated = SessionUnauthenticated();

    test('redirects to loginPath for a protected route', () {
      setSessionState(unauthenticated);
      setLocation('/dashboard');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      expect(result, '/login');
    });

    test('allows access to loginPath', () {
      setSessionState(unauthenticated);
      setLocation('/login');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });

    test('allows access to explicitly listed public paths', () {
      setSessionState(unauthenticated);
      setLocation('/terms');

      final result = makeGuard(publicPaths: ['/terms'])
          .redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });

    test('allows access to sub-path of public parent', () {
      setSessionState(unauthenticated);
      setLocation('/login/forgot-password');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      expect(result, isNull);
    });

    test('blocks access to path that only shares a prefix with a public path',
        () {
      setSessionState(unauthenticated);
      // /loginextra does NOT start with /login/
      setLocation('/loginextra');

      final result = makeGuard().redirect(null as dynamic, mockRouterState);
      // /loginextra is not equal to /login and does not start with /login/
      // so it should be blocked.
      expect(result, '/login');
    });
  });
}
