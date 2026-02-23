import '../core/logger.dart';
import 'membership_tier.dart';

/// Maps named features to the minimum [MembershipTier] required to access them.
///
/// Define the policy once at startup and consult it wherever access-control
/// decisions are needed:
///
/// ```dart
/// final policy = AccessPolicy();
/// policy.define('export_pdf',  MembershipTier.pro);
/// policy.define('sso',         MembershipTier.enterprise);
///
/// // Check a specific user's tier:
/// if (policy.canAccess('export_pdf', userTier)) {
///   exportToPdf();
/// }
///
/// // List everything a pro user can do:
/// final features = policy.featuresAvailableTo(MembershipTier.pro);
/// ```
class AccessPolicy {
  /// Creates an empty policy. Features must be [define]d before querying.
  AccessPolicy();

  final Map<String, MembershipTier> _policy = {};

  static const String _tag = 'AccessPolicy';

  // ---------------------------------------------------------------------------
  // Policy definition
  // ---------------------------------------------------------------------------

  /// Registers [featureName] as requiring at least [requiredTier] for access.
  ///
  /// Calling [define] a second time with the same [featureName] overwrites the
  /// previous requirement.
  void define(String featureName, MembershipTier requiredTier) {
    assert(featureName.isNotEmpty, 'featureName must not be empty');
    _policy[featureName] = requiredTier;
    PrimekitLogger.verbose(
      'AccessPolicy: "$featureName" requires ${requiredTier.name}',
      tag: _tag,
    );
  }

  /// Registers multiple [definitions] at once.
  ///
  /// The map keys are feature names; values are the required tiers.
  void defineAll(Map<String, MembershipTier> definitions) {
    definitions.forEach(define);
  }

  /// Removes a previously defined feature from the policy.
  ///
  /// After removal, [canAccess] will return `true` for the feature (open access).
  void undefine(String featureName) => _policy.remove(featureName);

  /// Removes all defined features (useful in tests).
  void clear() => _policy.clear();

  // ---------------------------------------------------------------------------
  // Access queries
  // ---------------------------------------------------------------------------

  /// Returns `true` if [userTier] meets or exceeds the required tier for
  /// [featureName].
  ///
  /// Returns `true` for features that have not been explicitly [define]d
  /// (open access by default).
  bool canAccess(String featureName, MembershipTier userTier) {
    final required = _policy[featureName];
    if (required == null) return true; // Undefined → open access.
    return userTier.isAtLeast(required);
  }

  /// Returns the minimum [MembershipTier] required to access [featureName],
  /// or `null` if the feature is not in the policy (open access).
  MembershipTier? requiredTierFor(String featureName) => _policy[featureName];

  /// Returns all feature names that [tier] can access given this policy,
  /// including features that are open (undefined) would need to be known
  /// externally — this method returns only explicitly defined features that
  /// [tier] qualifies for.
  List<String> featuresAvailableTo(MembershipTier tier) => _policy.entries
      .where((e) => tier.isAtLeast(e.value))
      .map((e) => e.key)
      .toList(growable: false);

  /// Returns all feature names that [tier] cannot access.
  List<String> featuresLockedFor(MembershipTier tier) => _policy.entries
      .where((e) => !tier.isAtLeast(e.value))
      .map((e) => e.key)
      .toList(growable: false);

  /// Returns all explicitly defined feature names.
  List<String> get allDefinedFeatures =>
      List.unmodifiable(_policy.keys.toList(growable: false));

  /// The number of features defined in this policy.
  int get length => _policy.length;

  /// Whether the policy has no defined features.
  bool get isEmpty => _policy.isEmpty;

  /// Returns a copy of the underlying policy map (immutable snapshot).
  Map<String, MembershipTier> get snapshot => Map.unmodifiable(Map.of(_policy));
}
