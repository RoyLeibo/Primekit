import 'package:flutter/material.dart';

import 'membership_tier.dart';

/// The display size of a [MemberBadge].
enum MemberBadgeSize {
  /// Compact badge — suitable for list items and avatars.
  small,

  /// Standard badge — suitable for profile pages and cards.
  medium,

  /// Large badge — suitable for prominent tier-display areas.
  large,
}

/// A visual chip/tag that displays a user's [MembershipTier].
///
/// The badge renders the tier's [MembershipTier.badgeLabel] and uses the tier's
/// [MembershipTier.badgeColor] as its background. Nothing is rendered for tiers
/// with no [MembershipTier.badgeLabel].
///
/// ```dart
/// MemberBadge(
///   tier: MembershipTier.pro,
///   size: MemberBadgeSize.medium,
///   showIcon: true,
/// )
/// ```
class MemberBadge extends StatelessWidget {
  /// Creates a [MemberBadge] for [tier].
  const MemberBadge({
    required this.tier,
    super.key,
    this.size = MemberBadgeSize.medium,
    this.showIcon = true,
  });

  /// The membership tier to display.
  final MembershipTier tier;

  /// Controls the visual size of the badge.
  final MemberBadgeSize size;

  /// Whether to show a star icon alongside the tier label.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final label = tier.badgeLabel;

    // Nothing to render if the tier has no badge label.
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    final backgroundColor =
        tier.badgeColor ?? const Color(0xFF9E9E9E); // default: grey

    final textColor = _contrastColor(backgroundColor);
    final metrics = _sizeMetrics(size);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(metrics.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.star_rounded, color: textColor, size: metrics.iconSize),
            SizedBox(width: metrics.iconSpacing),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: metrics.fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns a high-contrast foreground color for [background].
  static Color _contrastColor(Color background) {
    // Using relative luminance per WCAG 2.1.
    final luminance = background.computeLuminance();
    return luminance > 0.35 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  static _BadgeSizeMetrics _sizeMetrics(MemberBadgeSize size) => switch (size) {
    MemberBadgeSize.small => const _BadgeSizeMetrics(
      horizontalPadding: 6,
      verticalPadding: 2,
      borderRadius: 4,
      fontSize: 9,
      iconSize: 9,
      iconSpacing: 2,
    ),
    MemberBadgeSize.medium => const _BadgeSizeMetrics(
      horizontalPadding: 8,
      verticalPadding: 3,
      borderRadius: 6,
      fontSize: 11,
      iconSize: 11,
      iconSpacing: 3,
    ),
    MemberBadgeSize.large => const _BadgeSizeMetrics(
      horizontalPadding: 12,
      verticalPadding: 5,
      borderRadius: 8,
      fontSize: 14,
      iconSize: 14,
      iconSpacing: 4,
    ),
  };
}

/// Holds the visual dimensions for a given [MemberBadgeSize].
final class _BadgeSizeMetrics {
  const _BadgeSizeMetrics({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
}
