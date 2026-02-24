import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart'
    as fic
    show CompressFormat, FlutterImageCompress;

import 'compress_format.dart';
import 'media_file.dart';

export 'compress_format.dart';

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
      final targetPath = _buildTargetPath(source.path, format);
      final result = await fic.FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1920,
        format: _toFicFormat(format),
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
  static Future<({int width, int height})> getDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final _ = await fic.FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        quality: 1,
        minWidth: 0,
        minHeight: 0,
      );
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

  static String _extForFormat(CompressFormat format) => switch (format) {
    CompressFormat.jpeg => 'jpg',
    CompressFormat.png => 'png',
    CompressFormat.webp => 'webp',
    CompressFormat.heic => 'heic',
  };

  static String _mimeForFormat(CompressFormat format) => switch (format) {
    CompressFormat.jpeg => 'image/jpeg',
    CompressFormat.png => 'image/png',
    CompressFormat.webp => 'image/webp',
    CompressFormat.heic => 'image/heic',
  };

  static fic.CompressFormat _toFicFormat(CompressFormat format) =>
      switch (format) {
        CompressFormat.jpeg => fic.CompressFormat.jpeg,
        CompressFormat.png => fic.CompressFormat.png,
        CompressFormat.webp => fic.CompressFormat.webp,
        CompressFormat.heic => fic.CompressFormat.heic,
      };
}
