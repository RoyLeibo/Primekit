import 'package:flutter/material.dart';

/// Displays reaction emoji counts below a message bubble.
class ReactionDisplay extends StatelessWidget {
  const ReactionDisplay({
    required this.reactions,
    required this.currentUserId,
    this.isCurrentUser = false,
    this.onReactionTap,
    super.key,
  });

  final Map<String, List<String>> reactions;
  final String currentUserId;
  final bool isCurrentUser;
  final ValueChanged<String>? onReactionTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isCurrentUser ? WrapAlignment.end : WrapAlignment.start,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted = users.contains(currentUserId);

          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasReacted
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: hasReacted
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${users.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
