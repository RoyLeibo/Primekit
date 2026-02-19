import 'dart:async';

import 'package:flutter/material.dart';

/// A global loading overlay manager that renders a semi-transparent backdrop
/// with a [CircularProgressIndicator] and optional message, blocking all
/// user interaction while an async operation is in progress.
///
/// Usage:
/// ```dart
/// // Show and hide manually
/// LoadingOverlay.show(context, message: 'Saving...');
/// await doWork();
/// LoadingOverlay.hide(context);
///
/// // Or use wrap to handle show/hide automatically
/// final result = await LoadingOverlay.wrap(
///   context,
///   fetchData(),
///   message: 'Loading...',
/// );
/// ```
class LoadingOverlay {
  LoadingOverlay._();

  static OverlayEntry? _currentEntry;

  /// Shows the loading overlay anchored to the nearest [Overlay].
  ///
  /// If an overlay is already visible, this call is a no-op — only one
  /// overlay is shown at a time to prevent stacking.
  static void show(BuildContext context, {String? message}) {
    if (_currentEntry != null) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => PkLoadingOverlayWidget(message: message),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Removes the currently visible loading overlay.
  ///
  /// Safe to call even when no overlay is showing.
  static void hide(BuildContext context) {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Shows the overlay, awaits [future], then hides the overlay.
  ///
  /// The overlay is always hidden — even if [future] throws — to avoid
  /// leaving the UI in a locked state.
  ///
  /// ```dart
  /// final user = await LoadingOverlay.wrap(
  ///   context,
  ///   fetchUser(),
  ///   message: 'Loading profile...',
  /// );
  /// ```
  static Future<T> wrap<T>(
    BuildContext context,
    Future<T> future, {
    String? message,
  }) async {
    show(context, message: message);
    try {
      return await future;
    } finally {
      hide(context);
    }
  }
}

/// The visual widget rendered by [LoadingOverlay].
///
/// Fills the entire screen with a semi-transparent barrier that absorbs all
/// pointer events, then centers a [CircularProgressIndicator] with an
/// optional [message] label beneath it.
class PkLoadingOverlayWidget extends StatelessWidget {
  /// Creates a loading overlay widget.
  const PkLoadingOverlayWidget({super.key, this.message});

  /// Optional label displayed below the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 3,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
