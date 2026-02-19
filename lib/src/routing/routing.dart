/// Routing — Composable route guards, deep link dispatching, navigation
/// logging, and per-tab scroll state management for Primekit.
///
/// Requires the `go_router` package.
///
/// ```dart
/// import 'package:primekit/primekit.dart';
/// // or tree-shake to just this module:
/// import 'package:primekit/src/routing/routing.dart';
/// ```
library primekit_routing;

export 'deep_link_handler.dart';
export 'navigation_logger.dart';
export 'route_guard.dart';
export 'tab_state_manager.dart';
