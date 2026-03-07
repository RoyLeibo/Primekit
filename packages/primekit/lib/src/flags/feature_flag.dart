/// Typed feature flag definition.
///
/// Use the pre-typed subclasses ([BoolFlag], [StringFlag], [IntFlag],
/// [DoubleFlag], [JsonFlag]) for convenience, or use [FeatureFlag] directly
/// with a type parameter for full control.
///
/// ```dart
/// const darkMode = BoolFlag(key: 'dark_mode', defaultValue: false);
/// const welcomeMsg = StringFlag(key: 'welcome_msg', defaultValue: 'Hello!');
/// ```
final class FeatureFlag<T> {
  /// Creates a typed feature flag.
  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.description,
  });

  /// The unique remote config / flag key.
  final String key;

  /// Value returned when the flag is not found in the provider.
  final T defaultValue;

  /// Optional human-readable description of what this flag controls.
  final String? description;

  /// Returns `true` when [T] is [bool].
  bool get isBool => T == bool;

  /// Returns `true` when [T] is [String].
  bool get isString => T == String;

  /// Returns `true` when [T] is [int].
  bool get isInt => T == int;

  /// Returns `true` when [T] is [double].
  bool get isDouble => T == double;

  @override
  String toString() => 'FeatureFlag<$T>(key: $key)';
}

// ---------------------------------------------------------------------------
// Pre-typed convenience subclasses
// ---------------------------------------------------------------------------

/// A [FeatureFlag] typed to [bool].
final class BoolFlag extends FeatureFlag<bool> {
  /// Creates a boolean feature flag.
  const BoolFlag({
    required super.key,
    required super.defaultValue,
    super.description,
  });
}

/// A [FeatureFlag] typed to [String].
final class StringFlag extends FeatureFlag<String> {
  /// Creates a string feature flag.
  const StringFlag({
    required super.key,
    required super.defaultValue,
    super.description,
  });
}

/// A [FeatureFlag] typed to [int].
final class IntFlag extends FeatureFlag<int> {
  /// Creates an integer feature flag.
  const IntFlag({
    required super.key,
    required super.defaultValue,
    super.description,
  });
}

/// A [FeatureFlag] typed to [double].
final class DoubleFlag extends FeatureFlag<double> {
  /// Creates a double feature flag.
  const DoubleFlag({
    required super.key,
    required super.defaultValue,
    super.description,
  });
}

/// A [FeatureFlag] typed to [Map<String, dynamic>] (JSON object).
final class JsonFlag extends FeatureFlag<Map<String, dynamic>> {
  /// Creates a JSON feature flag.
  const JsonFlag({
    required super.key,
    required super.defaultValue,
    super.description,
  });
}
