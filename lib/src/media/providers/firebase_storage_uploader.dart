import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as fb;
import 'package:uuid/uuid.dart';

import '../media_file.dart';
import '../media_uploader.dart';
import '../upload_task.dart';

/// [MediaUploader] implementation backed by Firebase Cloud Storage.
///
/// Inject a custom [fb.FirebaseStorage] instance in tests.
///
/// ```dart
/// final uploader = FirebaseStorageUploader();
/// final task = uploader.upload(
///   file: photo,
///   remotePath: 'avatars/user_123.jpg',
/// );
/// task.progress.listen((p) => print('${(p * 100).toStringAsFixed(0)}%'));
/// final url = await task.downloadUrl;
/// ```
final class FirebaseStorageUploader implements MediaUploader {
  /// Creates a [FirebaseStorageUploader].
  ///
  /// [storage] defaults to [fb.FirebaseStorage.instance] when not provided.
  FirebaseStorageUploader({fb.FirebaseStorage? storage})
      : _storage = storage ?? fb.FirebaseStorage.instance;

  final fb.FirebaseStorage _storage;
  static const _uuid = Uuid();

  @override
  String get providerId => 'firebase_storage';

  // ---------------------------------------------------------------------------
  // upload
  // ---------------------------------------------------------------------------

  @override
  UploadTask upload({
    required MediaFile file,
    required String remotePath,
    Map<String, String>? metadata,
  }) {
    final taskId = _uuid.v4();
    final controller = UploadTaskController(taskId: taskId);
    final task = UploadTask.fromController(controller);

    _startUpload(
      file: file,
      remotePath: remotePath,
      metadata: metadata,
      controller: controller,
    );

    return task;
  }

  void _startUpload({
    required MediaFile file,
    required String remotePath,
    required Map<String, String>? metadata,
    required UploadTaskController controller,
  }) {
    // Fire-and-forget; errors are forwarded via controller.fail().
    Future<void>(() async {
      try {
        final ref = _storage.ref(remotePath);
        final storageMetadata = metadata != null
            ? fb.SettableMetadata(customMetadata: metadata)
            : null;

        final fbTask = ref.putFile(File(file.path), storageMetadata);
        controller.setStatus(UploadStatus.uploading);

        fbTask.snapshotEvents.listen(
          (snapshot) {
            final total = snapshot.totalBytes;
            if (total > 0) {
              controller
                  .setProgress(snapshot.bytesTransferred / total);
            }
          },
          onError: controller.fail,
        );

        final snapshot = await fbTask;
        final url = await snapshot.ref.getDownloadURL();
        controller.complete(downloadUrl: url);
      } on Exception catch (error) {
        controller.fail(error);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------

  @override
  Future<void> delete(String remotePath) async {
    try {
      await _storage.ref(remotePath).delete();
    } catch (error) {
      throw Exception(
        'FirebaseStorageUploader.delete failed for '
        '"$remotePath": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // getDownloadUrl
  // ---------------------------------------------------------------------------

  @override
  Future<String> getDownloadUrl(String remotePath) async {
    try {
      return await _storage.ref(remotePath).getDownloadURL();
    } catch (error) {
      throw Exception(
        'FirebaseStorageUploader.getDownloadUrl failed for '
        '"$remotePath": $error',
      );
    }
  }
}
