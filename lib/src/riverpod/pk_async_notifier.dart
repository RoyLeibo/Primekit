import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';

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
  /// Executes [operation], setting state to loading, then success or error.
  /// Preserves previous data during refresh when [preserveData] is true.
  Future<void> guard(
    Future<T> Function() operation, {
    bool preserveData = true,
  }) async {
    if (preserveData) {
      state = AsyncLoading<T>().copyWithPrevious(state);
    } else {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(operation);
  }

  /// Returns the current data, or null if loading or error.
  T? get currentData => state.valueOrNull;

  /// Returns true if this notifier is currently loading.
  bool get isLoading => state.isLoading;

  /// Returns the current error, or null.
  Object? get currentError => state.error;
}

/// A base class for Riverpod [StreamNotifier]s with PrimeKit patterns.
mixin PkStreamNotifierMixin<T> on StreamNotifier<T> {
  T? get currentData => state.valueOrNull;
  bool get isLoading => state.isLoading;
}

/// A base class for Riverpod [AutoDisposeAsyncNotifier]s.
mixin PkAutoDisposeAsyncNotifierMixin<T> on AutoDisposeAsyncNotifier<T> {
  Future<void> guard(
    Future<T> Function() operation, {
    bool preserveData = true,
  }) async {
    if (preserveData) {
      state = AsyncLoading<T>().copyWithPrevious(state);
    } else {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(operation);
  }

  T? get currentData => state.valueOrNull;
  bool get isLoading => state.isLoading;
}
