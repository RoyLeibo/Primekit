import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'compress_format.dart';
import 'media_file.dart';

export 'compress_format.dart';

/// Web implementation of [ImageCompressor] using the HTML Canvas API.
///
/// Reads image bytes from the [MediaFile.path] (a blob URL on web),
/// draws them on a canvas, and exports a compressed JPEG or PNG blob.
abstract final class ImageCompressor {
  ImageCompressor._();

  // ---------------------------------------------------------------------------
  // compress
  // ---------------------------------------------------------------------------

  /// Compresses [source] to [quality] (0–100) and optional max dimensions.
  ///
  /// Returns a new [MediaFile] with updated [MediaFile.sizeBytes].
  /// [format] defaults to [CompressFormat.jpeg].
  static Future<MediaFile> compress(
    MediaFile source, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      final bytes = await _readBytes(source.path);
      final compressed = await _compressBytes(
        bytes,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
      );
      return source.copyWith(
        sizeBytes: compressed.length,
        mimeType: _mimeForFormat(format),
      );
    } catch (e) {
      debugPrint('[Primekit] ImageCompressor (web): compress failed: $e');
      return source;
    }
  }

  // ---------------------------------------------------------------------------
  // compressToSize
  // ---------------------------------------------------------------------------

  /// Iteratively reduces quality until the file is at most [targetSizeKb] KB.
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
      } catch (e) {
        debugPrint(
          '[Primekit] ImageCompressor (web): '
          'compressToSize failed at quality=$quality: $e',
        );
        break;
      }
    }

    return best;
  }

  // ---------------------------------------------------------------------------
  // getDimensions
  // ---------------------------------------------------------------------------

  /// Returns `(width: 0, height: 0)` — exact dimensions require full decode.
  static Future<({int width, int height})> getDimensions(String path) async =>
      (width: 0, height: 0);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<Uint8List> _compressBytes(
    Uint8List bytes, {
    required int quality,
    int? maxWidth,
    int? maxHeight,
    required CompressFormat format,
  }) async {
    // Create a blob URL from the input bytes.
    final jsBytes = bytes.toJS;
    final blob = web.Blob([jsBytes].toJS);
    final blobUrl = web.URL.createObjectURL(blob);

    try {
      // Load into an image element.
      final img = web.HTMLImageElement();
      img.src = blobUrl;

      final loadCompleter = Completer<void>();
      // HTMLImageElement uses setter-style event handlers (not Dart streams).
      img.onload = (web.Event _) {
        loadCompleter.complete();
      }.toJS;
      img.onerror = (web.Event _) {
        loadCompleter.completeError(
          Exception('Failed to load image for compression'),
        );
      }.toJS;
      await loadCompleter.future;

      final srcW = img.naturalWidth;
      final srcH = img.naturalHeight;
      var dstW = srcW;
      var dstH = srcH;

      if (maxWidth != null && srcW > maxWidth) {
        dstW = maxWidth;
        dstH = (srcH * maxWidth / srcW).round();
      }
      if (maxHeight != null && dstH > maxHeight) {
        final scale = maxHeight / dstH;
        dstW = (dstW * scale).round();
        dstH = maxHeight;
      }

      final canvas = web.HTMLCanvasElement()
        ..width = dstW
        ..height = dstH;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(img, 0, 0);

      // Convert to blob with specified quality.
      final completer = Completer<Uint8List>();
      final mimeType = _mimeForFormat(format);
      final qualityJs = (quality / 100.0).toJS;

      canvas.toBlob(
        (web.Blob? resultBlob) {
          if (resultBlob == null) {
            completer.completeError(Exception('canvas.toBlob returned null'));
            return;
          }
          final reader = web.FileReader();
          // FileReader uses setter-style event handlers (not Dart streams).
          reader.onload = (web.Event _) {
            final arrayBuffer = reader.result as JSArrayBuffer;
            completer.complete(arrayBuffer.toDart.asUint8List());
          }.toJS;
          reader.onerror = (web.Event _) {
            completer.completeError(Exception('FileReader failed'));
          }.toJS;
          reader.readAsArrayBuffer(resultBlob);
        }.toJS,
        mimeType,
        qualityJs,
      );

      return completer.future;
    } finally {
      web.URL.revokeObjectURL(blobUrl);
    }
  }

  static Future<Uint8List> _readBytes(String path) async {
    try {
      // On web, path is typically a blob URL.
      final response = await web.window.fetch(path.toJS).toDart;
      final buffer = await response.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    } catch (e) {
      throw Exception(
        'ImageCompressor (web): failed to read bytes from $path: $e',
      );
    }
  }

  static String _mimeForFormat(CompressFormat format) => switch (format) {
    CompressFormat.jpeg => 'image/jpeg',
    CompressFormat.png => 'image/png',
    CompressFormat.webp => 'image/webp',
    CompressFormat.heic =>
      'image/jpeg', // HEIC not supported in canvas — fallback to JPEG
  };
}
