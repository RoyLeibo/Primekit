/// Core service locator with singleton, lazy-singleton, factory, scoped, and
/// async-singleton lifetimes.
library primekit_service_locator;

import 'disposable.dart';
import 'module.dart';

/// Defines how long a registered service instance lives.
enum ServiceLifetime {
  /// A single shared instance created at registration time.
  singleton,

  /// A single shared instance created on first [ServiceLocator.get] call.
  lazySingleton,

  /// A new instance created on every [ServiceLocator.get] call.
  factory,

  /// A new instance per service scope; shared within the same scope.
  scoped,
}

/// Metadata for a registered service.
///
/// Stored internally by [ServiceLocator]; consumers do not need to construct
/// this directly.
final class ServiceDescriptor {
  /// Creates a [ServiceDescriptor].
  const ServiceDescriptor({
    required this.type,
    required this.lifetime,
    required this.factory,
  });

  /// The Dart [Type] key used to look up this service.
  final Type type;

  /// How instances of this service are managed.
  final ServiceLifetime lifetime;

  /// A factory function that produces instances, receiving the owning locator.
  final Object Function(ServiceLocator locator) factory;
}

/// Lightweight service locator with lifecycle management.
///
/// Supports singleton, lazy-singleton, factory, scoped, and async-singleton
/// lifetimes. Includes helpers for testing ([reset]) and grouped registration
/// ([registerModule]).
///
/// ## Usage
///
/// ```dart
/// // Bootstrap (e.g. in main()):
/// ServiceLocator.instance
///   ..registerModule(NetworkModule())
///   ..registerModule(AuthModule());
///
/// await ServiceLocator.instance.allReady();
///
/// // Resolve anywhere:
/// final auth = ServiceLocator.instance.get<AuthService>();
/// ```
class ServiceLocator {
  /// Creates a fresh, isolated [ServiceLocator].
  ///
  /// Useful for per-screen or per-feature scopes that should not share state
  /// with the global locator, or for testing.
  ServiceLocator();

  static final ServiceLocator _instance = ServiceLocator();

  /// The default global [ServiceLocator].
  ///
  /// Use this in production code. Tests should call [reset] in `setUp`/
  /// `tearDown` to isolate state.
  static ServiceLocator get instance => _instance;

  // ---------------------------------------------------------------------------
  // Internal state (package-accessible via ServiceLocatorInternals)
  // ---------------------------------------------------------------------------

  final Map<Type, ServiceDescriptor> descriptors = {};
  final Map<Type, Object> singletons = {};

  // Async singleton support
  final Map<Type, Future<Object>> _asyncFutures = {};

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Registers a pre-built [instance] as a singleton for type [T].
  ///
  /// The same object is returned on every [get] call.
  ///
  /// ```dart
  /// locator.registerSingleton<Config>(Config.fromEnv());
  /// ```
  void registerSingleton<T extends Object>(T instance) {
    descriptors[T] = ServiceDescriptor(
      type: T,
      lifetime: ServiceLifetime.singleton,
      factory: (_) => instance,
    );
    singletons[T] = instance;
  }

  /// Registers a lazy singleton for type [T].
  ///
  /// [factory] is called once on the first [get] call; the result is cached
  /// for all subsequent calls.
  ///
  /// ```dart
  /// locator.registerLazySingleton<Database>(
  ///   (_) => SqliteDatabase('app.db'),
  /// );
  /// ```
  void registerLazySingleton<T extends Object>(
    T Function(ServiceLocator locator) factory,
  ) {
    descriptors[T] = ServiceDescriptor(
      type: T,
      lifetime: ServiceLifetime.lazySingleton,
      factory: factory,
    );
  }

  /// Registers a factory for type [T].
  ///
  /// [factory] is invoked on every [get] call, producing a new instance each
  /// time.
  ///
  /// ```dart
  /// locator.registerFactory<Logger>((_) => Logger());
  /// ```
  void registerFactory<T extends Object>(
    T Function(ServiceLocator locator) factory,
  ) {
    descriptors[T] = ServiceDescriptor(
      type: T,
      lifetime: ServiceLifetime.factory,
      factory: factory,
    );
  }

  /// Registers a scoped factory for type [T].
  ///
  /// Scoped instances are created once per scope boundary. Use this for
  /// services that should be shared within a screen but not across screens.
  ///
  /// ```dart
  /// locator.registerScoped<FormBloc>((_) => FormBloc());
  /// ```
  void registerScoped<T extends Object>(
    T Function(ServiceLocator locator) factory,
  ) {
    descriptors[T] = ServiceDescriptor(
      type: T,
      lifetime: ServiceLifetime.scoped,
      factory: factory,
    );
  }

  /// Registers an async singleton for type [T].
  ///
  /// [factory] is called once and its [Future] is cached. Await [allReady] to
  /// ensure all async singletons have resolved before consuming them.
  ///
  /// ```dart
  /// locator.registerSingletonAsync<RemoteConfig>(
  ///   (_) async {
  ///     final rc = FirebaseRemoteConfig.instance;
  ///     await rc.fetchAndActivate();
  ///     return rc;
  ///   },
  /// );
  /// await locator.allReady();
  /// ```
  void registerSingletonAsync<T extends Object>(
    Future<T> Function(ServiceLocator locator) factory,
  ) {
    final future = factory(this).then((value) {
      singletons[T] = value;
      return value;
    });
    _asyncFutures[T] = future;
    descriptors[T] = ServiceDescriptor(
      type: T,
      lifetime: ServiceLifetime.singleton,
      factory: (_) {
        if (!singletons.containsKey(T)) {
          throw StateError(
            'Async singleton $T has not resolved yet. '
            'Await ServiceLocator.allReady() before calling get<$T>().',
          );
        }
        return singletons[T]!;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Module registration
  // ---------------------------------------------------------------------------

  /// Registers all services declared by [module].
  ///
  /// ```dart
  /// locator.registerModule(AuthModule());
  /// ```
  void registerModule(DiModule module) => module.register(this);

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  /// Resolves and returns the service registered for type [T].
  ///
  /// Throws [StateError] if [T] is not registered.
  T get<T extends Object>() {
    final descriptor = descriptors[T];
    if (descriptor == null) {
      throw StateError(
        'No service registered for type $T. '
        'Did you forget to call register*<$T>()?',
      );
    }
    return _resolve<T>(descriptor);
  }

  /// Resolves the service registered for type [T], or returns `null` if not
  /// registered.
  T? tryGet<T extends Object>() {
    final descriptor = descriptors[T];
    if (descriptor == null) return null;
    return _resolve<T>(descriptor);
  }

  /// Returns `true` if a service is registered for type [T].
  bool isRegistered<T extends Object>() => descriptors.containsKey(T);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Waits for all async singletons registered with [registerSingletonAsync]
  /// to resolve.
  Future<void> allReady() async {
    await Future.wait(_asyncFutures.values);
  }

  /// Calls [PkDisposable.dispose] on all singleton instances that implement it.
  Future<void> disposeAll() async {
    final disposables = singletons.values.whereType<PkDisposable>();
    await Future.wait(disposables.map((d) => d.dispose()));
  }

  /// Clears all registrations and cached instances.
  ///
  /// Intended for use in tests; does **not** call `dispose` on existing
  /// singletons.
  void reset() {
    descriptors.clear();
    singletons.clear();
    _asyncFutures.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  T _resolve<T extends Object>(ServiceDescriptor descriptor) {
    switch (descriptor.lifetime) {
      case ServiceLifetime.singleton:
        return singletons.containsKey(T)
            ? singletons[T]! as T
            : descriptor.factory(this) as T;

      case ServiceLifetime.lazySingleton:
        return singletons.putIfAbsent(T, () => descriptor.factory(this)) as T;

      case ServiceLifetime.factory:
        return descriptor.factory(this) as T;

      case ServiceLifetime.scoped:
        // Scoped outside of an explicit scope boundary behaves like factory.
        return descriptor.factory(this) as T;
    }
  }
}
