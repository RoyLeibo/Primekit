/// Widget helpers for rendering [AsyncState] and [AsyncStateNotifier].
library primekit_async_builder;

import 'package:flutter/material.dart';

import 'async_state_notifier.dart';
import 'async_state_value.dart';

/// A stateless widget that builds UI from an [AsyncState].
///
/// Provides sensible defaults for every branch so that only the [data] builder
/// is required in most cases.
///
/// ```dart
/// AsyncBuilder<User>(
///   state: notifier.state,
///   data: (user) => Text(user.name),
///   error: (e, _) => Text('Failed: $e'),
/// )
/// ```
class AsyncBuilder<T> extends StatelessWidget {
  /// Creates an [AsyncBuilder].
  ///
  /// [state] and [data] are required. All other builders have defaults.
  const AsyncBuilder({
    super.key,
    required this.state,
    required this.data,
    this.loading,
    this.error,
    this.refreshing,
  });

  /// The current async state to render.
  final AsyncState<T> state;

  /// Builder invoked when [state] is [AsyncData].
  final Widget Function(T value) data;

  /// Builder invoked when [state] is [AsyncLoading].
  ///
  /// Defaults to a centred [CircularProgressIndicator].
  final Widget Function()? loading;

  /// Builder invoked when [state] is [AsyncError].
  ///
  /// Receives the error object and an optional stack trace.
  /// Defaults to a centred error [Text].
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// Builder invoked when [state] is [AsyncRefreshing].
  ///
  /// Defaults to a [Stack] that overlays the data widget with a loading
  /// indicator.
  final Widget Function(T previousValue)? refreshing;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => loading != null
        ? loading!()
        : const Center(child: CircularProgressIndicator()),
    data: data,
    error: (e, st) =>
        error != null ? error!(e, st) : Center(child: Text('Error: $e')),
    refreshing: (prev) => refreshing != null
        ? refreshing!(prev)
        : Stack(
            alignment: Alignment.topCenter,
            children: [data(prev), const LinearProgressIndicator()],
          ),
  );
}

/// A [ListenableBuilder] wrapper that rebuilds whenever [notifier] changes and
/// renders via an [AsyncBuilder].
///
/// ```dart
/// AsyncStateBuilder<User>(
///   notifier: userNotifier,
///   data: (user) => Text(user.name),
/// )
/// ```
class AsyncStateBuilder<T> extends StatelessWidget {
  /// Creates an [AsyncStateBuilder].
  const AsyncStateBuilder({
    super.key,
    required this.notifier,
    required this.data,
    this.loading,
    this.error,
    this.refreshing,
  });

  /// The notifier whose [AsyncStateNotifier.state] drives the UI.
  final AsyncStateNotifier<T> notifier;

  /// Builder invoked when the notifier's state is [AsyncData].
  final Widget Function(T value) data;

  /// Builder invoked when the notifier's state is [AsyncLoading].
  ///
  /// Defaults to a centred [CircularProgressIndicator].
  final Widget Function()? loading;

  /// Builder invoked when the notifier's state is [AsyncError].
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// Builder invoked when the notifier's state is [AsyncRefreshing].
  final Widget Function(T previousValue)? refreshing;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: notifier,
    builder: (_, __) => AsyncBuilder<T>(
      state: notifier.state,
      data: data,
      loading: loading,
      error: error,
      refreshing: refreshing,
    ),
  );
}
