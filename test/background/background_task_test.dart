import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/background/background_task.dart';

void main() {
  // -------------------------------------------------------------------------
  // BackgroundConstraints
  // -------------------------------------------------------------------------

  group('BackgroundConstraints defaults', () {
    test('networkType defaults to notRequired', () {
      const c = BackgroundConstraints();
      expect(c.networkType, NetworkType.notRequired);
    });

    test('requiresCharging defaults to false', () {
      const c = BackgroundConstraints();
      expect(c.requiresCharging, isFalse);
    });

    test('requiresDeviceIdle defaults to false', () {
      const c = BackgroundConstraints();
      expect(c.requiresDeviceIdle, isFalse);
    });

    test('is const constructible with defaults', () {
      const c = BackgroundConstraints();
      expect(c, isNotNull);
    });

    test('all fields can be set', () {
      const c = BackgroundConstraints(
        networkType: NetworkType.unmetered,
        requiresCharging: true,
        requiresDeviceIdle: true,
      );
      expect(c.networkType, NetworkType.unmetered);
      expect(c.requiresCharging, isTrue);
      expect(c.requiresDeviceIdle, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // NetworkType enum
  // -------------------------------------------------------------------------

  group('NetworkType enum', () {
    test('has three values', () {
      expect(NetworkType.values.length, 3);
    });

    test('values are notRequired, connected, unmetered', () {
      expect(NetworkType.values, [
        NetworkType.notRequired,
        NetworkType.connected,
        NetworkType.unmetered,
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // TaskConfig
  // -------------------------------------------------------------------------

  group('TaskConfig', () {
    test('stores taskId correctly', () {
      const config = TaskConfig(taskId: 'com.example.sync');
      expect(config.taskId, 'com.example.sync');
    });

    test('initialDelay defaults to null', () {
      const config = TaskConfig(taskId: 'task');
      expect(config.initialDelay, isNull);
    });

    test('constraints defaults to BackgroundConstraints()', () {
      const config = TaskConfig(taskId: 'task');
      expect(config.constraints.networkType, NetworkType.notRequired);
      expect(config.constraints.requiresCharging, isFalse);
    });

    test('inputData defaults to empty map', () {
      const config = TaskConfig(taskId: 'task');
      expect(config.inputData, isEmpty);
    });

    test('maxRetries defaults to null', () {
      const config = TaskConfig(taskId: 'task');
      expect(config.maxRetries, isNull);
    });

    test('all fields can be set', () {
      const config = TaskConfig(
        taskId: 'my.task',
        initialDelay: Duration(seconds: 30),
        constraints: BackgroundConstraints(
          networkType: NetworkType.connected,
          requiresCharging: true,
        ),
        inputData: {'user_id': 'abc123'},
        maxRetries: 3,
      );

      expect(config.taskId, 'my.task');
      expect(config.initialDelay, const Duration(seconds: 30));
      expect(config.constraints.networkType, NetworkType.connected);
      expect(config.constraints.requiresCharging, isTrue);
      expect(config.inputData['user_id'], 'abc123');
      expect(config.maxRetries, 3);
    });

    test('is const constructible', () {
      const config = TaskConfig(taskId: 'const.task');
      expect(config, isNotNull);
    });
  });
}
