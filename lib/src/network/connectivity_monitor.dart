import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../core/logger.dart';

/// Monitors network connectivity and exposes a debounced stream of
/// connection-state changes.
///
/// Uses the `connectivity_plus` package under the hood and deduplications
/// rapid flaps with a 500 ms debounce so consumers never see spurious
/// on/off toggles.
///
/// ```dart
/// final monitor = ConnectivityMonitor.instance;
///
/// // One-shot check
/// final isOnline = await monitor.checkNow();
///
/// // React to changes
/// monitor.isConnected.listen((online) {
///   if (!online) showOfflineBanner();
/// });
/// ```
final class ConnectivityMonitor {
  ConnectivityMonitor._() {
    _init();
  }

  static final ConnectivityMonitor _instance = ConnectivityMonitor._();

  /// The shared singleton instance.
  static ConnectivityMonitor get instance => _instance;

  static const String _tag = 'ConnectivityMonitor';
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  final Connectivity _connectivity = Connectivity();

  /// Backing subject — starts with `true` (optimistic) until first check.
  final BehaviorSubject<bool> _statusSubject =
      BehaviorSubject<bool>.seeded(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// A debounced stream that emits `true` when connected and `false` when
  /// offline.
  ///
  /// The stream is backed by a [BehaviorSubject], so new subscribers
  /// immediately receive the latest known status.
  Stream<bool> get isConnected => _statusSubject.stream
      .debounceTime(_debounceDuration)
      .distinct();

  /// The most recently observed connectivity status.
  ///
  /// Returns `true` if the device was last observed to be online.
  bool get currentStatus => _statusSubject.value;

  /// Performs an immediate connectivity check and returns the result.
  ///
  /// Also updates [currentStatus] and emits on [isConnected] if the status
  /// has changed.
  Future<bool> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = _isConnected(results);
      _update(connected);
      return connected;
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to check connectivity.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      return _statusSubject.value;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _init() {
    // Perform an initial check asynchronously so the singleton constructor
    // doesn't block.
    checkNow();

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final connected = _isConnected(results);
        PrimekitLogger.verbose(
          'Connectivity changed: ${connected ? "online" : "offline"}.',
          tag: _tag,
        );
        _update(connected);
      },
      onError: (Object error, StackTrace stack) {
        PrimekitLogger.error(
          'Connectivity stream error.',
          tag: _tag,
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  void _update(bool connected) {
    if (_statusSubject.value != connected) {
      PrimekitLogger.info(
        'Network is now ${connected ? "online" : "offline"}.',
        tag: _tag,
      );
    }
    _statusSubject.add(connected);
  }

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Injects a connectivity value for unit tests.
  @visibleForTesting
  void injectStatusForTesting(bool connected) => _statusSubject.add(connected);

  /// Disposes the underlying stream subscription and subject.
  ///
  /// Only needed in tests; the singleton lives for the app lifetime in
  /// production.
  @visibleForTesting
  Future<void> disposeForTesting() async {
    await _subscription?.cancel();
    await _statusSubject.close();
  }
}
