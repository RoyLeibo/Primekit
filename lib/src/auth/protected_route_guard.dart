import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/logger.dart';
import 'session_manager.dart' show SessionAuthenticated, SessionLoading, SessionStateProvider;

/// A [GoRouter] redirect guard that protects routes from unauthenticated
/// access.
///
/// Plug this into your [GoRouter.redirect] callback. For every navigation
/// event it checks whether the destination path is listed in [publicPaths];
/// if not, it verifies the session and redirects to [loginPath] when the
/// user is not authenticated.
///
/// While the session state is [SessionLoading] (i.e. being restored on
/// startup), the guard redirects to a loading path — or holds the user at
/// the current location — to avoid a brief unauthenticated flash.
///
/// ```dart
/// final guard = ProtectedRouteGuard(
///   sessionManager: SessionManager.instance,
///   loginPath: '/login',
/// );
///
/// final router = GoRouter(
///   redirect: guard.redirect,
///   routes: [...],
/// );
/// ```
final class ProtectedRouteGuard {
  ProtectedRouteGuard({
    required SessionStateProvider sessionManager,
    this.loginPath = '/login',
    this.loadingPath,
    List<String>? publicPaths,
  })  : _sessionManager = sessionManager,
        _publicPaths = {
          loginPath,
          if (publicPaths != null) ...publicPaths,
        };

  final SessionStateProvider _sessionManager;

  /// The path to redirect to when the user is not authenticated.
  final String loginPath;

  /// An optional path to show while the session is loading.
  ///
  /// When `null`, the guard returns `null` during loading (i.e. stays on the
  /// current route) to avoid a redirect loop before state is known.
  final String? loadingPath;

  final Set<String> _publicPaths;

  // ---------------------------------------------------------------------------
  // Public paths
  // ---------------------------------------------------------------------------

  /// Paths that do not require authentication.
  ///
  /// Always includes [loginPath] and any paths supplied at construction.
  List<String> get publicPaths => List.unmodifiable(_publicPaths);

  // ---------------------------------------------------------------------------
  // Redirect logic
  // ---------------------------------------------------------------------------

  /// Called by [GoRouter] on every navigation event.
  ///
  /// Returns the path to redirect to, or `null` to allow the navigation.
  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.toString();
    final sessionState = _sessionManager.state;

    PrimekitLogger.verbose(
      'Guard evaluating location="$location" session=${sessionState.runtimeType}',
      tag: 'ProtectedRouteGuard',
    );

    // While session is loading, redirect to loadingPath or hold in place.
    if (sessionState is SessionLoading) {
      final destination = loadingPath;
      if (destination != null && location != destination) {
        PrimekitLogger.debug(
          'Session loading — redirecting to loadingPath "$destination"',
          tag: 'ProtectedRouteGuard',
        );
        return destination;
      }
      // Nowhere to send them yet; let the current route render.
      return null;
    }

    final isPublic = _isPublicPath(location);

    if (sessionState is SessionAuthenticated) {
      // Authenticated users trying to visit the login screen are sent to root.
      if (location == loginPath) {
        PrimekitLogger.debug(
          'Authenticated user on login path — redirecting to /',
          tag: 'ProtectedRouteGuard',
        );
        return '/';
      }
      // Authenticated: allow everything.
      return null;
    }

    // Unauthenticated.
    if (isPublic) {
      // Public routes are always allowed.
      return null;
    }

    PrimekitLogger.debug(
      'Unauthenticated access to "$location" — redirecting to "$loginPath"',
      tag: 'ProtectedRouteGuard',
    );
    return loginPath;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when [location] starts with any path in [_publicPaths].
  ///
  /// Prefix matching is used so that `/login/forgot-password` is correctly
  /// treated as public when `/login` is a public path.
  bool _isPublicPath(String location) {
    return _publicPaths.any(
      (public) => location == public || location.startsWith('$public/'),
    );
  }
}
