import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A composable guard that can allow or redirect a navigation attempt.
///
/// Implement this abstract class to create guards such as authentication
/// checks, subscription tier gates, or feature-flag walls, then attach them
/// to [GoRouter] redirect callbacks:
///
/// ```dart
/// final authGuard = AuthRouteGuard(authRepo: repo);
/// final tierGuard = TierRouteGuard(membership: membershipService);
///
/// GoRouter(
///   redirect: RouteGuard.all([authGuard, tierGuard]).redirect,
///   routes: [...],
/// )
/// ```
abstract class RouteGuard {
  /// Evaluates whether navigation to [state] should proceed.
  ///
  /// Return `null` to allow navigation. Return a path string (e.g. `/login`)
  /// to redirect the user instead.
  Future<String?> redirect(BuildContext context, GoRouterState state);

  // ---------------------------------------------------------------------------
  // Composition helpers
  // ---------------------------------------------------------------------------

  /// Creates a guard that runs [guards] in sequence.
  ///
  /// The first guard that returns a non-null redirect path wins. If all
  /// guards return `null` the navigation is allowed.
  static RouteGuard all(List<RouteGuard> guards) =>
      _AllRouteGuard(guards: guards);

  /// Creates a guard that allows navigation if **any** guard in [guards]
  /// returns `null`.
  ///
  /// Navigation is blocked (redirected to the first non-null path) only when
  /// **every** guard wants to redirect.
  static RouteGuard any(List<RouteGuard> guards) =>
      _AnyRouteGuard(guards: guards);
}

// ---------------------------------------------------------------------------
// Composite guards
// ---------------------------------------------------------------------------

/// Runs guards in sequence; returns the first non-null redirect, or `null`
/// when all guards pass.
class CompositeRouteGuard extends RouteGuard {
  /// Creates a composite guard from [guards].
  CompositeRouteGuard({required this.guards});

  /// The ordered list of guards to evaluate.
  final List<RouteGuard> guards;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    for (final guard in guards) {
      final redirect = await guard.redirect(context, state);
      if (redirect != null) return redirect;
    }
    return null;
  }
}

/// Returns the first non-null redirect only if every guard wants to redirect.
/// If any guard returns null the navigation is allowed.
class _AnyRouteGuard extends RouteGuard {
  _AnyRouteGuard({required this.guards});

  final List<RouteGuard> guards;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    String? lastRedirect;
    for (final guard in guards) {
      final redirect = await guard.redirect(context, state);
      if (redirect == null) return null; // At least one guard passes.
      lastRedirect = redirect;
    }
    // Every guard wanted to redirect; honour the last one.
    return lastRedirect;
  }
}

/// Internal implementation of [RouteGuard.all].
class _AllRouteGuard extends CompositeRouteGuard {
  _AllRouteGuard({required super.guards});
}
