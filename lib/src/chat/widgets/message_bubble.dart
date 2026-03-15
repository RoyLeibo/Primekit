import 'package:flutter/material.dart';

import '../chat_theme_data.dart';
import '../message.dart';
import 'reaction_display.dart';
import 'reaction_picker.dart';
import 'reply_preview.dart';

/// A single chat message bubble.
///
/// Right-aligned with gradient for the current user,
/// left-aligned with surface color for others.
/// Sender name resolved via [ChatThemeData.senderNameBuilder].
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.currentUserId,
    this.showSender = false,
    this.onReaction,
    this.onSwipeReply,
    super.key,
  });

  final Message message;
  final bool isCurrentUser;
  final bool showSender;
  final String currentUserId;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onSwipeReply;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }

  String? _currentUserReaction() {
    for (final entry in message.reactions.entries) {
      if (entry.value.contains(currentUserId)) return entry.key;
    }
    return null;
  }

  void _showReactionPicker(BuildContext context, Offset tapPosition) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        const pickerWidth = 280.0;
        final left = (tapPosition.dx - pickerWidth / 2)
            .clamp(8.0, screenWidth - pickerWidth - 8.0);
        final top = tapPosition.dy - 60;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => entry.remove(),
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: ReactionPicker(
                  existingReaction: _currentUserReaction(),
                  onReactionSelected: (emoji) {
                    entry.remove();
                    onReaction?.call(emoji);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);
    final timeText = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _SwipeToReply(
        isCurrentUser: isCurrentUser,
        onSwipe: onSwipeReply,
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser && showSender)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: chatTheme.senderNameBuilder?.call(message.senderId) ??
                    Text(
                      message.senderId,
                      style: chatTheme.senderNameStyle ??
                          theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
              ),
            GestureDetector(
              onLongPressStart: onReaction != null
                  ? (details) =>
                      _showReactionPicker(context, details.globalPosition)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? chatTheme.sentBubbleGradient
                      : null,
                  color: isCurrentUser
                      ? (chatTheme.sentBubbleColor ??
                          theme.colorScheme.primary)
                      : (chatTheme.receivedBubbleColor ?? theme.cardColor),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCurrentUser ? 18 : 6),
                    bottomRight: Radius.circular(isCurrentUser ? 6 : 18),
                  ),
                  boxShadow: isCurrentUser
                      ? null
                      : chatTheme.receivedBubbleShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isReply &&
                        message.replyToContent != null &&
                        message.replyToSenderId != null)
                      InlineReplyBubble(
                        replyToContent: message.replyToContent!,
                        replyToSenderId: message.replyToSenderId!,
                        isCurrentUser: isCurrentUser,
                      ),
                    Text(
                      message.content,
                      style: (chatTheme.messageTextStyle ??
                              theme.textTheme.bodyMedium)
                          ?.copyWith(
                        color: isCurrentUser
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.hasReactions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ReactionDisplay(
                  reactions: message.reactions,
                  currentUserId: currentUserId,
                  isCurrentUser: isCurrentUser,
                  onReactionTap: (emoji) => onReaction?.call(emoji),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                timeText,
                style: chatTheme.timestampStyle ??
                    theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipe-to-reply gesture wrapper.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.child,
    required this.isCurrentUser,
    this.onSwipe,
  });

  final Widget child;
  final bool isCurrentUser;
  final VoidCallback? onSwipe;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dragOffset = 0;
  static const _triggerThreshold = 60.0;
  bool _triggered = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onSwipe == null) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, 80.0);
      if (_dragOffset >= _triggerThreshold && !_triggered) {
        _triggered = true;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_triggered) widget.onSwipe?.call();
    _triggered = false;
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: widget.isCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        children: [
          if (_dragOffset > 0)
            Positioned(
              left: widget.isCurrentUser ? null : 0,
              right: widget.isCurrentUser ? 0 : null,
              child: Opacity(
                opacity: (_dragOffset / _triggerThreshold).clamp(0.0, 1.0),
                child: Icon(
                  Icons.reply_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          AnimatedContainer(
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
