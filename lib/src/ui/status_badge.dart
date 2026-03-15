import 'package:flutter/material.dart';

import '../design_system/pk_radius.dart';
import '../design_system/pk_spacing.dart';

/// Visual variant for how the badge is rendered.
enum StatusBadgeVariant {
  /// Filled chip with text label.
  text,

  /// Filled chip with leading icon and text label.
  icon,

  /// Small colored dot only (no text).
  dot,
}

/// Configuration for a single status value.
@immutable
class StatusBadgeConfig {
  /// Display label for this status.
  final String label;

  /// Foreground (text/icon) color.
  final Color foreground;

  /// Background fill color.
  final Color background;

  /// Border color. Defaults to [foreground] at 30% opacity.
  final Color? border;

  /// Optional leading icon (used when variant is [StatusBadgeVariant.icon]).
  final IconData? icon;

  const StatusBadgeConfig({
    required this.label,
    required this.foreground,
    required this.background,
    this.border,
    this.icon,
  });
}

/// A generic multi-state status indicator.
///
/// Maps each enum value of type [T] to a [StatusBadgeConfig] for rendering.
/// Supports text, icon, and dot variants.
///
/// ```dart
/// StatusBadge<VaccineStatus>(
///   value: VaccineStatus.overdue,
///   configs: {
///     VaccineStatus.overdue: StatusBadgeConfig(
///       label: 'Overdue',
///       foreground: Colors.red,
///       background: Colors.red.withValues(alpha: 0.1),
///     ),
///     VaccineStatus.upToDate: StatusBadgeConfig(
///       label: 'Up to date',
///       foreground: Colors.green,
///       background: Colors.green.withValues(alpha: 0.1),
///     ),
///   },
/// )
/// ```
class StatusBadge<T extends Enum> extends StatelessWidget {
  /// The current status value.
  final T value;

  /// Map of every possible enum value to its badge configuration.
  final Map<T, StatusBadgeConfig> configs;

  /// Visual variant. Defaults to [StatusBadgeVariant.text].
  final StatusBadgeVariant variant;

  /// Text style for the label. Falls back to theme labelMedium.
  final TextStyle? labelStyle;

  /// Dot diameter when using [StatusBadgeVariant.dot].
  final double dotSize;

  const StatusBadge({
    super.key,
    required this.value,
    required this.configs,
    this.variant = StatusBadgeVariant.text,
    this.labelStyle,
    this.dotSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final config = configs[value];
    if (config == null) return const SizedBox.shrink();

    final borderColor =
        config.border ?? config.foreground.withValues(alpha: 0.3);

    if (variant == StatusBadgeVariant.dot) {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: config.foreground,
          shape: BoxShape.circle,
        ),
      );
    }

    final effectiveStyle = (labelStyle ??
            Theme.of(context).textTheme.labelMedium ??
            const TextStyle())
        .copyWith(color: config.foreground);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PkSpacing.md,
        vertical: PkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(PkRadius.full),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (variant == StatusBadgeVariant.icon && config.icon != null) ...[
            Icon(config.icon, size: 14, color: config.foreground),
            const SizedBox(width: PkSpacing.xs),
          ],
          Text(config.label, style: effectiveStyle),
        ],
      ),
    );
  }
}
