/// DiModule — groups related service registrations.
library primekit_di_module;

import 'service_locator.dart';

/// A logical grouping of service registrations.
///
/// Implement [DiModule] to co-locate all registrations for a single feature
/// area. Register the module via [ServiceLocator.registerModule].
///
/// ```dart
/// class AuthModule implements DiModule {
///   @override
///   void register(ServiceLocator locator) {
///     locator.registerLazySingleton<AuthService>(
///       (_) => FirebaseAuthService(),
///     );
///     locator.registerLazySingleton<TokenStorage>(
///       (_) => SecureTokenStorage(),
///     );
///   }
/// }
///
/// // In app bootstrap:
/// ServiceLocator.instance.registerModule(AuthModule());
/// ```
abstract interface class DiModule {
  /// Registers this module's services into [locator].
  void register(ServiceLocator locator);
}
