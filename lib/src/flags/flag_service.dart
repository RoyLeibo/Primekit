import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'feature_flag.dart';
import 'flag_provider.dart';

/// High-level API for feature flags, remote config, and A/B testing.
///
/// Call [configure] once (typically in `main()`) with a [FlagProvider], then
/// use [get] / [isEnabled] anywhere in the app:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   FlagService.instance.configure(FirebaseFlagProvider());
///   await FlagService.instance.refresh();
///   runApp(const MyApp());
/// }
///
/// // Elsewhere:
/// const darkMode = BoolFlag(key: 'dark_mode', defaultValue: false);
/// final isOn = FlagService.instance.isEnabled(darkMode); // true / false
/// ```
///
/// Local overrides (for QA / dev) take precedence over the active provider:
/// ```dart
/// FlagService.instance.setOverride(darkMode, true);
/// ```
final class FlagService {
  FlagService._();

  static final FlagService _instance = FlagService._();

  /// The shared singleton instance.
  static FlagService get instance => _instance;

  static const String _tag = 'FlagService';

  FlagProvider? _provider;

  /// Local overrides: key → raw override value.
  final Map<String, dynamic> _overrides = {};

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the active [FlagProvider].
  ///
  /// Must be called before [get] or [isEnabled]. Calling again replaces the
  /// current provider (useful in tests).
  void configure(FlagProvider provider) {
    _provider = provider;
    PrimekitLogger.info(
      'Configured with provider: ${provider.providerId}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Flag reading
  // ---------------------------------------------------------------------------

  /// Returns the typed value for [flag].
  ///
  /// Resolution order:
  /// 1. Local override (set via [setOverride]).
  /// 2. Active provider.
  /// 3. Flag's [FeatureFlag.defaultValue].
  ///
  /// Throws [ConfigurationException] when [configure] has not been called.
  T get<T>(FeatureFlag<T> flag) {
    final override = _overrides[flag.key];
    if (override != null && override is T) {
      PrimekitLogger.debug(
        'Override active for "${flag.key}": $override',
        tag: _tag,
      );
      return override;
    }

    final provider = _requireProvider();
    return provider.getValue<T>(flag.key, flag.defaultValue);
  }

  /// Returns `true` when the [flag] value resolves to `true`.
  bool isEnabled(BoolFlag flag) => get<bool>(flag);

  // ---------------------------------------------------------------------------
  // A/B testing
  // ---------------------------------------------------------------------------

  /// Assigns [userId] to a variant based on a deterministic hash of
  /// `'$experimentKey:$userId'`.
  ///
  /// The same user always receives the same variant for a given experiment.
  /// [weights] must sum to 1.0 and have the same length as [variants].
  /// When [weights] is omitted, variants are equally distributed.
  ///
  /// ```dart
  /// final variant = FlagService.instance.abVariant(
  ///   experimentKey: 'checkout_cta',
  ///   userId: currentUser.id,
  ///   variants: ['control', 'v1', 'v2'],
  /// );
  /// ```
  String abVariant({
    required String experimentKey,
    required String userId,
    required List<String> variants,
    List<double>? weights,
  }) {
    assert(variants.isNotEmpty, 'variants must not be empty');

    final effectiveWeights = weights ?? _equalWeights(variants.length);

    assert(
      effectiveWeights.length == variants.length,
      'weights.length must equal variants.length',
    );
    assert(
      (effectiveWeights.fold(0.0, (a, b) => a + b) - 1.0).abs() < 0.0001,
      'weights must sum to 1.0',
    );

    final bucket = _userBucket('$experimentKey:$userId');
    var cumulative = 0.0;
    for (var i = 0; i < variants.length; i++) {
      cumulative += effectiveWeights[i];
      if (bucket < cumulative) return variants[i];
    }
    // Fallback to last variant in case of floating-point rounding.
    return variants.last;
  }

  // ---------------------------------------------------------------------------
  // Overrides (dev / QA)
  // ---------------------------------------------------------------------------

  /// Sets a local override for [flag] with [value].
  ///
  /// Overrides take precedence over the active provider. Use [clearOverride]
  /// or [clearAllOverrides] to remove them.
  void setOverride<T>(FeatureFlag<T> flag, T value) {
    _overrides[flag.key] = value;
    PrimekitLogger.debug('Override set for "${flag.key}": $value', tag: _tag);
  }

  /// Removes the local override for [flag].
  void clearOverride<T>(FeatureFlag<T> flag) {
    _overrides.remove(flag.key);
    PrimekitLogger.debug('Override cleared for "${flag.key}".', tag: _tag);
  }

  /// Removes all local overrides.
  void clearAllOverrides() {
    _overrides.clear();
    PrimekitLogger.debug('All overrides cleared.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  /// Delegates a refresh call to the active provider.
  Future<void> refresh() async {
    final provider = _requireProvider();
    await provider.refresh();
  }

  /// Returns the UTC time of the last successful provider fetch.
  DateTime? get lastFetchedAt => _provider?.lastFetchedAt;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  FlagProvider _requireProvider() {
    final provider = _provider;
    if (provider == null) {
      throw const ConfigurationException(
        message: 'FlagService.configure() must be called before reading flags.',
      );
    }
    return provider;
  }

  /// Converts a user + experiment key into a [0, 1) bucket value using SHA-256.
  double _userBucket(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    // Use the first 4 bytes of the hash as a 32-bit unsigned integer.
    final value =
        (digest.bytes[0] << 24) |
        (digest.bytes[1] << 16) |
        (digest.bytes[2] << 8) |
        digest.bytes[3];
    // Normalise to [0, 1).
    return value / 0xFFFFFFFF;
  }

  List<double> _equalWeights(int count) =>
      List<double>.filled(count, 1.0 / count);

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the service to its unconfigured state. For use in tests only.
  void resetForTesting() {
    _provider = null;
    _overrides.clear();
  }
}
