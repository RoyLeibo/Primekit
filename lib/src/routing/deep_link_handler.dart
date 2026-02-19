import 'dart:async';

import 'package:go_router/go_router.dart';

/// A configured route pattern and the function that translates a matching
/// [Uri] into a [GoRouter]-compatible path string.
class DeepLinkRoute {
  /// Creates a deep link route.
  ///
  /// [pattern] can be either a [String] (substring match) or a [RegExp]
  /// for more complex matching.
  ///
  /// [handler] receives the full [Uri] and must return the go_router path to
  /// navigate to (e.g. `/products/42`).
  const DeepLinkRoute({
    required Object pattern,
    required this.handler,
  }) : _pattern = pattern;

  final Object _pattern;

  /// Translates a matched uri into a GoRouter-compatible destination path.
  final String Function(Uri uri) handler;

  /// Returns `true` if this route matches [uri].
  bool matches(Uri uri) {
    final input = uri.toString();
    if (_pattern is String) {
      return input.contains(_pattern as String);
    } else if (_pattern is RegExp) {
      return (_pattern as RegExp).hasMatch(input);
    }
    return false;
  }
}

/// Parses and dispatches incoming deep links to a [GoRouter] instance.
///
/// Register URL patterns with corresponding handlers, then call [handleLink]
/// whenever the app receives a URI (from app links, universal links, or
/// custom schemes).
///
/// ```dart
/// final handler = DeepLinkHandler();
/// handler.configure(
///   router: myGoRouter,
///   routes: [
///     DeepLinkRoute(
///       pattern: RegExp(r'/products/(\d+)'),
///       handler: (uri) => '/products/${uri.pathSegments.last}',
///     ),
///     DeepLinkRoute(
///       pattern: '/invite',
///       handler: (uri) => '/join?code=${uri.queryParameters['code']}',
///     ),
///   ],
/// );
///
/// // On app launch / resume:
/// handler.handleLink(incomingUri);
///
/// // Or listen to the stream:
/// handler.incomingLinks.listen((uri) => print('Got link: $uri'));
/// ```
class DeepLinkHandler {
  GoRouter? _router;
  List<DeepLinkRoute> _routes = const [];

  final StreamController<Uri> _incomingLinksController =
      StreamController<Uri>.broadcast();

  /// A broadcast stream that emits every URI passed to [handleLink],
  /// regardless of whether it matched a registered route.
  Stream<Uri> get incomingLinks => _incomingLinksController.stream;

  /// Attaches the handler to a [GoRouter] and registers the URL [routes].
  ///
  /// This method is idempotent and may be called again to update routes.
  void configure({
    required GoRouter router,
    List<DeepLinkRoute> routes = const [],
  }) {
    _router = router;
    _routes = List.unmodifiable(routes);
  }

  /// Handles an incoming [uri] by finding a matching [DeepLinkRoute] and
  /// navigating via [GoRouter.go].
  ///
  /// Emits the URI on [incomingLinks] before attempting navigation so
  /// listeners can react regardless of route matching.
  ///
  /// Does nothing if [configure] has not been called yet.
  void handleLink(Uri uri) {
    _incomingLinksController.add(uri);

    final router = _router;
    if (router == null) return;

    for (final route in _routes) {
      if (route.matches(uri)) {
        try {
          final path = route.handler(uri);
          router.go(path);
        } on Exception {
          // Handler threw; skip this route and try the next.
        }
        return;
      }
    }
    // No route matched; navigation is not attempted.
  }

  /// Releases the internal stream controller.
  ///
  /// Call this when the handler is no longer needed to prevent memory leaks.
  void dispose() {
    _incomingLinksController.close();
  }
}
