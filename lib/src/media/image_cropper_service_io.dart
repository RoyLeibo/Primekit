import 'dart:io';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';

import 'media_file.dart';

/// Wraps [croppy] with a clean immutable-result API for native platforms.
///
/// The crop UI is presented on top of the current navigation stack.
/// Returns `null` if the user cancels the crop.
///
/// ```dart
/// final cropped = await ImageCropperService.crop(
///   context,
///   source,
///   aspectRatio: (x: 16, y: 9),
/// );
/// ```
abstract final class ImageCropperService {
  ImageCropperService._();

  // ---------------------------------------------------------------------------
  // crop
  // ---------------------------------------------------------------------------

  /// Opens the crop UI for [source].
  ///
  /// Returns a new [MediaFile] pointing to the cropped result, or `null` when
  /// the user cancels.
  ///
  /// [aspectRatio] — forced ratio expressed as `(x: 16, y: 9)`.
  /// When `null` the user can freely choose any ratio.
  static Future<MediaFile?> crop(
    BuildContext context,
    MediaFile source, {
    ({int x, int y})? aspectRatio,
    String? toolbarTitle,
    Color? toolbarColor,
  }) async {
    try {
      final result = await showMaterialImageCropper(
        context,
        imageProvider: FileImage(File(source.path)),
        allowedAspectRatios: aspectRatio != null
            ? [CropAspectRatio(width: aspectRatio.x, height: aspectRatio.y)]
            : null,
        themeData: toolbarColor != null
            ? ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: toolbarColor),
              )
            : null,
      );

      if (result == null) return null;

      final byteData = await result.uiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();

      final targetPath = _buildTargetPath();
      await File(targetPath).writeAsBytes(bytes);

      return source.copyWith(
        path: targetPath,
        name: _basename(targetPath),
        sizeBytes: bytes.length,
        mimeType: 'image/png',
        width: result.uiImage.width,
        height: result.uiImage.height,
      );
    } on Exception {
      rethrow;
    } catch (error) {
      throw Exception('ImageCropperService.crop failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // cropSquare
  // ---------------------------------------------------------------------------

  /// Convenience method that crops [source] to a square (avatar use-case).
  ///
  /// Returns `null` when the user cancels.
  static Future<MediaFile?> cropSquare(
    BuildContext context,
    MediaFile source, {
    Color? toolbarColor,
  }) => crop(
    context,
    source,
    aspectRatio: (x: 1, y: 1),
    toolbarColor: toolbarColor,
  );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _buildTargetPath() {
    final dir = Directory.systemTemp.path;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$dir/primekit_crop_$ts.png';
  }

  static String _basename(String path) {
    final sep = path.lastIndexOf('/');
    return sep == -1 ? path : path.substring(sep + 1);
  }
}
