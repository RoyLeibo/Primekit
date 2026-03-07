import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/media/upload_task.dart';

void main() {
  group('UploadTask', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    UploadTaskController makeController() =>
        UploadTaskController(taskId: 'task_test');

    // -------------------------------------------------------------------------
    // Progress stream — subscribe first, then emit
    // -------------------------------------------------------------------------

    group('progress stream', () {
      test('emits values as controller emits them', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        // Collect future emissions.
        final emitted = <double>[];
        final completer = Completer<void>();
        task.progress.listen(emitted.add, onDone: completer.complete);

        ctrl.setProgress(0.25);
        ctrl.setProgress(0.75);
        ctrl.complete(downloadUrl: 'https://example.com/file.jpg');

        await completer.future;
        expect(emitted, containsAllInOrder([0.25, 0.75, 1.0]));
      });

      test('clamps negative value to 0.0', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final emitted = <double>[];
        final completer = Completer<void>();
        task.progress.listen(emitted.add, onDone: completer.complete);

        ctrl.setProgress(-5.0);
        ctrl.complete(downloadUrl: 'https://example.com/file.jpg');

        await completer.future;
        expect(emitted, contains(0.0));
      });

      test('clamps value above 1.0 to 1.0', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final emitted = <double>[];
        final completer = Completer<void>();
        task.progress.listen(emitted.add, onDone: completer.complete);

        ctrl.setProgress(200.0);
        ctrl.complete(downloadUrl: 'https://example.com/file.jpg');

        await completer.future;
        // The 200.0 is clamped to 1.0; then complete adds another 1.0.
        for (final v in emitted) {
          expect(v, inInclusiveRange(0.0, 1.0));
        }
      });
    });

    // -------------------------------------------------------------------------
    // Status transitions
    // -------------------------------------------------------------------------

    group('status transitions', () {
      test('starts with pending emitted first', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final statuses = <UploadStatus>[];
        final completer = Completer<void>();
        task.status.listen(statuses.add, onDone: completer.complete);

        ctrl.complete(downloadUrl: 'https://example.com/f.jpg');

        await completer.future;
        expect(statuses.first, UploadStatus.pending);
      });

      test('transitions pending→uploading→completed', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final statuses = <UploadStatus>[];
        final completer = Completer<void>();
        task.status.listen(statuses.add, onDone: completer.complete);

        ctrl.setStatus(UploadStatus.uploading);
        ctrl.complete(downloadUrl: 'https://example.com/f.jpg');

        await completer.future;

        expect(
          statuses,
          containsAllInOrder([
            UploadStatus.pending,
            UploadStatus.uploading,
            UploadStatus.completed,
          ]),
        );
      });

      test('transitions to failed on fail()', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final statuses = <UploadStatus>[];
        final completer = Completer<void>();
        task.status.listen(
          statuses.add,
          onDone: completer.complete,
          onError: (_) {},
        );

        // Suppress the unhandled downloadUrl error.
        unawaited(task.downloadUrl.catchError((_) => ''));
        ctrl.fail(Exception('network error'));

        await completer.future;
        expect(statuses, contains(UploadStatus.failed));
      });

      test('transitions to cancelled on cancel()', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final statuses = <UploadStatus>[];
        final completer = Completer<void>();
        task.status.listen(
          statuses.add,
          onDone: completer.complete,
          onError: (_) {},
        );

        // Suppress the unhandled downloadUrl error.
        unawaited(task.downloadUrl.catchError((_) => ''));
        await task.cancel();

        await completer.future;
        expect(statuses, contains(UploadStatus.cancelled));
      });
    });

    // -------------------------------------------------------------------------
    // downloadUrl
    // -------------------------------------------------------------------------

    group('downloadUrl', () {
      test('resolves to URL on complete()', () async {
        const url = 'https://cdn.example.com/avatars/user_1.jpg';
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        ctrl.complete(downloadUrl: url);

        expect(await task.downloadUrl, url);
      });

      test('throws UploadFailedException on fail()', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        ctrl.fail(Exception('server error'));

        await expectLater(
          task.downloadUrl,
          throwsA(isA<UploadFailedException>()),
        );
      });

      test('throws UploadCancelledException on cancel()', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        unawaited(task.cancel());

        await expectLater(
          task.downloadUrl,
          throwsA(isA<UploadCancelledException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // pause / resume
    // -------------------------------------------------------------------------

    group('pause / resume', () {
      test('emits paused then uploading', () async {
        final ctrl = makeController();
        final task = UploadTask.fromController(ctrl);

        final statuses = <UploadStatus>[];
        final completer = Completer<void>();
        task.status.listen(statuses.add, onDone: completer.complete);

        await task.pause();
        await task.resume();
        ctrl.complete(downloadUrl: 'https://example.com/f.jpg');

        await completer.future;

        expect(statuses, contains(UploadStatus.paused));
        expect(statuses, contains(UploadStatus.uploading));
      });
    });

    // -------------------------------------------------------------------------
    // taskId
    // -------------------------------------------------------------------------

    test('fromController exposes taskId', () {
      final ctrl = UploadTaskController(taskId: 'my_unique_id');
      final task = UploadTask.fromController(ctrl);
      expect(task.taskId, 'my_unique_id');
    });
  });
}
