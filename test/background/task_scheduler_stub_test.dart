import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/background/task_scheduler_stub.dart';

void main() {
  group('TaskScheduler stub', () {
    test('initialize() completes without error', () async {
      await expectLater(
        TaskScheduler.initialize(taskRegistry: {}),
        completes,
      );
    });

    test('schedulePeriodic() completes without error', () async {
      await expectLater(
        TaskScheduler.instance.schedulePeriodic(
          uniqueName: 'test.periodic',
          taskId: 'test',
          frequency: const Duration(minutes: 15),
        ),
        completes,
      );
    });

    test('scheduleOnce() completes without error', () async {
      await expectLater(
        TaskScheduler.instance.scheduleOnce(
          uniqueName: 'test.once',
          taskId: 'test',
        ),
        completes,
      );
    });

    test('cancel() completes without error', () async {
      await expectLater(
        TaskScheduler.instance.cancel('test.periodic'),
        completes,
      );
    });

    test('cancelAll() completes without error', () async {
      await expectLater(
        TaskScheduler.instance.cancelAll(),
        completes,
      );
    });

    test('isScheduled() always returns false', () async {
      final result = await TaskScheduler.instance.isScheduled('any.task');
      expect(result, isFalse);
    });
  });
}
