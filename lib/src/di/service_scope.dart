import 'disposable.dart';
import 'service_locator.dart';

/// A child scope that inherits registrations from a parent [ServiceLocator]
/// but maintains its own instance cache for [ServiceLifetime.scoped] services.
///
/// Create a scope when entering a feature area (e.g. a screen) and call
/// [dispose] when leaving it. All [PkDisposable] scoped instances are cleaned
/// up automatically.
///
/// ```dart
/// final scope = ServiceScope.of(ServiceLocator.instance);
///
/// // Resolves scoped instances independently from the parent:
/// final bloc = scope.get<FormBloc>();
///
/// // Clean up when done (e.g. in State.dispose):
/// await scope.dispose();
/// ```
class ServiceScope {
  ServiceScope._(this._parent);

  /// Creates a [ServiceScope] whose registrations are inherited from [parent].
  factory ServiceScope.of(ServiceLocator parent) => ServiceScope._(parent);

  final ServiceLocator _parent;
  final Map<Type, Object> _scopedInstances = {};
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  /// Resolves the service registered for type [T].
  ///
  /// For [ServiceLifetime.scoped] services the instance is created once within
  /// this scope and reused for subsequent calls. For all other lifetimes the
  /// parent locator's behaviour is used.
  ///
  /// Throws [StateError] if the scope has been disposed or [T] is not
  /// registered.
  T get<T extends Object>() {
    if (_disposed) {
      throw StateError('ServiceScope has been disposed. Create a new scope.');
    }

    final descriptor = _parent.descriptors[T];
    if (descriptor == null) return _parent.get<T>();

    if (descriptor.lifetime == ServiceLifetime.scoped) {
      return _scopedInstances.putIfAbsent(T, () => descriptor.factory(_parent))
          as T;
    }

    return _parent.get<T>();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Disposes all [PkDisposable] scoped instances and marks the scope as
  /// closed.
  ///
  /// After calling [dispose], any further call to [get] will throw.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final disposables = _scopedInstances.values.whereType<PkDisposable>();
    await Future.wait(disposables.map((d) => d.dispose()));
    _scopedInstances.clear();
  }
}
