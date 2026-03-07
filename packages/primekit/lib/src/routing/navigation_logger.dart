import 'package:flutter/material.dart';

/// A backend-agnostic interface for forwarding screen-view events from
/// [NavigationLogger].
///
/// Implement this to forward events to Firebase Analytics, Amplitude,
/// Mixpanel, or any other analytics backend.
abstract interface class NavigationAnalyticsProvider {
  /// Logs a screen view event.
  ///
  /// [screenName] is the route name. [parameters] carries any extra metadata
  /// (e.g. previous screen, arguments).
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object?>? parameters,
  });
}

/// A [NavigatorObserver] that logs every route transition.
///
/// Attach it to [MaterialApp.navigatorObservers] or `GoRouter` observers to
/// automatically capture push, pop, and replace events:
///
/// ```dart
/// final logger = NavigationLogger(
///   analyticsProvider: myAnalyticsProvider,
///   logToConsole: kDebugMode,
/// );
///
/// MaterialApp(
///   navigatorObservers: [logger],
///   ...
/// )
/// ```
class NavigationLogger extends NavigatorObserver {
  /// Creates a [NavigationLogger].
  ///
  /// [analyticsProvider] receives `screen_view` events for every route
  /// transition. [logToConsole] mirrors events to [debugPrint] when `true`.
  NavigationLogger({this.analyticsProvider, this.logToConsole = true});

  /// Optional analytics backend to forward screen-view events to.
  final NavigationAnalyticsProvider? analyticsProvider;

  /// Whether to mirror navigation events to [debugPrint].
  final bool logToConsole;

  // ---------------------------------------------------------------------------
  // NavigatorObserver overrides
  // ---------------------------------------------------------------------------

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logEvent(event: 'push', current: route, previous: previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logEvent(event: 'pop', current: previousRoute, previous: route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logEvent(event: 'replace', current: newRoute, previous: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logEvent(event: 'remove', current: previousRoute, previous: route);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _logEvent({
    required String event,
    Route<dynamic>? current,
    Route<dynamic>? previous,
  }) {
    final currentName = _routeName(current);
    final previousName = _routeName(previous);

    if (currentName == null) return;

    if (logToConsole) {
      debugPrint('[NavigationLogger] $event: $previousName -> $currentName');
    }

    analyticsProvider?.logScreenView(
      currentName,
      parameters: {'event': event, 'previous_screen': ?previousName},
    );
  }

  String? _routeName(Route<dynamic>? route) {
    if (route == null) return null;
    final name = route.settings.name;
    return (name != null && name.isNotEmpty)
        ? name
        : route.runtimeType.toString();
  }
}
