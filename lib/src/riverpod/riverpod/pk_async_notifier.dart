import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A base class for Riverpod [AsyncNotifier]s with built-in
/// loading/error/success lifecycle and PrimeKit's [Result] pattern.
///
/// ```dart
/// @riverpod
/// class UserNotifier extends _$UserNotifier with PkAsyncNotifierMixin<User> {
///   @override
///   Future<User> build() => fetchUser();
///
///   Future<void> refresh() => guard(() => fetchUser());
/// }
/// ```
mixin PkAsyncNotifierMixin<T> on AsyncNotifier<T> {
  bool _preserveData = true;

  /// Executes [operation], setting state to loading, then success or error.
  /// Preserves previous data during refresh when [preserveData] is true.
  Future<void> guard(
    Future<T> Function() operation, {
    bool preserveData = true,
  }) async {
    _preserveData = preserveData;
    if (preserveData) {
      // ignore: invalid_use_of_internal_member
      state = AsyncLoading<T>().copyWithPrevious(state);
    } else {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(operation);
  }

  /// Returns the current data, or null if loading (without preserve), error,
  /// or not yet loaded.
  T? get currentData {
    final s = state;
    if (s.hasError) return null;
    if (s.isLoading && !_preserveData) return null;
    return s.value;
  }

  /// Returns true if this notifier is currently loading.
  bool get isLoading => state.isLoading;

  /// Returns the current error, or null.
  Object? get currentError => state.error;
}

/// A base class for Riverpod [StreamNotifier]s with PrimeKit patterns.
mixin PkStreamNotifierMixin<T> on StreamNotifier<T> {
  T? get currentData => state.value;
  bool get isLoading => state.isLoading;
}

/// A base class for auto-dispose async notifiers.
/// In Riverpod 3.x, AutoDisposeAsyncNotifier was merged into AsyncNotifier.
/// Use [PkAsyncNotifierMixin] directly on [AsyncNotifier].
@Deprecated('Use PkAsyncNotifierMixin on AsyncNotifier instead. '
    'AutoDisposeAsyncNotifier was removed in Riverpod 3.x.')
mixin PkAutoDisposeAsyncNotifierMixin<T> on AsyncNotifier<T> {
  Future<void> guard(
    Future<T> Function() operation, {
    bool preserveData = true,
  }) async {
    if (preserveData) {
      // ignore: invalid_use_of_internal_member
      // ignore: invalid_use_of_internal_member
      state = AsyncLoading<T>().copyWithPrevious(state);
    } else {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(operation);
  }

  T? get currentData => state.value;
  bool get isLoading => state.isLoading;
}
