import 'package:flutter/material.dart';

import 'crash_reporter.dart';

/// A Flutter widget that catches errors thrown by its [child] subtree.
///
/// [ErrorBoundary] installs a scoped [FlutterError.onError] handler when it
/// is active (i.e. [child] is showing).  When a build-time error occurs
/// anywhere in the subtree, the handler fires, [reporter] records the error,
/// [onError] is called, and on the next frame [fallback] is shown instead.
///
/// ```dart
/// ErrorBoundary(
///   reporter: CrashConfig.reporter,
///   fallback: const Text('Something went wrong'),
///   child: MyWidget(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  /// Creates an [ErrorBoundary].
  const ErrorBoundary({
    required this.child,
    super.key,
    this.fallback,
    this.onError,
    this.reporter,
  });

  /// The widget subtree to guard.
  final Widget child;

  /// Widget shown when [child] throws.  Defaults to a plain error card.
  final Widget? fallback;

  /// Called with the error and stack trace whenever [child] throws.
  final void Function(Object error, StackTrace stack)? onError;

  /// When non-null, errors are automatically forwarded to this reporter.
  final CrashReporter? reporter;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _lastError;

  // The FlutterError.onError handler installed before we override it.
  void Function(FlutterErrorDetails)? _previousHandler;

  @override
  void initState() {
    super.initState();
    _installHandler();
  }

  @override
  void dispose() {
    _uninstallHandler();
    super.dispose();
  }

  void _installHandler() {
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _previousHandler?.call(details);
      _captureError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  void _uninstallHandler() {
    FlutterError.onError = _previousHandler;
    _previousHandler = null;
  }

  void _captureError(Object error, StackTrace stack) {
    widget.onError?.call(error, stack);
    widget.reporter?.recordError(error, stack);
    // Defer setState so it doesn't fire synchronously inside a build.
    Future.microtask(() {
      if (mounted && !_hasError) {
        setState(() {
          _hasError = true;
          _lastError = error;
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _hasError = false;
      _lastError = null;
    });
    // Re-install our handler after reset so we catch future errors again.
    _installHandler();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      _uninstallHandler();
      return widget.fallback ??
          _DefaultErrorWidget(error: _lastError!, onRetry: _reset);
    }
    return widget.child;
  }
}

/// Default fallback UI shown when no custom [ErrorBoundary.fallback] is given.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
