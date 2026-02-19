import 'package:flutter/material.dart';

/// A utility class that displays a themed Material 3 confirmation dialog.
///
/// Returns `true` when the user confirms and `false` when they cancel or
/// dismiss the dialog (e.g. by pressing the system back button).
///
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context,
///   title: 'Discard changes?',
///   message: 'Your unsaved changes will be lost.',
///   isDestructive: true,
/// );
/// if (confirmed) discardChanges();
///
/// // Pre-built delete helper
/// final deleted = await ConfirmDialog.showDelete(context, itemName: 'Photo');
/// ```
class ConfirmDialog {
  ConfirmDialog._();

  /// Shows a confirmation dialog and returns the user's choice.
  ///
  /// - [isDestructive]: when `true`, the confirm button is rendered in the
  ///   theme's error colour to signal a dangerous action.
  /// - [icon]: optional leading icon rendered at the top of the dialog.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialogWidget(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );

    return result ?? false;
  }

  /// Pre-configured delete confirmation dialog.
  ///
  /// [itemName] is embedded in the dialog message so users know exactly what
  /// they are deleting. Uses destructive button styling.
  static Future<bool> showDelete(
    BuildContext context, {
    String? itemName,
  }) {
    final target = itemName != null ? '"$itemName"' : 'this item';
    return show(
      context,
      title: 'Delete $target?',
      message:
          'This action cannot be undone. $target will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_forever_outlined,
    );
  }
}

/// The actual dialog widget rendered by [ConfirmDialog].
class _ConfirmDialogWidget extends StatelessWidget {
  const _ConfirmDialogWidget({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmColor =
        isDestructive ? colorScheme.error : colorScheme.primary;

    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              size: 32,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
            )
          : null,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        textAlign: icon != null ? TextAlign.center : TextAlign.start,
      ),
      content: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: icon != null ? TextAlign.center : TextAlign.start,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive
                  ? colorScheme.onError
                  : colorScheme.onPrimary,
            ),
          ),
        ),
      ],
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
