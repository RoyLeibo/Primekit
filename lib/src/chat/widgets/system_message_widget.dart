import 'package:flutter/material.dart';

import '../chat_theme_data.dart';
import '../message.dart';

/// Renders a system message as a centered pill (e.g. "User joined the group").
class SystemMessageWidget extends StatelessWidget {
  const SystemMessageWidget({required this.message, super.key});

  final Message message;

  String _defaultIcon(String? systemType) {
    return switch (systemType) {
      SystemMessageTypes.memberJoined => '\u{1F44B}',
      SystemMessageTypes.memberLeft => '\u{1F6B6}',
      SystemMessageTypes.groupCreated => '\u{1F389}',
      _ => '\u{2139}\u{FE0F}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    final icon = chatTheme.systemMessageIconResolver?.call(
          message.systemType ?? '',
        ) ??
        _defaultIcon(message.systemType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: chatTheme.systemMessageBackground ??
                theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.content,
                  style: chatTheme.systemMessageStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: chatTheme.systemMessageTextColor ??
                            theme.colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
