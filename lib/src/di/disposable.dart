/// Disposable interface for services managed by [ServiceLocator].
library primekit_disposable;

import 'service_locator.dart';
import 'service_scope.dart';

/// Implemented by services that need deterministic cleanup when their
/// enclosing [ServiceLocator] scope is torn down.
///
/// [ServiceLocator.disposeAll] calls [dispose] on every singleton that
/// implements this interface. [ServiceScope.dispose] calls it on scoped
/// instances when a scope is torn down.
///
/// ```dart
/// class DatabaseService implements PkDisposable {
///   @override
///   Future<void> dispose() async => _connection.close();
/// }
/// ```
abstract interface class PkDisposable {
  /// Releases any resources held by this service.
  ///
  /// Called by [ServiceLocator.disposeAll] on singletons, and by
  /// [ServiceScope.dispose] on scoped instances.
  Future<void> dispose();
}
