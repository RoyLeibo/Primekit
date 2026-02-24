import 'package:flutter/foundation.dart';

import 'compress_format.dart';
import 'media_file.dart';

export 'compress_format.dart';

/// No-op [ImageCompressor] stub for platforms that do not support
/// `flutter_image_compress` (Web, Windows, Linux).
///
/// All methods return the original [MediaFile] unchanged with a debug warning.
abstract final class ImageCompressor {
  ImageCompressor._();

  // ---------------------------------------------------------------------------
  // compress
  // ---------------------------------------------------------------------------

  /// Returns [source] unchanged — image compression is not available on this
  /// platform.
  static Future<MediaFile> compress(
    MediaFile source, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    debugPrint(
      '[Primekit] ImageCompressor: not supported on this platform '
      '— returning original file unchanged.',
    );
    return source;
  }

  // ---------------------------------------------------------------------------
  // compressToSize
  // ---------------------------------------------------------------------------

  /// Returns [source] unchanged — image compression is not available on this
  /// platform.
  static Future<MediaFile> compressToSize(
    MediaFile source, {
    required int targetSizeKb,
    int minQuality = 40,
  }) async {
    debugPrint(
      '[Primekit] ImageCompressor: not supported on this platform '
      '— returning original file unchanged.',
    );
    return source;
  }

  // ---------------------------------------------------------------------------
  // getDimensions
  // ---------------------------------------------------------------------------

  /// Always returns `(width: 0, height: 0)` on this platform.
  static Future<({int width, int height})> getDimensions(String path) async {
    debugPrint(
      '[Primekit] ImageCompressor.getDimensions: not supported on this platform.',
    );
    return (width: 0, height: 0);
  }
}
