import 'flag_provider.dart';

/// A [FlagProvider] backed by a static in-memory map.
///
/// Ideal for:
/// - Unit tests — inject any values without network calls.
/// - Local dev overrides — hard-code flags during development.
/// - Offline / CI scenarios — no external dependencies.
///
/// ```dart
/// final provider = LocalFlagProvider({
///   'dark_mode': true,
///   'welcome_msg': 'Hello, tester!',
///   'max_items': 50,
/// });
/// FlagService.instance.configure(provider);
/// ```
final class LocalFlagProvider implements FlagProvider {
  /// Creates a provider from a static flag map.
  ///
  /// All flag values must be JSON-compatible primitives or maps.
  LocalFlagProvider(Map<String, dynamic> flags)
      : _flags = Map<String, dynamic>.unmodifiable(flags);

  final Map<String, dynamic> _flags;

  @override
  String get providerId => 'local';

  @override
  DateTime? get lastFetchedAt => null;

  // ---------------------------------------------------------------------------
  // Lifecycle — no-ops for local provider
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}

  // ---------------------------------------------------------------------------
  // Generic accessor
  // ---------------------------------------------------------------------------

  @override
  T getValue<T>(String key, T defaultValue) {
    final raw = _flags[key];
    if (raw is T) return raw;
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Typed accessors
  // ---------------------------------------------------------------------------

  @override
  bool getBool(String key, {required bool defaultValue}) =>
      getValue<bool>(key, defaultValue);

  @override
  String getString(String key, {required String defaultValue}) =>
      getValue<String>(key, defaultValue);

  @override
  int getInt(String key, {required int defaultValue}) =>
      getValue<int>(key, defaultValue);

  @override
  double getDouble(String key, {required double defaultValue}) {
    final raw = _flags[key];
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return defaultValue;
  }

  @override
  Map<String, dynamic> getJson(
    String key, {
    required Map<String, dynamic> defaultValue,
  }) {
    final raw = _flags[key];
    if (raw is Map<String, dynamic>) return raw;
    return defaultValue;
  }
}
