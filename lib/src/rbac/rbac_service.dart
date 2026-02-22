import 'package:flutter/foundation.dart';

import 'permission.dart';
import 'rbac_context.dart';
import 'rbac_policy.dart';
import 'rbac_provider.dart';

/// Singleton state holder for the current user's RBAC context.
///
/// Configure once on app start, then call [loadForUser] after sign-in and
/// [clear] on sign-out.
///
/// ```dart
/// // App startup:
/// RbacService.instance.configure(provider: myProvider, policy: myPolicy);
///
/// // After sign-in:
/// await RbacService.instance.loadForUser(userId);
///
/// // Guard a feature:
/// if (RbacService.instance.can(Permission.write('posts'))) { ... }
///
/// // On sign-out:
/// RbacService.instance.clear();
/// ```
class RbacService extends ChangeNotifier {
  RbacService._();

  static final RbacService _instance = RbacService._();

  /// The global singleton instance.
  static RbacService get instance => _instance;

  RbacProvider? _provider;
  RbacPolicy? _policy;
  RbacContext? _context;
  bool _isLoaded = false;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the service with a [provider] and [policy].
  ///
  /// Must be called before [loadForUser].
  void configure({
    required RbacProvider provider,
    required RbacPolicy policy,
  }) {
    _provider = provider;
    _policy = policy;
  }

  // ---------------------------------------------------------------------------
  // Load / clear
  // ---------------------------------------------------------------------------

  /// Loads the [RbacContext] for [userId] from the configured provider.
  ///
  /// Notifies listeners when complete.
  Future<void> loadForUser(String userId) async {
    assert(
      _provider != null,
      'Call RbacService.instance.configure() before loadForUser()',
    );
    try {
      _context = await _provider!.loadContext(userId: userId);
      _isLoaded = true;
      notifyListeners();
    } catch (error) {
      throw Exception('RbacService.loadForUser failed: $error');
    }
  }

  /// Clears the current context (call on sign-out).
  ///
  /// Notifies listeners.
  void clear() {
    _context = null;
    _isLoaded = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// The current RBAC context, or `null` before [loadForUser] completes.
  RbacContext? get context => _context;

  /// Whether [loadForUser] has completed successfully.
  bool get isLoaded => _isLoaded;

  /// The configured [RbacPolicy], or `null` before [configure] is called.
  RbacPolicy? get policy => _policy;

  // ---------------------------------------------------------------------------
  // Permission helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when the current user has [permission].
  ///
  /// Returns `false` when no context is loaded.
  bool can(Permission permission) => _context?.can(permission) ?? false;

  /// Returns `true` when the current user has **all** [permissions].
  bool canAll(List<Permission> permissions) =>
      _context?.canAll(permissions) ?? false;

  /// Returns `true` when the current user has **at least one** of
  /// [permissions].
  bool canAny(List<Permission> permissions) =>
      _context?.canAny(permissions) ?? false;

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the singleton for testing purposes.
  ///
  /// Not part of the public API — use only in tests.
  @visibleForTesting
  static void resetForTesting() {
    _instance._provider = null;
    _instance._policy = null;
    _instance._context = null;
    _instance._isLoaded = false;
  }
}
