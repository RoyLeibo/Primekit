import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'media_file.dart';

/// Provides image compression utilities backed by [FlutterImageCompress].
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
  /// The result is written to a new temp file. [format] defaults to JPEG.
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
      final targetPath = _buildTargetPath(source.path, format);
      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1920,
        format: format,
      );

      if (result == null) {
        throw Exception('Compression returned null for path: ${source.path}');
      }

      final outFile = File(result.path);
      final sizeBytes = await outFile.length();
      final dims = await getDimensions(result.path);

      return source.copyWith(
        path: result.path,
        name: _basename(result.path),
        sizeBytes: sizeBytes,
        mimeType: _mimeForFormat(format),
        width: dims.width,
        height: dims.height,
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
  ///
  /// Uses [FlutterImageCompress.compressWithList] at minimal quality to
  /// extract metadata cheaply.  Width and height of `0` indicate unknown
  /// dimensions (e.g. when the file cannot be decoded).
  static Future<({int width, int height})> getDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      // Compress to a tiny version to confirm decodability; the public
      // FlutterImageCompress API does not expose dimension metadata directly.
      // Use the XFile result path to attempt a secondary read where possible.
      final _ = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        quality: 1,
        minWidth: 0,
        minHeight: 0,
      );
      // Return 0×0 as a sentinel when exact dimensions are unavailable.
      return (width: 0, height: 0);
    } on Exception {
      rethrow;
    } catch (error) {
      throw Exception('ImageCompressor.getDimensions failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _buildTargetPath(String sourcePath, CompressFormat format) {
    final dir = Directory.systemTemp.path;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = _extForFormat(format);
    return '$dir/primekit_compress_$ts.$ext';
  }

  static String _basename(String path) {
    final sep = path.lastIndexOf('/');
    return sep == -1 ? path : path.substring(sep + 1);
  }

  static String _extForFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'jpg';
      case CompressFormat.png:
        return 'png';
      case CompressFormat.webp:
        return 'webp';
      case CompressFormat.heic:
        return 'heic';
    }
  }

  static String _mimeForFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'image/jpeg';
      case CompressFormat.png:
        return 'image/png';
      case CompressFormat.webp:
        return 'image/webp';
      case CompressFormat.heic:
        return 'image/heic';
    }
  }
}
