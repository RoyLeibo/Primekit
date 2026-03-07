/// Abstract backend contract for all flag / remote-config providers.
///
/// Implementations must supply typed accessors and lifecycle methods.
/// [FlagService] delegates all reads through this interface, so providers
/// are interchangeable (Firebase, MongoDB, local map, cached wrapper, etc.).
abstract interface class FlagProvider {
  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the provider (e.g. fetch + activate remote config).
  ///
  /// Must be called before any [getValue] call.
  Future<void> initialize();

  /// Requests a fresh value set from the remote source.
  ///
  /// The provider should update its in-memory state after this call.
  Future<void> refresh();

  // ---------------------------------------------------------------------------
  // Generic accessor
  // ---------------------------------------------------------------------------

  /// Returns the value for [key], falling back to [defaultValue] if the key
  /// does not exist or has an incompatible type.
  T getValue<T>(String key, T defaultValue);

  // ---------------------------------------------------------------------------
  // Typed accessors
  // ---------------------------------------------------------------------------

  /// Returns a boolean flag value.
  bool getBool(String key, {required bool defaultValue});

  /// Returns a string flag value.
  String getString(String key, {required String defaultValue});

  /// Returns an integer flag value.
  int getInt(String key, {required int defaultValue});

  /// Returns a double flag value.
  double getDouble(String key, {required double defaultValue});

  /// Returns a JSON object flag value.
  Map<String, dynamic> getJson(
    String key, {
    required Map<String, dynamic> defaultValue,
  });

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  /// A stable identifier for this provider (e.g. `'firebase'`, `'mongo'`).
  String get providerId;

  /// The UTC time of the last successful fetch, or `null` if never fetched.
  DateTime? get lastFetchedAt;
}
