import 'package:flutter/material.dart';

import 'media_file.dart';

/// No-op stub for [ImageCropperService].
///
/// Returns `null` for all crop requests. This branch is unreachable in
/// practice — Web uses the html variant and native uses the io variant.
abstract final class ImageCropperService {
  ImageCropperService._();

  static Future<MediaFile?> crop(
    BuildContext context,
    MediaFile source, {
    ({int x, int y})? aspectRatio,
    String? toolbarTitle,
    Color? toolbarColor,
  }) async => null;

  static Future<MediaFile?> cropSquare(
    BuildContext context,
    MediaFile source, {
    Color? toolbarColor,
  }) async => null;
}
