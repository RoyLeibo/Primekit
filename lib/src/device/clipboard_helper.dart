import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/logger.dart';

/// Static helpers for reading and writing the system clipboard.
///
/// ```dart
/// // Copy with a SnackBar confirmation
/// await ClipboardHelper.copyWithFeedback(context, 'https://example.com');
///
/// // Silent copy
/// await ClipboardHelper.copy('secret-token');
///
/// // Paste
/// final text = await ClipboardHelper.paste();
/// ```
abstract final class ClipboardHelper {
  static const String _tag = 'ClipboardHelper';

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Writes [text] to the clipboard silently.
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    PrimekitLogger.verbose('Copied to clipboard.', tag: _tag);
  }

  /// Writes [text] to the clipboard and shows a [SnackBar] in [context].
  ///
  /// [message] customises the SnackBar text. Defaults to `'Copied!'`.
  /// The SnackBar is not shown when [context] is no longer mounted.
  static Future<void> copyWithFeedback(
    BuildContext context,
    String text, {
    String? message,
  }) async {
    await copy(text);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Copied!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the current clipboard text, or `null` if the clipboard is empty
  /// or contains non-text data.
  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    PrimekitLogger.verbose(
      'Paste: ${text != null ? "${text.length} chars" : "empty"}',
      tag: _tag,
    );
    return text;
  }

  /// Returns `true` if the clipboard currently contains plain-text content.
  static Future<bool> hasContent() async {
    final hasStrings = await Clipboard.hasStrings();
    return hasStrings;
  }
}
