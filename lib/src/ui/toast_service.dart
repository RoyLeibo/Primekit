import 'package:flutter/material.dart';

/// The semantic type of a toast message, controlling its color and icon.
enum ToastType {
  /// Indicates a successful operation.
  success,

  /// Indicates an error or failure.
  error,

  /// Indicates a cautionary condition.
  warning,

  /// Provides neutral information.
  info,
}

/// Where the toast appears on screen.
enum ToastPosition {
  /// Anchored near the top of the screen.
  top,

  /// Anchored near the bottom of the screen (default).
  bottom,
}

/// A service that displays typed, positioned [SnackBar] toasts.
///
/// Each toast variant carries a distinctive color and leading icon so users
/// can immediately understand the nature of the feedback.
///
/// ```dart
/// ToastService.success(context, 'Profile saved.');
/// ToastService.error(context, 'Something went wrong.');
///
/// ToastService.show(
///   context,
///   'Update available',
///   type: ToastType.info,
///   duration: const Duration(seconds: 5),
///   action: SnackBarAction(label: 'Update', onPressed: doUpdate),
/// );
/// ```
class ToastService {
  ToastService._();

  // ---------------------------------------------------------------------------
  // Convenience shorthands
  // ---------------------------------------------------------------------------

  /// Shows a success toast.
  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  /// Shows an error toast.
  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  /// Shows a warning toast.
  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning);

  /// Shows an info toast.
  static void info(BuildContext context, String message) =>
      show(context, message);

  // ---------------------------------------------------------------------------
  // Primary API
  // ---------------------------------------------------------------------------

  /// Displays a typed toast with full configuration.
  ///
  /// Clears any currently visible snack-bar before showing the new one so
  /// toasts do not queue up and confuse users.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    final style = _styleFor(type);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(style.icon, color: style.foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: style.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: style.background,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: _marginFor(position),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: style.foreground,
                onPressed: action.onPressed,
              )
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static _ToastStyle _styleFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastStyle(
          background: Color(0xFF1B5E20),
          foreground: Colors.white,
          icon: Icons.check_circle_outline_rounded,
        );
      case ToastType.error:
        return const _ToastStyle(
          background: Color(0xFFB71C1C),
          foreground: Colors.white,
          icon: Icons.error_outline_rounded,
        );
      case ToastType.warning:
        return const _ToastStyle(
          background: Color(0xFFE65100),
          foreground: Colors.white,
          icon: Icons.warning_amber_rounded,
        );
      case ToastType.info:
        return const _ToastStyle(
          background: Color(0xFF0D47A1),
          foreground: Colors.white,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  static EdgeInsets _marginFor(ToastPosition position) {
    switch (position) {
      case ToastPosition.top:
        return const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 60,
          bottom: 8,
        );
      case ToastPosition.bottom:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }
}

/// Internal styling record for a [ToastType].
class _ToastStyle {
  const _ToastStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
