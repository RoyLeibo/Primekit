import 'media_file.dart';
import 'upload_task.dart';

/// Abstract interface for uploading [MediaFile]s to a remote storage backend.
///
/// Concrete implementations are provided for Firebase Storage and can be
/// added for S3, Cloudinary, etc.
///
/// ```dart
/// final uploader = FirebaseStorageUploader();
/// final task = uploader.upload(
///   file: photo,
///   remotePath: 'avatars/user_123.jpg',
/// );
/// final url = await task.downloadUrl;
/// ```
abstract interface class MediaUploader {
  /// Starts an upload of [file] to [remotePath] on the backend.
  ///
  /// [metadata] — optional key/value pairs stored alongside the file
  /// (e.g. `{'userId': '123', 'contentType': 'image/jpeg'}`).
  ///
  /// Returns an [UploadTask] immediately; the upload starts asynchronously.
  UploadTask upload({
    required MediaFile file,
    required String remotePath,
    Map<String, String>? metadata,
  });

  /// Deletes the file at [remotePath] from the backend.
  ///
  /// Throws if the file does not exist or the caller lacks permission.
  Future<void> delete(String remotePath);

  /// Returns a public download URL for the file at [remotePath].
  ///
  /// Throws if the file does not exist.
  Future<String> getDownloadUrl(String remotePath);

  /// Machine-readable identifier for this backend, e.g. `'firebase_storage'`.
  String get providerId;
}
