import 'dart:io';

import 'package:flutter/services.dart';

/// Provides system share sheet integration and deep-link construction.
///
/// Uses Flutter's built-in [SystemChannels] mechanism — no extra package
/// needed for basic text / URL sharing. File sharing uses the platform
/// share sheet via [MethodChannel].
///
/// ```dart
/// await ShareService.shareText(text: 'Check out this article!');
/// await ShareService.shareUrl(url: Uri.parse('https://example.com'));
///
/// final link = ShareService.buildShareLink(
///   scheme: 'https',
///   host: 'app.example.com',
///   path: '/posts/42',
/// );
/// ```
abstract final class ShareService {
  ShareService._();

  static const MethodChannel _channel = MethodChannel(
    'dev.fluttercommunity.plus/share',
  );

  // ---------------------------------------------------------------------------
  // shareText
  // ---------------------------------------------------------------------------

  /// Opens the system share sheet to share [text].
  ///
  /// [subject] — optional subject line (used by email clients).
  /// [sharePositionOrigin] — anchor rect for the iPad share popover.
  static Future<void> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      await _channel.invokeMethod<void>('share', <String, dynamic>{
        'text': text,
        if (subject != null) 'subject': subject,
        if (sharePositionOrigin != null) 'originX': sharePositionOrigin.left,
        if (sharePositionOrigin != null) 'originY': sharePositionOrigin.top,
        if (sharePositionOrigin != null)
          'originWidth': sharePositionOrigin.width,
        if (sharePositionOrigin != null)
          'originHeight': sharePositionOrigin.height,
      });
    } on PlatformException catch (e) {
      throw Exception('ShareService.shareText failed: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // shareUrl
  // ---------------------------------------------------------------------------

  /// Opens the system share sheet to share [url].
  ///
  /// [text] — optional body text accompanying the URL.
  /// [subject] — optional subject line.
  static Future<void> shareUrl({
    required Uri url,
    String? text,
    String? subject,
  }) => shareText(
    text: text != null ? '$text\n$url' : url.toString(),
    subject: subject,
  );

  // ---------------------------------------------------------------------------
  // shareFile
  // ---------------------------------------------------------------------------

  /// Opens the system share sheet to share the file at [filePath].
  ///
  /// [text] — optional caption.
  /// [mimeType] — MIME type hint (e.g. `'image/jpeg'`).
  static Future<void> shareFile({
    required String filePath,
    String? text,
    String? mimeType,
  }) async {
    if (!File(filePath).existsSync()) {
      throw ArgumentError('File not found: $filePath');
    }
    try {
      await _channel.invokeMethod<void>('shareFiles', <String, dynamic>{
        'paths': [filePath],
        if (text != null) 'text': text,
        if (mimeType != null) 'mimeTypes': [mimeType],
      });
    } on PlatformException catch (e) {
      throw Exception('ShareService.shareFile failed: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // buildShareLink
  // ---------------------------------------------------------------------------

  /// Builds a [Uri] suitable for sharing a specific piece of content.
  ///
  /// ```dart
  /// final link = ShareService.buildShareLink(
  ///   scheme: 'https',
  ///   host: 'app.example.com',
  ///   path: '/posts/42',
  ///   queryParameters: {'ref': 'share'},
  /// );
  /// // https://app.example.com/posts/42?ref=share
  /// ```
  static Uri buildShareLink({
    required String scheme,
    required String host,
    required String path,
    Map<String, String>? queryParameters,
  }) => Uri(
    scheme: scheme,
    host: host,
    path: path,
    queryParameters: queryParameters?.isNotEmpty ?? false
        ? queryParameters
        : null,
  );
}
