import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'media_file.dart';

/// Wraps [croppy] with a clean immutable-result API for Web.
///
/// Loads the source image via [NetworkImage] (accepts blob URLs returned by
/// `image_picker` on web). Returns a new blob URL as the cropped file path.
abstract final class ImageCropperService {
  ImageCropperService._();

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
        imageProvider: NetworkImage(source.path),
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

      final blobUrl = _createBlobUrl(bytes);
      return source.copyWith(
        path: blobUrl,
        name: 'cropped.png',
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

  static String _createBlobUrl(Uint8List bytes) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    return web.URL.createObjectURL(blob);
  }
}
