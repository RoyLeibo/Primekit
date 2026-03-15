import 'package:flutter/material.dart';

import '../chat_theme_data.dart';
import '../message.dart';
import 'reply_preview.dart';

/// Bottom input bar for composing and sending chat messages.
class ChatInput extends StatefulWidget {
  const ChatInput({
    required this.onSend,
    this.enabled = true,
    this.replyingTo,
    this.onCancelReply,
    this.onTyping,
    super.key,
  });

  final ValueChanged<String> onSend;
  final bool enabled;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onTyping;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    if (hasText) {
      widget.onTyping?.call();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingTo != null)
          ReplyPreview(
            message: widget.replyingTo!,
            onClose: () => widget.onCancelReply?.call(),
          ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 10,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: widget.replyingTo != null
                ? null
                : Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  maxLines: 4,
                  minLines: 1,
                  style: chatTheme.messageTextStyle ??
                      theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.replyingTo != null
                        ? 'Reply...'
                        : 'Type a message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: chatTheme.inputBorderColor ??
                            theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: chatTheme.inputBorderColor ??
                            theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: chatTheme.inputFocusedBorderColor ??
                            theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _hasText ? _handleSend : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: chatTheme.sendButtonGradient,
                    color: chatTheme.sendButtonColor ??
                        theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
