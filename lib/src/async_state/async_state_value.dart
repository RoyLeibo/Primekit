/// Core sealed class for representing the four states of an async operation.
///
/// Replaces the common `isLoading`/`error`/`data` bool triad with a typed,
/// exhaustive sealed class.
///
/// ```dart
/// AsyncState<User> state = AsyncState.loading();
///
/// state.when(
///   loading: () => const CircularProgressIndicator(),
///   data: (user) => Text(user.name),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
library primekit_async_state_value;

/// Represents the four possible states of an asynchronous operation:
/// loading, data, error, and refreshing.
///
/// Use the factory constructors to create instances and [when] / [maybeWhen]
/// to exhaustively pattern-match over the current state.
sealed class AsyncState<T> {
  /// Creates an [AsyncLoading] state — no data available yet.
  const factory AsyncState.loading() = AsyncLoading<T>;

  /// Creates an [AsyncData] state with the resolved [value].
  const factory AsyncState.data(T value) = AsyncData<T>;

  /// Creates an [AsyncError] state with the given [error] and optional
  /// [stackTrace].
  const factory AsyncState.error(Object error, {StackTrace? stackTrace}) =
      AsyncError<T>;

  /// Creates an [AsyncRefreshing] state that retains a [previousValue] while
  /// a new load is in flight.
  factory AsyncState.refreshing(T previousValue) = AsyncRefreshing<T>;

  // ---------------------------------------------------------------------------
  // Pattern matching
  // ---------------------------------------------------------------------------

  /// Exhaustively matches the current state and returns a value of type [R].
  ///
  /// If [refreshing] is omitted, the [loading] branch is used for
  /// [AsyncRefreshing] states.
  ///
  /// ```dart
  /// final widget = state.when(
  ///   loading: () => const CircularProgressIndicator(),
  ///   data: (value) => Text('$value'),
  ///   error: (e, _) => Text('Error: $e'),
  /// );
  /// ```
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T previousValue)? refreshing,
  });

  /// Like [when], but provides an [orElse] fallback for unhandled branches.
  ///
  /// ```dart
  /// final label = state.maybeWhen(
  ///   data: (v) => v.toString(),
  ///   orElse: () => '…',
  /// );
  /// ```
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T previousValue)? refreshing,
  });

  // ---------------------------------------------------------------------------
  // Transformations
  // ---------------------------------------------------------------------------

  /// Transforms the contained value with [transform] when this is an
  /// [AsyncData] or [AsyncRefreshing] state.
  ///
  /// Loading and error states are preserved with the new type parameter [R].
  ///
  /// ```dart
  /// AsyncState<String> nameState = userState.map((u) => u.name);
  /// ```
  AsyncState<R> map<R>(R Function(T value) transform);

  // ---------------------------------------------------------------------------
  // Convenience accessors
  // ---------------------------------------------------------------------------

  /// The contained value, or `null` if this is not [AsyncData] or
  /// [AsyncRefreshing].
  T? get valueOrNull;

  /// The contained error, or `null` if this is not [AsyncError].
  Object? get errorOrNull;

  /// `true` only when this is an [AsyncLoading] state.
  bool get isLoading;

  /// `true` only when this is an [AsyncData] state.
  bool get isData;

  /// `true` only when this is an [AsyncError] state.
  bool get isError;

  /// `true` only when this is an [AsyncRefreshing] state.
  bool get isRefreshing;

  /// `true` when a value is available — i.e. for [AsyncData] and
  /// [AsyncRefreshing].
  bool get hasValue;
}

// ---------------------------------------------------------------------------
// Concrete subtypes
// ---------------------------------------------------------------------------

/// The initial, empty loading state — no data or error is available.
final class AsyncLoading<T> implements AsyncState<T> {
  /// Creates an [AsyncLoading] state.
  const AsyncLoading();

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T previousValue)? refreshing,
  }) => loading();

  @override
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T previousValue)? refreshing,
  }) => loading != null ? loading() : orElse();

  @override
  AsyncState<R> map<R>(R Function(T value) transform) => AsyncLoading<R>();

  @override
  T? get valueOrNull => null;

  @override
  Object? get errorOrNull => null;

  @override
  bool get isLoading => true;

  @override
  bool get isData => false;

  @override
  bool get isError => false;

  @override
  bool get isRefreshing => false;

  @override
  bool get hasValue => false;

  @override
  bool operator ==(Object other) => other is AsyncLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AsyncState<$T>.loading()';
}

/// A successfully resolved state carrying the produced [value].
final class AsyncData<T> implements AsyncState<T> {
  /// Creates an [AsyncData] state with the given [value].
  const AsyncData(this.value);

  /// The resolved value.
  final T value;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T previousValue)? refreshing,
  }) => data(value);

  @override
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T previousValue)? refreshing,
  }) => data != null ? data(value) : orElse();

  @override
  AsyncState<R> map<R>(R Function(T value) transform) =>
      AsyncData<R>(transform(value));

  @override
  T get valueOrNull => value;

  @override
  Object? get errorOrNull => null;

  @override
  bool get isLoading => false;

  @override
  bool get isData => true;

  @override
  bool get isError => false;

  @override
  bool get isRefreshing => false;

  @override
  bool get hasValue => true;

  @override
  bool operator ==(Object other) =>
      other is AsyncData<T> && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'AsyncState<$T>.data($value)';
}

/// A failed state carrying the [error] and an optional [stackTrace].
final class AsyncError<T> implements AsyncState<T> {
  /// Creates an [AsyncError] state.
  const AsyncError(this.error, {this.stackTrace});

  /// The error that caused the failure.
  final Object error;

  /// The stack trace associated with [error], if available.
  final StackTrace? stackTrace;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T previousValue)? refreshing,
  }) => error(this.error, stackTrace);

  @override
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T previousValue)? refreshing,
  }) => error != null ? error(this.error, stackTrace) : orElse();

  @override
  AsyncState<R> map<R>(R Function(T value) transform) =>
      AsyncError<R>(error, stackTrace: stackTrace);

  @override
  T? get valueOrNull => null;

  @override
  Object get errorOrNull => error;

  @override
  bool get isLoading => false;

  @override
  bool get isData => false;

  @override
  bool get isError => true;

  @override
  bool get isRefreshing => false;

  @override
  bool get hasValue => false;

  @override
  bool operator ==(Object other) =>
      other is AsyncError<T> &&
      other.error == error &&
      other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace);

  @override
  String toString() => 'AsyncState<$T>.error($error)';
}

/// A refreshing state that shows [previousValue] while a new load is in flight.
///
/// Useful for pull-to-refresh: the UI can keep showing the old value while
/// a loading indicator is overlaid.
final class AsyncRefreshing<T> implements AsyncState<T> {
  /// Creates an [AsyncRefreshing] state with the given [previousValue].
  const AsyncRefreshing(this.previousValue);

  /// The last successfully loaded value, visible during the refresh.
  final T previousValue;

  @override
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T previousValue)? refreshing,
  }) => refreshing != null ? refreshing(previousValue) : loading();

  @override
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T previousValue)? refreshing,
  }) => refreshing != null ? refreshing(previousValue) : orElse();

  @override
  AsyncState<R> map<R>(R Function(T value) transform) =>
      AsyncRefreshing<R>(transform(previousValue));

  @override
  T get valueOrNull => previousValue;

  @override
  Object? get errorOrNull => null;

  @override
  bool get isLoading => false;

  @override
  bool get isData => false;

  @override
  bool get isError => false;

  @override
  bool get isRefreshing => true;

  @override
  bool get hasValue => true;

  @override
  bool operator ==(Object other) =>
      other is AsyncRefreshing<T> && other.previousValue == previousValue;

  @override
  int get hashCode => Object.hash(runtimeType, previousValue);

  @override
  String toString() => 'AsyncState<$T>.refreshing($previousValue)';
}
