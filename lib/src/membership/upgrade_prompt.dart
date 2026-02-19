import 'package:flutter/material.dart';

import 'member_badge.dart';
import 'membership_tier.dart';

/// Controls the visual presentation style of an [UpgradePrompt].
enum UpgradePromptStyle {
  /// A rounded card with icon, title, benefits list, and CTA button.
  card,

  /// A slim horizontal banner with a short message and CTA button.
  banner,

  /// A modal dialog with full tier details.
  dialog,

  /// A compact inline row — icon + text + small button.
  inline,
}

/// A standardised upgrade call-to-action widget that prompts the user to
/// upgrade to [targetTier].
///
/// ```dart
/// UpgradePrompt(
///   targetTier: MembershipTier.pro,
///   featureName: 'PDF Export',
///   onUpgradeTap: () => paywallController.show(featureName: 'export_pdf'),
///   style: UpgradePromptStyle.card,
/// )
/// ```
class UpgradePrompt extends StatelessWidget {
  /// Creates an [UpgradePrompt].
  const UpgradePrompt({
    required this.targetTier,
    super.key,
    this.featureName,
    this.customMessage,
    this.onUpgradeTap,
    this.style = UpgradePromptStyle.card,
  });

  /// The tier the user needs to access the gated feature.
  final MembershipTier targetTier;

  /// Optional name of the feature that triggered this prompt.
  final String? featureName;

  /// Optional custom message overriding the default copy.
  final String? customMessage;

  /// Called when the user taps the upgrade CTA.
  final VoidCallback? onUpgradeTap;

  /// Controls the visual layout of the prompt.
  final UpgradePromptStyle style;

  @override
  Widget build(BuildContext context) => switch (style) {
        UpgradePromptStyle.card => _CardPrompt(
            tier: targetTier,
            featureName: featureName,
            customMessage: customMessage,
            onUpgradeTap: onUpgradeTap,
          ),
        UpgradePromptStyle.banner => _BannerPrompt(
            tier: targetTier,
            featureName: featureName,
            customMessage: customMessage,
            onUpgradeTap: onUpgradeTap,
          ),
        UpgradePromptStyle.dialog => _DialogPrompt(
            tier: targetTier,
            featureName: featureName,
            customMessage: customMessage,
            onUpgradeTap: onUpgradeTap,
          ),
        UpgradePromptStyle.inline => _InlinePrompt(
            tier: targetTier,
            featureName: featureName,
            customMessage: customMessage,
            onUpgradeTap: onUpgradeTap,
          ),
      };
}

// ---------------------------------------------------------------------------
// Private layout variants
// ---------------------------------------------------------------------------

final class _CardPrompt extends StatelessWidget {
  const _CardPrompt({
    required this.tier,
    this.featureName,
    this.customMessage,
    this.onUpgradeTap,
  });

  final MembershipTier tier;
  final String? featureName;
  final String? customMessage;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tier.badgeColor ?? theme.colorScheme.primary;
    final message = customMessage ??
        (featureName != null
            ? '$featureName requires ${tier.name}.'
            : 'Upgrade to ${tier.name} to unlock more features.');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upgrade to ${tier.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                MemberBadge(tier: tier, size: MemberBadgeSize.small),
              ],
            ),
            const SizedBox(height: 10),
            Text(message, style: theme.textTheme.bodyMedium),
            if (tier.perks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tier.perks.map(
                (perk) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          perk,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUpgradeTap,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text('Upgrade to ${tier.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BannerPrompt extends StatelessWidget {
  const _BannerPrompt({
    required this.tier,
    this.featureName,
    this.customMessage,
    this.onUpgradeTap,
  });

  final MembershipTier tier;
  final String? featureName;
  final String? customMessage;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tier.badgeColor ?? theme.colorScheme.primary;
    final message = customMessage ??
        (featureName != null
            ? 'Unlock $featureName with ${tier.name}'
            : 'Upgrade to ${tier.name} for more');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        border: Border(top: BorderSide(color: accent, width: 2)),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgradeTap,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

final class _DialogPrompt extends StatelessWidget {
  const _DialogPrompt({
    required this.tier,
    this.featureName,
    this.customMessage,
    this.onUpgradeTap,
  });

  final MembershipTier tier;
  final String? featureName;
  final String? customMessage;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tier.badgeColor ?? theme.colorScheme.primary;
    final message = customMessage ??
        (featureName != null
            ? '$featureName is available on the ${tier.name} plan.'
            : 'Upgrade to ${tier.name} to unlock premium features.');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: accent),
          const SizedBox(width: 10),
          Text('${tier.name} Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (tier.perks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...tier.perks.map(
              (perk) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(perk, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: onUpgradeTap,
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: Text('Upgrade to ${tier.name}'),
        ),
      ],
    );
  }
}

final class _InlinePrompt extends StatelessWidget {
  const _InlinePrompt({
    required this.tier,
    this.featureName,
    this.customMessage,
    this.onUpgradeTap,
  });

  final MembershipTier tier;
  final String? featureName;
  final String? customMessage;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tier.badgeColor ?? theme.colorScheme.primary;
    final label = customMessage ??
        (featureName != null ? '$featureName — ${tier.name} only' : '${tier.name} only');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: accent),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onUpgradeTap,
          child: Text(
            'Upgrade',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
