import 'package:flutter/material.dart';

/// Theming configuration for PrimeKit chat widgets.
///
/// Wrap your chat UI in a [ChatTheme] widget to customize appearance.
/// All properties are optional — widgets fall back to [Theme.of(context)].
///
/// ```dart
/// ChatTheme(
///   data: ChatThemeData(
///     sentBubbleGradient: myGradient,
///     senderNameBuilder: (userId) => UserAvatar(userId: userId),
///   ),
///   child: ChatMessageList(...),
/// )
/// ```
@immutable
class ChatThemeData {
  const ChatThemeData({
    this.sentBubbleGradient,
    this.sentBubbleColor,
    this.receivedBubbleColor,
    this.receivedBubbleShadow,
    this.messageTextStyle,
    this.senderNameStyle,
    this.timestampStyle,
    this.systemMessageStyle,
    this.systemMessageBackground,
    this.systemMessageTextColor,
    this.dateSeparatorStyle,
    this.sendButtonGradient,
    this.sendButtonColor,
    this.inputBorderColor,
    this.inputFocusedBorderColor,
    this.senderNameBuilder,
    this.nameResolver,
    this.systemMessageIconResolver,
  });

  /// Gradient for the current user's message bubble.
  final LinearGradient? sentBubbleGradient;

  /// Solid color fallback for sent bubble if no gradient.
  final Color? sentBubbleColor;

  /// Background color for received message bubbles.
  final Color? receivedBubbleColor;

  /// Shadow for received message bubbles.
  final List<BoxShadow>? receivedBubbleShadow;

  /// Text style for message content.
  final TextStyle? messageTextStyle;

  /// Text style for sender name labels.
  final TextStyle? senderNameStyle;

  /// Text style for timestamps.
  final TextStyle? timestampStyle;

  /// Text style for system message pills.
  final TextStyle? systemMessageStyle;

  /// Background color for system message pills.
  final Color? systemMessageBackground;

  /// Text color for system messages.
  final Color? systemMessageTextColor;

  /// Text style for date separator labels.
  final TextStyle? dateSeparatorStyle;

  /// Gradient for the send button circle.
  final LinearGradient? sendButtonGradient;

  /// Solid color fallback for send button if no gradient.
  final Color? sendButtonColor;

  /// Border color for the chat input field.
  final Color? inputBorderColor;

  /// Focused border color for the chat input field.
  final Color? inputFocusedBorderColor;

  /// Builds a widget to display the sender name for a user ID.
  /// Used by [MessageBubble] and [ReplyPreview].
  final Widget Function(String userId)? senderNameBuilder;

  /// Resolves a user ID to a display name string.
  /// Used by [TypingIndicator] for text-based display.
  final String Function(String userId)? nameResolver;

  /// Maps a system message type string to an icon/emoji string.
  final String Function(String systemType)? systemMessageIconResolver;

  /// Looks up [ChatThemeData] from the widget tree, or returns null.
  static ChatThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatTheme>()?.data;
  }

  /// Looks up [ChatThemeData] from the widget tree.
  /// Returns an empty [ChatThemeData] if none is found.
  static ChatThemeData of(BuildContext context) {
    return maybeOf(context) ?? const ChatThemeData();
  }
}

/// InheritedWidget that provides [ChatThemeData] to descendant chat widgets.
class ChatTheme extends InheritedWidget {
  const ChatTheme({
    required this.data,
    required super.child,
    super.key,
  });

  final ChatThemeData data;

  @override
  bool updateShouldNotify(ChatTheme oldWidget) => data != oldWidget.data;
}
