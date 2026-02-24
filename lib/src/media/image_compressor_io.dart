import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'compress_format.dart';
import 'media_file.dart';

export 'compress_format.dart';

/// Provides image compression utilities backed by the pure-Dart [image] package.
///
/// Supports Android, iOS, macOS, Windows, Linux, and Web via a single
/// pure-Dart implementation — no platform channels required.
///
/// All methods return new [MediaFile] instances — the source is never mutated.
///
/// ```dart
/// final compressed = await ImageCompressor.compress(
///   original,
///   quality: 80,
///   maxWidth: 1280,
/// );
/// ```
abstract final class ImageCompressor {
  ImageCompressor._();

  // ---------------------------------------------------------------------------
  // compress
  // ---------------------------------------------------------------------------

  /// Compresses [source] to [quality] (0–100) and optional max dimensions.
  ///
  /// The result is written to a new temp file. [format] defaults to
  /// [CompressFormat.jpeg].
  ///
  /// Throws an [Exception] if compression fails.
  static Future<MediaFile> compress(
    MediaFile source, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      final bytes = await File(source.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Could not decode image at ${source.path}');
      }

      // Resize if requested (only downscale, never upscale).
      final processed = _maybeResize(
        decoded,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final encoded = _encode(processed, format, quality);
      final targetPath = _buildTargetPath(format);
      await File(targetPath).writeAsBytes(encoded);

      return source.copyWith(
        path: targetPath,
        name: _basename(targetPath),
        sizeBytes: encoded.length,
        mimeType: _mimeForFormat(format),
        width: processed.width,
        height: processed.height,
      );
    } on Exception {
      rethrow;
    } catch (error) {
      throw Exception('ImageCompressor.compress failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // compressToSize
  // ---------------------------------------------------------------------------

  /// Iteratively reduces quality until the file is at most [targetSizeKb] KB.
  ///
  /// Quality will not drop below [minQuality]. If the target cannot be reached,
  /// the smallest achievable result is returned.
  static Future<MediaFile> compressToSize(
    MediaFile source, {
    required int targetSizeKb,
    int minQuality = 40,
  }) async {
    final targetBytes = targetSizeKb * 1024;
    var quality = 85;
    var best = source;

    while (quality >= minQuality) {
      try {
        final candidate = await compress(source, quality: quality);
        best = candidate;
        if ((candidate.sizeBytes ?? 0) <= targetBytes) return candidate;
        quality -= 10;
      } on Exception {
        rethrow;
      } catch (error) {
        throw Exception(
          'ImageCompressor.compressToSize failed at quality=$quality: $error',
        );
      }
    }

    return best;
  }

  // ---------------------------------------------------------------------------
  // getDimensions
  // ---------------------------------------------------------------------------

  /// Returns the pixel dimensions of the image at [path].
  static Future<({int width, int height})> getDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return (width: 0, height: 0);
      return (width: decoded.width, height: decoded.height);
    } on Exception {
      rethrow;
    } catch (error) {
      throw Exception('ImageCompressor.getDimensions failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static img.Image _maybeResize(
    img.Image source, {
    int? maxWidth,
    int? maxHeight,
  }) {
    if (maxWidth == null && maxHeight == null) return source;

    final srcW = source.width;
    final srcH = source.height;
    final needsResize =
        (maxWidth != null && srcW > maxWidth) ||
        (maxHeight != null && srcH > maxHeight);
    if (!needsResize) return source;

    // img.copyResize maintains aspect ratio when only one dimension is given.
    return img.copyResize(source, width: maxWidth, height: maxHeight);
  }

  static Uint8List _encode(
    img.Image image,
    CompressFormat format,
    int quality,
  ) => switch (format) {
    CompressFormat.jpeg => Uint8List.fromList(
      img.encodeJpg(image, quality: quality),
    ),
    CompressFormat.png => Uint8List.fromList(img.encodePng(image)),
    // WebP encoding is not supported by the image package (read-only);
    // falls back to JPEG.
    CompressFormat.webp => Uint8List.fromList(
      img.encodeJpg(image, quality: quality),
    ),
    // HEIC not supported by the image package — fall back to JPEG.
    CompressFormat.heic => Uint8List.fromList(
      img.encodeJpg(image, quality: quality),
    ),
  };

  static String _buildTargetPath(CompressFormat format) {
    final dir = Directory.systemTemp.path;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = _extForFormat(format);
    return '$dir/primekit_compress_$ts.$ext';
  }

  static String _basename(String path) {
    final sep = path.lastIndexOf('/');
    return sep == -1 ? path : path.substring(sep + 1);
  }

  static String _extForFormat(CompressFormat format) => switch (format) {
    CompressFormat.jpeg => 'jpg',
    CompressFormat.png => 'png',
    CompressFormat.webp => 'jpg', // WebP encode not supported; output as JPG.
    CompressFormat.heic => 'jpg',
  };

  static String _mimeForFormat(CompressFormat format) => switch (format) {
    CompressFormat.jpeg => 'image/jpeg',
    CompressFormat.png => 'image/png',
    CompressFormat.webp => 'image/webp',
    CompressFormat.heic => 'image/jpeg',
  };
}
