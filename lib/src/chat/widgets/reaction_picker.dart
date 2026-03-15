import 'package:flutter/material.dart';

/// Default reaction emoji constants.
abstract final class ChatReactions {
  static const String thumbsUp = '\u{1F44D}';
  static const String heart = '\u{2764}\u{FE0F}';
  static const String laugh = '\u{1F602}';
  static const String surprised = '\u{1F62E}';
  static const String sad = '\u{1F622}';
  static const String checkMark = '\u{2705}';

  static const List<String> all = [
    thumbsUp,
    heart,
    laugh,
    surprised,
    sad,
    checkMark,
  ];
}

/// Floating reaction picker shown on long-press of a message.
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({
    required this.onReactionSelected,
    this.existingReaction,
    super.key,
  });

  final ValueChanged<String> onReactionSelected;
  final String? existingReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChatReactions.all.map((emoji) {
          final isSelected = emoji == existingReaction;
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
