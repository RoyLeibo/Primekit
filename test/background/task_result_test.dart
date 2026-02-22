import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/background/task_result.dart';

void main() {
  group('TaskResult sealed variants', () {
    // -----------------------------------------------------------------------
    // TaskSuccess
    // -----------------------------------------------------------------------

    test('TaskResult.success() creates a TaskSuccess', () {
      const result = TaskResult.success();
      expect(result, isA<TaskSuccess>());
    });

    test('TaskSuccess is const constructible', () {
      const result = TaskSuccess();
      expect(result, isNotNull);
    });

    test('TaskSuccess toString is descriptive', () {
      expect(const TaskSuccess().toString(), contains('success'));
    });

    // -----------------------------------------------------------------------
    // TaskRetry
    // -----------------------------------------------------------------------

    test('TaskResult.retry() creates a TaskRetry', () {
      const result = TaskResult.retry();
      expect(result, isA<TaskRetry>());
    });

    test('TaskRetry stores optional reason', () {
      const result = TaskRetry(reason: 'network unavailable');
      expect(result.reason, 'network unavailable');
    });

    test('TaskRetry reason is null by default', () {
      const result = TaskRetry();
      expect(result.reason, isNull);
    });

    test('TaskRetry toString contains retry', () {
      expect(const TaskRetry().toString(), contains('retry'));
    });

    test('TaskRetry with reason toString contains reason', () {
      const result = TaskRetry(reason: 'test reason');
      expect(result.toString(), contains('test reason'));
    });

    // -----------------------------------------------------------------------
    // TaskFailure
    // -----------------------------------------------------------------------

    test('TaskResult.failure() creates a TaskFailure', () {
      final result = TaskResult.failure(Exception('boom'));
      expect(result, isA<TaskFailure>());
    });

    test('TaskFailure stores the error', () {
      final error = Exception('some error');
      final result = TaskFailure(error);
      expect(result.error, same(error));
    });

    test('TaskFailure toString contains failure', () {
      final result = TaskFailure(Exception('x'));
      expect(result.toString(), contains('failure'));
    });

    // -----------------------------------------------------------------------
    // Exhaustive switch
    // -----------------------------------------------------------------------

    test('sealed switch is exhaustive over all variants', () {
      TaskResult result = const TaskResult.success();
      final label = switch (result) {
        TaskSuccess() => 'success',
        TaskRetry() => 'retry',
        TaskFailure() => 'failure',
      };
      expect(label, 'success');

      result = const TaskResult.retry(reason: 'net');
      expect(
        switch (result) {
          TaskSuccess() => 'success',
          TaskRetry() => 'retry',
          TaskFailure() => 'failure',
        },
        'retry',
      );

      result = TaskResult.failure(StateError('bad'));
      expect(
        switch (result) {
          TaskSuccess() => 'success',
          TaskRetry() => 'retry',
          TaskFailure() => 'failure',
        },
        'failure',
      );
    });
  });
}
