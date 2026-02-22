import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'media_file.dart';

/// Wraps [ImagePicker] with a clean, immutable-result API.
///
/// All methods return [MediaFile] (or `null` / a list), without exposing
/// the underlying `XFile` or `PickedFile` types.
///
/// ```dart
/// final file = await MediaPicker.pickImage();
/// if (file != null) {
///   // use file.path, file.sizeBytes, etc.
/// }
/// ```
abstract final class MediaPicker {
  MediaPicker._();

  static final _picker = ImagePicker();

  // ---------------------------------------------------------------------------
  // Pick from gallery / camera
  // ---------------------------------------------------------------------------

  /// Opens the system image picker and returns the chosen image as [MediaFile].
  ///
  /// Returns `null` when the user cancels.
  ///
  /// [source] — [ImageSource.gallery] (default) or [ImageSource.camera].
  /// [maxWidth] / [maxHeight] — downsample during decoding (platform-level).
  /// [imageQuality] — JPEG/WebP quality 0–100 applied by the platform plugin.
  /// [requestFullMetadata] — when `true`, requests EXIF/GPS data (iOS).
  static Future<MediaFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = false,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata,
      );
      if (xFile == null) return null;
      return _fromXFile(xFile);
    } catch (error) {
      throw Exception('MediaPicker.pickImage failed: $error');
    }
  }

  /// Opens the system multi-image picker.
  ///
  /// Returns an empty list when the user cancels or selects nothing.
  ///
  /// [limit] — maximum number of images the user may pick (platform-level).
  static Future<List<MediaFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final xFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );
      return [
        for (final xf in xFiles) await _fromXFile(xf),
      ];
    } catch (error) {
      throw Exception('MediaPicker.pickMultipleImages failed: $error');
    }
  }

  /// Opens the system video picker.
  ///
  /// Returns `null` when the user cancels.
  static Future<MediaFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final xFile = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      if (xFile == null) return null;
      return _fromXFile(xFile);
    } catch (error) {
      throw Exception('MediaPicker.pickVideo failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Camera shortcuts
  // ---------------------------------------------------------------------------

  /// Opens the camera to take a photo.
  ///
  /// Returns `null` when the user cancels.
  static Future<MediaFile?> takePhoto({int? imageQuality}) =>
      pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

  /// Opens the camera to record a video.
  ///
  /// Returns `null` when the user cancels.
  static Future<MediaFile?> recordVideo({Duration? maxDuration}) =>
      pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static Future<MediaFile> _fromXFile(XFile xFile) async {
    final file = File(xFile.path);
    int? sizeBytes;
    try {
      sizeBytes = await file.length();
    } on FileSystemException {
      // Size unavailable — leave null.
    }
    return MediaFile(
      path: xFile.path,
      name: xFile.name,
      sizeBytes: sizeBytes,
      mimeType: xFile.mimeType,
    );
  }
}
