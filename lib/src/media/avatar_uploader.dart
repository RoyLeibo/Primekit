import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_compressor.dart';
import 'image_cropper_service.dart';
import 'media_file.dart';
import 'media_picker.dart';
import 'media_uploader.dart';
import 'upload_task.dart';

/// Convenience pipeline: pick → crop to square → compress → upload.
///
/// Used for the typical "change avatar" flow.
///
/// ```dart
/// final avatarUploader = AvatarUploader(uploader: FirebaseStorageUploader());
/// final url = await avatarUploader.pickAndUpload(userId: 'user_123');
/// if (url != null) {
///   // url is the public download URL of the uploaded avatar
/// }
/// ```
final class AvatarUploader {
  /// Creates an [AvatarUploader].
  ///
  /// [uploader] — backend that persists the file (e.g. a
  ///   `FirebaseStorageUploader`).
  /// [pathPrefix] — remote directory prefix, e.g. `'avatars'`.
  /// [targetSizeKb] — maximum compressed file size in kilobytes.
  /// [outputSize] — square dimension in pixels for the final avatar.
  const AvatarUploader({
    required MediaUploader uploader,
    String pathPrefix = 'avatars',
    int targetSizeKb = 200,
    int outputSize = 512,
  })  : _uploader = uploader,
        _pathPrefix = pathPrefix,
        _targetSizeKb = targetSizeKb,
        _outputSize = outputSize;

  final MediaUploader _uploader;
  final String _pathPrefix;
  final int _targetSizeKb;
  final int _outputSize;

  // ---------------------------------------------------------------------------
  // pickAndUpload
  // ---------------------------------------------------------------------------

  /// Full pipeline: pick image → crop to square → compress → upload.
  ///
  /// Returns the public download URL on success, or `null` if the user cancels
  /// any step (pick or crop).
  ///
  /// [userId] — used to build the remote path: `<pathPrefix>/<userId>.jpg`.
  /// [source] — [ImageSource.gallery] (default) or [ImageSource.camera].
  /// [context] — optional, currently unused but accepted for API consistency
  ///             with crop UI theming in future.
  Future<String?> pickAndUpload({
    required String userId,
    ImageSource source = ImageSource.gallery,
    BuildContext? context,
  }) async {
    // Step 1: Pick image.
    final picked = await MediaPicker.pickImage(source: source);
    if (picked == null) return null;

    // Step 2: Crop to square.
    final cropped = await ImageCropperService.cropSquare(picked);
    if (cropped == null) return null;

    // Step 3: Compress.
    final compressed = await ImageCompressor.compressToSize(
      cropped,
      targetSizeKb: _targetSizeKb,
    );

    // Also enforce output dimensions.
    final resized = await ImageCompressor.compress(
      compressed,
      maxWidth: _outputSize,
      maxHeight: _outputSize,
    );

    // Step 4: Upload.
    final remotePath = '$_pathPrefix/$userId.jpg';
    final task = _uploader.upload(file: resized, remotePath: remotePath);

    try {
      return await task.downloadUrl;
    } catch (error) {
      throw Exception('AvatarUploader.pickAndUpload upload failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // uploadFile
  // ---------------------------------------------------------------------------

  /// Uploads [file] directly (skips pick and crop steps).
  ///
  /// [userId] — used to build the remote path: `<pathPrefix>/<userId>.jpg`.
  UploadTask uploadFile(MediaFile file, {required String userId}) {
    final remotePath = '$_pathPrefix/$userId.jpg';
    return _uploader.upload(file: file, remotePath: remotePath);
  }
}
