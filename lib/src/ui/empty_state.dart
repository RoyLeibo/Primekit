import 'package:flutter/material.dart';

/// A configurable empty-state widget for screens with no content.
///
/// Renders an icon (or custom illustration), an optional title, a message,
/// and an optional action button in a vertically centred layout.
///
/// ```dart
/// EmptyState(
///   message: 'You\'re all caught up.',
///   title: 'No messages',
///   icon: Icons.inbox_outlined,
/// )
///
/// // Pre-built variants
/// EmptyState.noResults(onClear: clearFilters)
/// EmptyState.noConnection(onRetry: reload)
/// EmptyState.error(onRetry: reload)
/// EmptyState.noData(onCreate: openForm)
/// ```
class EmptyState extends StatelessWidget {
  /// Creates a fully customisable empty-state widget.
  const EmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  // ---------------------------------------------------------------------------
  // Pre-built factories (must appear before non-constructor members per lint)
  // ---------------------------------------------------------------------------

  /// Shows an empty state for empty search or filter results.
  factory EmptyState.noResults({Key? key, VoidCallback? onClear}) =>
      EmptyState(
        key: key,
        message: 'Try adjusting your search or filters.',
        icon: Icons.search_off_rounded,
        title: 'No results found',
        actionLabel: onClear != null ? 'Clear filters' : null,
        onAction: onClear,
      );

  /// Shows an empty state for when the device is offline.
  factory EmptyState.noConnection({Key? key, VoidCallback? onRetry}) =>
      EmptyState(
        key: key,
        message: 'Check your internet connection and try again.',
        icon: Icons.wifi_off_rounded,
        title: 'No connection',
        actionLabel: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );

  /// Shows an empty state for unexpected errors.
  factory EmptyState.error({
    Key? key,
    VoidCallback? onRetry,
    String? message,
  }) =>
      EmptyState(
        key: key,
        message: message ?? 'An unexpected error occurred. Please try again.',
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        actionLabel: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );

  /// Shows an empty state for screens with no data yet.
  factory EmptyState.noData({
    Key? key,
    String? message,
    VoidCallback? onCreate,
  }) =>
      EmptyState(
        key: key,
        message: message ?? 'Get started by adding your first item.',
        icon: Icons.inbox_outlined,
        title: 'Nothing here yet',
        actionLabel: onCreate != null ? 'Create' : null,
        onAction: onCreate,
      );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// The main descriptive message shown to the user.
  final String message;

  /// Optional bold title displayed above [message].
  final String? title;

  /// Icon displayed when [illustration] is not provided.
  final IconData? icon;

  /// A custom illustration widget. Takes precedence over [icon].
  final Widget? illustration;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVisual(colorScheme),
            const SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(ColorScheme colorScheme) {
    if (illustration != null) return illustration!;

    if (icon != null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: colorScheme.onSurfaceVariant),
      );
    }

    return const SizedBox.shrink();
  }
}
