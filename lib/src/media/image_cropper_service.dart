import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import 'media_file.dart';

/// Wraps [ImageCropper] with a clean immutable-result API.
///
/// The crop UI is presented on top of the current navigation stack.
/// Returns `null` if the user cancels the crop.
///
/// ```dart
/// final cropped = await ImageCropperService.crop(
///   context,
///   source,
///   aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
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
  /// [aspectRatio] — forced ratio, e.g.
  ///   `CropAspectRatio(ratioX: 1, ratioY: 1)`.
  /// [presets] — list of ratio presets shown in the crop toolbar.
  /// [cropStyle] — [CropStyle.rectangle] (default) or [CropStyle.circle].
  /// [toolbarColor] — colour of the crop toolbar.
  /// [toolbarTitle] — title shown in the crop toolbar.
  static Future<MediaFile?> crop(
    BuildContext context,
    MediaFile source, {
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? presets,
    CropStyle cropStyle = CropStyle.rectangle,
    Color? toolbarColor,
    String? toolbarTitle,
  }) async {
    try {
      final effectivePresets =
          presets ??
          const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ];

      final uiSettings = <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: toolbarTitle ?? 'Crop Image',
          toolbarColor: toolbarColor,
          cropStyle: cropStyle,
          lockAspectRatio: aspectRatio != null,
          aspectRatioPresets: effectivePresets,
        ),
        IOSUiSettings(
          title: toolbarTitle ?? 'Crop Image',
          aspectRatioLockEnabled: aspectRatio != null,
          cropStyle: cropStyle,
          aspectRatioPresets: effectivePresets,
        ),
      ];

      // Web requires WebUiSettings — add it conditionally.
      if (kIsWeb) {
        uiSettings.add(WebUiSettings(context: context));
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: source.path,
        aspectRatio: aspectRatio,
        uiSettings: uiSettings,
      );

      if (cropped == null) return null;
      return await _fromCroppedFile(source, cropped);
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
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    presets: const [CropAspectRatioPreset.square],
    cropStyle: CropStyle.circle,
    toolbarColor: toolbarColor,
    toolbarTitle: 'Crop Avatar',
  );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<MediaFile> _fromCroppedFile(
    MediaFile source,
    CroppedFile cropped,
  ) async {
    int? sizeBytes;
    try {
      // CroppedFile.readAsBytes() is cross-platform (works on web and native).
      final bytes = await cropped.readAsBytes();
      sizeBytes = bytes.length;
    } catch (_) {
      // Size unavailable — leave null.
    }
    return source.copyWith(
      path: cropped.path,
      name: _basename(cropped.path),
      sizeBytes: sizeBytes,
      // Width/height unknown after crop without decoding.
      width: null,
      height: null,
    );
  }

  static String _basename(String path) {
    final sep = path.lastIndexOf('/');
    return sep == -1 ? path : path.substring(sep + 1);
  }
}
