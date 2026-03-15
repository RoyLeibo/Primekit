import 'package:flutter/material.dart';

import '../chat_theme_data.dart';
import '../message.dart';

/// Shows a reply preview bar above the chat input when replying to a message.
class ReplyPreview extends StatelessWidget {
  const ReplyPreview({
    required this.message,
    this.onClose,
    super.key,
  });

  final Message message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                chatTheme.senderNameBuilder?.call(message.senderId) ??
                    Text(
                      'Reply',
                      style: chatTheme.senderNameStyle ??
                          theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                    ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact inline reply bubble shown inside a message bubble.
class InlineReplyBubble extends StatelessWidget {
  const InlineReplyBubble({
    required this.replyToContent,
    required this.replyToSenderId,
    this.isCurrentUser = false,
    super.key,
  });

  final String replyToContent;
  final String replyToSenderId;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isCurrentUser
                ? Colors.white.withValues(alpha: 0.5)
                : theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          chatTheme.senderNameBuilder?.call(replyToSenderId) ??
              Text(
                replyToSenderId,
                style: chatTheme.senderNameStyle ??
                    theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.primary,
                    ),
              ),
          const SizedBox(height: 2),
          Text(
            replyToContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCurrentUser
                  ? Colors.white.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
