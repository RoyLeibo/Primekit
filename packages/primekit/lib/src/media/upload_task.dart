import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// The lifecycle state of an [UploadTask].
enum UploadStatus {
  /// Task has been created but upload has not started.
  pending,

  /// Upload is actively transferring data.
  uploading,

  /// Upload has been paused by the caller.
  paused,

  /// Upload finished successfully and [UploadTask.downloadUrl] is ready.
  completed,

  /// Upload failed; [UploadTask.downloadUrl] will never resolve.
  failed,

  /// Upload was cancelled by the caller.
  cancelled,
}

/// Represents an in-flight or completed file upload.
///
/// Progress and status changes are exposed as broadcast [Stream]s so multiple
/// listeners can observe the same task.
///
/// ```dart
/// final task = uploader.upload(
///   file: photo,
///   remotePath: 'avatars/user123.jpg',
/// );
/// task.progress.listen((p) => setState(() => _progress = p));
/// final url = await task.downloadUrl;
/// ```
class UploadTask {
  /// Creates an [UploadTask] backed by the provided [UploadTaskController].
  ///
  /// Provider implementations call this factory to construct tasks that they
  /// then drive through [UploadTaskController].
  factory UploadTask.fromController(UploadTaskController controller) =>
      UploadTask._(
        taskId: controller.taskId,
        progress: controller._progressSubject,
        status: controller._statusSubject,
        downloadUrl: controller._urlCompleter.future,
        onPause: controller.pause,
        onResume: controller.resume,
        onCancel: controller.cancel,
      );

  UploadTask._({
    required this.taskId,
    required this.progress,
    required this.status,
    required this.downloadUrl,
    required Future<void> Function() onPause,
    required Future<void> Function() onResume,
    required Future<void> Function() onCancel,
  }) : _onPause = onPause,
       _onResume = onResume,
       _onCancel = onCancel;

  /// Unique identifier for this task (e.g. a UUID or remote path hash).
  final String taskId;

  /// Upload progress from `0.0` (not started) to `1.0` (complete).
  ///
  /// Uses a [BehaviorSubject] internally so late subscribers see the latest
  /// value immediately.
  final Stream<double> progress;

  /// Stream of [UploadStatus] transitions.
  ///
  /// Uses a [BehaviorSubject] internally so late subscribers see the current
  /// status immediately (starts with [UploadStatus.pending]).
  final Stream<UploadStatus> status;

  /// Resolves to the public download URL once [UploadStatus.completed].
  ///
  /// Throws if the upload fails or is cancelled.
  final Future<String> downloadUrl;

  final Future<void> Function() _onPause;
  final Future<void> Function() _onResume;
  final Future<void> Function() _onCancel;

  /// Pauses the upload (platform-dependent; no-op for HTTP uploads).
  Future<void> pause() => _onPause();

  /// Resumes a paused upload.
  Future<void> resume() => _onResume();

  /// Cancels the upload; [downloadUrl] will throw [UploadCancelledException].
  Future<void> cancel() => _onCancel();
}

// ---------------------------------------------------------------------------
// UploadTaskController
// ---------------------------------------------------------------------------

/// Mutable controller used by `MediaUploader` implementations to drive
/// an [UploadTask].
///
/// ```dart
/// final controller = UploadTaskController(taskId: taskId);
/// final task = UploadTask.fromController(controller);
/// controller.setStatus(UploadStatus.uploading);
/// controller.setProgress(0.5);
/// controller.complete(downloadUrl: url);
/// ```
class UploadTaskController {
  /// Creates a controller with [taskId].
  ///
  /// The initial status [UploadStatus.pending] is seeded into the
  /// [BehaviorSubject] so late subscribers receive it immediately.
  UploadTaskController({required this.taskId});

  /// The task identifier shared with the resulting [UploadTask].
  final String taskId;

  // BehaviorSubject replays the latest value to new subscribers.
  final BehaviorSubject<double> _progressSubject = BehaviorSubject<double>();
  final BehaviorSubject<UploadStatus> _statusSubject =
      BehaviorSubject<UploadStatus>.seeded(UploadStatus.pending);
  final Completer<String> _urlCompleter = Completer<String>();

  bool _cancelled = false;

  /// Emits a progress value in `[0.0, 1.0]`.
  void setProgress(double value) {
    if (_progressSubject.isClosed) return;
    _progressSubject.add(value.clamp(0.0, 1.0));
  }

  /// Emits a new [UploadStatus].
  void setStatus(UploadStatus s) {
    if (_statusSubject.isClosed) return;
    _statusSubject.add(s);
  }

  /// Marks the upload as complete and resolves [UploadTask.downloadUrl].
  void complete({required String downloadUrl}) {
    setProgress(1.0);
    setStatus(UploadStatus.completed);
    if (!_urlCompleter.isCompleted) {
      _urlCompleter.complete(downloadUrl);
    }
    _close();
  }

  /// Marks the upload as failed.
  void fail(Object error) {
    setStatus(UploadStatus.failed);
    if (!_urlCompleter.isCompleted) {
      _urlCompleter.completeError(
        UploadFailedException('Upload failed: $error'),
      );
    }
    _close();
  }

  /// Pauses the upload (implementor hook).
  Future<void> pause() async => setStatus(UploadStatus.paused);

  /// Resumes the upload (implementor hook).
  Future<void> resume() async => setStatus(UploadStatus.uploading);

  /// Cancels the upload (implementor hook).
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    setStatus(UploadStatus.cancelled);
    if (!_urlCompleter.isCompleted) {
      _urlCompleter.completeError(const UploadCancelledException());
    }
    _close();
  }

  void _close() {
    if (!_progressSubject.isClosed) _progressSubject.close();
    if (!_statusSubject.isClosed) _statusSubject.close();
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when an upload fails.
final class UploadFailedException implements Exception {
  /// Creates an [UploadFailedException] with a [message].
  const UploadFailedException(this.message);

  /// Developer-facing error message.
  final String message;

  @override
  String toString() => 'UploadFailedException: $message';
}

/// Thrown when the caller cancels an upload and then awaits
/// [UploadTask.downloadUrl].
final class UploadCancelledException implements Exception {
  /// Creates an [UploadCancelledException].
  const UploadCancelledException();

  @override
  String toString() => 'UploadCancelledException';
}
