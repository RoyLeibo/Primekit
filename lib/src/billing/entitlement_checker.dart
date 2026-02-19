import '../core/exceptions.dart';
import '../core/logger.dart';
import 'subscription_manager.dart';

// ---------------------------------------------------------------------------
// EntitlementResult
// ---------------------------------------------------------------------------

/// The result of an entitlement check for a named feature.
///
/// Use pattern-matching (switch / when) to handle all variants:
/// ```dart
/// final result = await checker.check('export_pdf');
/// switch (result) {
///   case EntitlementAllowed(:final productId):
///     print('Access granted via $productId');
///   case EntitlementDenied(:final reason):
///     showPaywall(reason);
///   case EntitlementLoading():
///     showSpinner();
/// }
/// ```
sealed class EntitlementResult {
  const EntitlementResult();

  /// Access granted because [productId] is active.
  factory EntitlementResult.allowed({required String productId}) =
      EntitlementAllowed;

  /// Access denied for [reason].
  factory EntitlementResult.denied({required String reason}) =
      EntitlementDenied;

  /// The entitlement system has not yet completed initialisation.
  factory EntitlementResult.loading() = EntitlementLoading;

  /// Convenience: `true` only for [EntitlementAllowed].
  bool get isAllowed => this is EntitlementAllowed;
}

/// Access is granted. [productId] is the active product providing the entitlement.
final class EntitlementAllowed extends EntitlementResult {
  const EntitlementAllowed({required this.productId});

  /// The product whose active subscription grants this entitlement.
  final String productId;

  @override
  String toString() => 'EntitlementAllowed(productId: $productId)';
}

/// Access is denied. [reason] is a developer-readable explanation.
final class EntitlementDenied extends EntitlementResult {
  const EntitlementDenied({required this.reason});

  /// Developer-readable denial reason.
  final String reason;

  @override
  String toString() => 'EntitlementDenied(reason: $reason)';
}

/// The entitlement system has not yet completed initialisation.
final class EntitlementLoading extends EntitlementResult {
  const EntitlementLoading();

  @override
  String toString() => 'EntitlementLoading()';
}

// ---------------------------------------------------------------------------
// EntitlementChecker
// ---------------------------------------------------------------------------

/// Checks whether the current user can access a named feature based on their
/// active subscriptions.
///
/// **Setup (once at startup):**
/// ```dart
/// EntitlementChecker.configure(
///   subscriptionManager: subscriptionManager,
///   featureToProductMap: {
///     'export_pdf':    ['primekit_pro_monthly', 'primekit_pro_yearly'],
///     'dark_theme':    ['primekit_pro_monthly', 'primekit_pro_yearly'],
///     'priority_chat': ['primekit_enterprise'],
///   },
/// );
/// ```
///
/// **Usage:**
/// ```dart
/// final checker = EntitlementChecker.instance;
/// if (await checker.canAccess('export_pdf')) {
///   exportToPdf();
/// } else {
///   showPaywall();
/// }
/// ```
class EntitlementChecker {
  EntitlementChecker._({
    required SubscriptionManager subscriptionManager,
    required Map<String, List<String>> featureToProductMap,
  })  : _subscriptionManager = subscriptionManager,
        _featureToProductMap = Map.unmodifiable(
          featureToProductMap.map(
            (k, v) => MapEntry(k, List<String>.unmodifiable(v)),
          ),
        );

  static EntitlementChecker? _instance;

  /// The singleton [EntitlementChecker] instance.
  ///
  /// Throws [ConfigurationException] if [configure] has not been called first.
  static EntitlementChecker get instance {
    if (_instance == null) {
      throw const ConfigurationException(
        message: 'EntitlementChecker not configured. '
            'Call EntitlementChecker.configure() before use.',
      );
    }
    return _instance!;
  }

  /// Returns `true` if [configure] has already been called.
  static bool get isConfigured => _instance != null;

  /// Configures and initialises the singleton [EntitlementChecker].
  ///
  /// [featureToProductMap] maps each feature name to the list of product IDs
  /// (any one of which being active grants access to the feature).
  ///
  /// Safe to call multiple times — subsequent calls overwrite the configuration.
  static void configure({
    required SubscriptionManager subscriptionManager,
    required Map<String, List<String>> featureToProductMap,
  }) {
    _instance = EntitlementChecker._(
      subscriptionManager: subscriptionManager,
      featureToProductMap: featureToProductMap,
    );
    PrimekitLogger.info(
      'EntitlementChecker configured with ${featureToProductMap.length} feature(s)',
      tag: 'EntitlementChecker',
    );
  }

  /// Resets the singleton (for testing only).
  static void reset() => _instance = null;

  // ---------------------------------------------------------------------------
  // Instance state
  // ---------------------------------------------------------------------------

  final SubscriptionManager _subscriptionManager;

  /// Immutable copy of the feature-to-product mapping supplied at configuration.
  final Map<String, List<String>> _featureToProductMap;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` if the user's active subscriptions grant access to
  /// [featureName].
  ///
  /// Returns `false` for unknown features (those not in the feature-to-product map).
  Future<bool> canAccess(String featureName) async {
    final result = await check(featureName);
    return result.isAllowed;
  }

  /// Returns a detailed [EntitlementResult] for [featureName].
  ///
  /// - [EntitlementAllowed] — user has an active product that grants access.
  /// - [EntitlementDenied] — no active product covers this feature.
  /// - [EntitlementLoading] — returned when a transient error prevents checking
  ///   (caller should retry or treat as denied).
  Future<EntitlementResult> check(String featureName) async {
    final productIds = _featureToProductMap[featureName];

    if (productIds == null || productIds.isEmpty) {
      PrimekitLogger.warning(
        'EntitlementChecker.check: unknown feature "$featureName". '
        'Register it via configure(featureToProductMap: …).',
        tag: 'EntitlementChecker',
      );
      return EntitlementResult.denied(
        reason: 'Feature "$featureName" is not registered in the entitlement map.',
      );
    }

    try {
      for (final productId in productIds) {
        final info = await _subscriptionManager.getSubscription(productId);
        if (info != null && info.isActive) {
          PrimekitLogger.verbose(
            'Entitlement granted: "$featureName" via $productId',
            tag: 'EntitlementChecker',
          );
          return EntitlementResult.allowed(productId: productId);
        }
      }

      PrimekitLogger.debug(
        'Entitlement denied: "$featureName" — no active product found '
        'among [${productIds.join(', ')}]',
        tag: 'EntitlementChecker',
      );

      return EntitlementResult.denied(
        reason: 'No active subscription grants access to "$featureName".',
      );
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'EntitlementChecker.check failed for "$featureName"',
        tag: 'EntitlementChecker',
        error: error,
        stackTrace: stack,
      );
      return EntitlementResult.loading();
    }
  }

  /// Returns all feature names the user currently has access to.
  Future<List<String>> accessibleFeatures() async {
    final results = await Future.wait(
      _featureToProductMap.keys.map(
        (feature) => check(feature).then((r) => (feature: feature, result: r)),
      ),
    );
    return results
        .where((r) => r.result.isAllowed)
        .map((r) => r.feature)
        .toList(growable: false);
  }

  /// Returns all feature names mapped to products but not currently accessible.
  Future<List<String>> blockedFeatures() async {
    final results = await Future.wait(
      _featureToProductMap.keys.map(
        (feature) => check(feature).then((r) => (feature: feature, result: r)),
      ),
    );
    return results
        .where((r) => !r.result.isAllowed)
        .map((r) => r.feature)
        .toList(growable: false);
  }

  /// The product IDs that grant access to [featureName], or an empty list if
  /// [featureName] is not registered.
  List<String> productsForFeature(String featureName) =>
      List.unmodifiable(_featureToProductMap[featureName] ?? const <String>[]);
}
