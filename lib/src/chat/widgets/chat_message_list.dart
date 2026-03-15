import 'package:flutter/material.dart';

import '../chat_theme_data.dart';
import '../message.dart';
import 'message_bubble.dart';
import 'system_message_widget.dart';

/// A composable, reversed message list with date separators and sender grouping.
///
/// Displays messages newest-at-bottom. Supports custom rendering for
/// app-specific system messages via [systemMessageBuilder].
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    required this.messages,
    required this.currentUserId,
    this.onReaction,
    this.onSwipeReply,
    this.systemMessageBuilder,
    this.emptyState,
    super.key,
  });

  final List<Message> messages;
  final String currentUserId;
  final void Function(String messageId, String emoji)? onReaction;
  final void Function(Message message)? onSwipeReply;

  /// Override rendering for specific system message types.
  /// Return null to use the default [SystemMessageWidget].
  final Widget? Function(Message message)? systemMessageBuilder;

  /// Widget shown when the message list is empty.
  final Widget? emptyState;

  bool _shouldShowSender(int index) {
    if (index >= messages.length - 1) return true;
    if (_shouldShowDateSeparator(index)) return true;
    return messages[index].senderId != messages[index + 1].senderId;
  }

  bool _shouldShowDateSeparator(int index) {
    if (index >= messages.length - 1) return true;
    final current = messages[index].createdAt;
    final next = messages[index + 1].createdAt;
    return current.year != next.year ||
        current.month != next.month ||
        current.day != next.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return emptyState ?? const ChatEmptyState();
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDate = _shouldShowDateSeparator(index);

        Widget messageWidget;

        if (message.isSystem) {
          messageWidget =
              systemMessageBuilder?.call(message) ??
              SystemMessageWidget(message: message);
        } else {
          final isCurrentUser = message.senderId == currentUserId;
          messageWidget = Align(
            alignment: isCurrentUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              showSender: !isCurrentUser && _shouldShowSender(index),
              currentUserId: currentUserId,
              onReaction: onReaction != null
                  ? (emoji) => onReaction!(message.id, emoji)
                  : null,
              onSwipeReply: onSwipeReply != null
                  ? () => onSwipeReply!(message)
                  : null,
            ),
          );
        }

        if (showDate) {
          return Column(
            children: [
              DateSeparator(label: _formatDateSeparator(message.createdAt)),
              messageWidget,
            ],
          );
        }

        return messageWidget;
      },
    );
  }
}

/// A centered date label between message groups.
class DateSeparator extends StatelessWidget {
  const DateSeparator({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          label,
          style: chatTheme.dateSeparatorStyle ??
              theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

/// Default empty state for [ChatMessageList].
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    this.title = 'Start the conversation!',
    this.subtitle = 'Send a message to your group',
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
