import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/background/background_task.dart';
import 'package:primekit/src/background/common_tasks.dart';
import 'package:primekit/src/background/task_registry.dart';

// A minimal BackgroundTask for testing.
final class _EchoTask implements BackgroundTask {
  @override
  String get taskId => 'test.echo';

  @override
  Future<bool> execute(Map<String, dynamic> inputData) async => true;
}

void main() {
  setUp(() {
    TaskRegistry.clearForTesting();
  });

  // -------------------------------------------------------------------------
  // register + resolve
  // -------------------------------------------------------------------------

  group('register and resolve', () {
    test('resolve returns correct task after registration', () {
      TaskRegistry.register('test.echo', _EchoTask.new);
      final task = TaskRegistry.resolve('test.echo');
      expect(task, isA<_EchoTask>());
    });

    test('resolve returns null for unknown taskId', () {
      final task = TaskRegistry.resolve('com.unknown.task');
      expect(task, isNull);
    });

    test('each resolve call creates a new instance', () {
      TaskRegistry.register('test.echo', _EchoTask.new);
      final a = TaskRegistry.resolve('test.echo');
      final b = TaskRegistry.resolve('test.echo');
      expect(a, isNot(same(b)));
    });

    test('re-registering overwrites the previous factory', () {
      TaskRegistry.register('test.task', _EchoTask.new);
      TaskRegistry.register('test.task', _EchoTask.new);
      final task = TaskRegistry.resolve('test.task');
      expect(task, isA<_EchoTask>());
    });

    test('registeredIds reflects all registered tasks', () {
      TaskRegistry.register('a.task', _EchoTask.new);
      TaskRegistry.register('b.task', _EchoTask.new);
      expect(TaskRegistry.registeredIds, containsAll(['a.task', 'b.task']));
    });
  });

  // -------------------------------------------------------------------------
  // registerBuiltIns
  // -------------------------------------------------------------------------

  group('registerBuiltIns', () {
    test('registers NetworkSyncTask', () {
      TaskRegistry.registerBuiltIns();
      final task = TaskRegistry.resolve(NetworkSyncTask.id);
      expect(task, isA<NetworkSyncTask>());
    });

    test('registers CacheCleanupTask', () {
      TaskRegistry.registerBuiltIns();
      final task = TaskRegistry.resolve(CacheCleanupTask.id);
      expect(task, isA<CacheCleanupTask>());
    });

    test('registers EmailQueueFlushTask', () {
      TaskRegistry.registerBuiltIns();
      final task = TaskRegistry.resolve(EmailQueueFlushTask.id);
      expect(task, isA<EmailQueueFlushTask>());
    });

    test('all built-in IDs are in registeredIds after registerBuiltIns', () {
      TaskRegistry.registerBuiltIns();
      expect(
        TaskRegistry.registeredIds,
        containsAll([
          NetworkSyncTask.id,
          CacheCleanupTask.id,
          EmailQueueFlushTask.id,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // clearForTesting
  // -------------------------------------------------------------------------

  group('clearForTesting', () {
    test('resolve returns null after clearing', () {
      TaskRegistry.register('test.echo', _EchoTask.new);
      TaskRegistry.clearForTesting();
      expect(TaskRegistry.resolve('test.echo'), isNull);
    });

    test('registeredIds is empty after clearing', () {
      TaskRegistry.register('test.echo', _EchoTask.new);
      TaskRegistry.clearForTesting();
      expect(TaskRegistry.registeredIds, isEmpty);
    });
  });
}
