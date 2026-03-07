/// Map extension methods.
extension PrimekitMapExtensions<K, V> on Map<K, V> {
  /// Returns the value for [key], or [fallback] if not present.
  V getOrDefault(K key, V fallback) => containsKey(key) ? this[key]! : fallback;

  /// Returns a new map with entries filtered by [test].
  Map<K, V> whereEntries(bool Function(MapEntry<K, V> entry) test) =>
      Map.fromEntries(entries.where(test));

  /// Returns a new map with values transformed by [transform].
  Map<K, R> mapValues<R>(R Function(V value) transform) =>
      map((k, v) => MapEntry(k, transform(v)));

  /// Returns a new map with keys transformed by [transform].
  Map<R, V> mapKeys<R>(R Function(K key) transform) =>
      map((k, v) => MapEntry(transform(k), v));

  /// Returns a new map merged with [other]. [other] values take precedence.
  Map<K, V> mergedWith(Map<K, V> other) => {...this, ...other};

  /// Returns `true` if the map is not empty.
  bool get isNotEmpty => !isEmpty;
}

/// Nullable map extensions.
extension PrimekitNullableMapExtensions<K, V> on Map<K, V>? {
  /// Returns the map, or an empty map if null.
  Map<K, V> get orEmpty => this ?? const {};
}
