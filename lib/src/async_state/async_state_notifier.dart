import 'package:flutter/foundation.dart';

import 'async_state_value.dart';

/// A [ChangeNotifier] that drives a single async operation and exposes its
/// result as an [AsyncState].
///
/// Manage any single async operation (e.g. an API call) without writing
/// loading/error/data boilerplate yourself:
///
/// ```dart
/// final notifier = AsyncStateNotifier<User>();
///
/// // Starts the operation; moves state through loading → data / error.
/// await notifier.run(() => userRepository.fetchProfile());
///
/// // Listen in the UI:
/// ListenableBuilder(
///   listenable: notifier,
///   builder: (_, __) => AsyncBuilder(
///     state: notifier.state,
///     data: (user) => Text(user.name),
///   ),
/// );
/// ```
class AsyncStateNotifier<T> extends ChangeNotifier {
  AsyncStateNotifier() : _state = const AsyncLoading();

  AsyncState<T> _state;

  /// The current state of the async operation.
  AsyncState<T> get state => _state;

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  /// Executes [operation], transitioning through:
  /// `loading → data` on success, or `loading → error` on failure.
  ///
  /// Any currently in-flight [run] is not cancelled — call [reset] first if
  /// needed.
  Future<void> run(Future<T> Function() operation) async {
    _setState(const AsyncLoading());
    try {
      final result = await operation();
      _setState(AsyncData(result));
    } on Exception catch (e, st) {
      _setState(AsyncError(e, stackTrace: st));
    }
  }

  /// Executes [operation] while preserving the current value as visible data.
  ///
  /// Transitions: `refreshing(previousValue) → data` on success, or
  /// `refreshing → error` on failure.
  ///
  /// If there is no current value (state is not [AsyncData] or
  /// [AsyncRefreshing]), falls back to a plain [run].
  Future<void> refresh(Future<T> Function() operation) async {
    final previous = _state.valueOrNull;
    if (previous == null) {
      await run(operation);
      return;
    }
    _setState(AsyncRefreshing<T>(previous));
    try {
      final result = await operation();
      _setState(AsyncData(result));
    } on Exception catch (e, st) {
      _setState(AsyncError(e, stackTrace: st));
    }
  }

  /// Resets the state back to [AsyncLoading].
  void reset() => _setState(const AsyncLoading());

  /// Directly sets the state to [AsyncData] with [value].
  void setData(T value) => _setState(AsyncData(value));

  /// Directly sets the state to [AsyncError] with [error] and optional [st].
  void setError(Object error, [StackTrace? st]) =>
      _setState(AsyncError(error, stackTrace: st));

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _setState(AsyncState<T> next) {
    _state = next;
    notifyListeners();
  }
}
