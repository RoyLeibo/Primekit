/// List and Iterable extension methods.
extension PrimekitListExtensions<T> on List<T> {
  /// Returns the element at [index], or `null` if out of bounds.
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  /// Returns a new list with duplicates removed (preserving order).
  List<T> get unique {
    final seen = <T>{};
    return where(seen.add).toList();
  }

  /// Groups elements by the key returned by [keyOf].
  Map<K, List<T>> groupBy<K>(K Function(T element) keyOf) {
    final result = <K, List<T>>{};
    for (final element in this) {
      result.putIfAbsent(keyOf(element), () => []).add(element);
    }
    return result;
  }

  /// Splits the list into chunks of [size].
  List<List<T>> chunked(int size) {
    assert(size > 0, 'Chunk size must be positive');
    final result = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      result.add(sublist(i, (i + size).clamp(0, length)));
    }
    return result;
  }

  /// Returns the first element matching [test], or `null`.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Returns a new list with [element] inserted at [index].
  List<T> insertedAt(int index, T element) => [
        ...sublist(0, index),
        element,
        ...sublist(index),
      ];

  /// Returns a new list with the element at [index] replaced by [element].
  List<T> replacedAt(int index, T element) => [
        ...sublist(0, index),
        element,
        ...sublist(index + 1),
      ];

  /// Returns a new list with the element at [index] removed.
  List<T> removedAt(int index) => [
        ...sublist(0, index),
        ...sublist(index + 1),
      ];

  /// Flattens one level of nesting if this is a `List<List<T>>`.
  List<T> get flattened =>
      expand<T>((e) => e is List<T> ? e as List<T> : [e]).toList();

  /// Returns a random element, or `null` if empty.
  T? get random {
    if (isEmpty) return null;
    return this[(DateTime.now().millisecondsSinceEpoch % length).abs()];
  }
}

/// Nullable iterable extensions.
extension PrimekitNullableListExtensions<T> on List<T>? {
  /// Returns `true` if the list is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns the list, or an empty list if null.
  List<T> get orEmpty => this ?? const [];
}
