import 'package:flutter/material.dart';

import '../chat_theme_data.dart';

/// Shows "User is typing..." with animated dots.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    required this.typingUserIds,
    super.key,
  });

  final List<String> typingUserIds;

  @override
  Widget build(BuildContext context) {
    if (typingUserIds.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final chatTheme = ChatThemeData.of(context);

    final names = typingUserIds.map((id) {
      return chatTheme.nameResolver?.call(id) ?? 'Someone';
    }).toList();

    final text = switch (names.length) {
      1 => '${names[0]} is typing',
      2 => '${names[0]} and ${names[1]} are typing',
      _ => '${names[0]} and ${names.length - 1} others are typing',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          const _AnimatedDots(),
        ],
      ),
    );
  }
}

/// Three dots that animate in sequence.
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2)
                .clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  '.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
