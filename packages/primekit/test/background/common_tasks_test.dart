import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/background/common_tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // -------------------------------------------------------------------------
  // NetworkSyncTask
  // -------------------------------------------------------------------------

  group('NetworkSyncTask', () {
    late NetworkSyncTask task;

    setUp(() {
      task = NetworkSyncTask();
    });

    test('taskId is "primekit.network_sync"', () {
      expect(task.taskId, 'primekit.network_sync');
    });

    test('static id matches instance taskId', () {
      expect(NetworkSyncTask.id, task.taskId);
    });

    test('execute returns true on success', () async {
      final result = await task.execute({});
      expect(result, isTrue);
    });

    test('execute accepts non-empty inputData', () async {
      final result = await task.execute({'user_id': 'abc123'});
      expect(result, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // CacheCleanupTask
  // -------------------------------------------------------------------------

  group('CacheCleanupTask', () {
    late CacheCleanupTask task;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      task = CacheCleanupTask();
    });

    test('taskId is "primekit.cache_cleanup"', () {
      expect(task.taskId, 'primekit.cache_cleanup');
    });

    test('static id matches instance taskId', () {
      expect(CacheCleanupTask.id, task.taskId);
    });

    test('execute completes without error on empty prefs', () async {
      await expectLater(task.execute({}), completes);
    });

    test('execute returns true on success', () async {
      final result = await task.execute({});
      expect(result, isTrue);
    });

    test('execute removes expired cache entries', () async {
      // Seed prefs with an expired entry.
      final expiredTime = DateTime.now().toUtc().subtract(
        const Duration(hours: 2),
      );
      SharedPreferences.setMockInitialValues({
        'pk_json_cache::old_key':
            '{"data":{},"expiresAt":"'
            '${expiredTime.toIso8601String()}"}',
        'pk_json_cache::valid_key': '{"data":{},"expiresAt":null}',
        'unrelated_key': 'untouched',
      });

      await task.execute({});

      final prefs = await SharedPreferences.getInstance();
      // The expired entry should be removed.
      expect(prefs.getString('pk_json_cache::old_key'), isNull);
      // The never-expiring entry should be kept.
      expect(prefs.getString('pk_json_cache::valid_key'), isNotNull);
      // Unrelated keys are untouched.
      expect(prefs.getString('unrelated_key'), 'untouched');
    });

    test('execute keeps entries that are not expired', () async {
      final futureTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'pk_json_cache::fresh':
            '{"data":{},"expiresAt":"'
            '${futureTime.toIso8601String()}"}',
      });

      await task.execute({});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pk_json_cache::fresh'), isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // EmailQueueFlushTask
  // -------------------------------------------------------------------------

  group('EmailQueueFlushTask', () {
    late EmailQueueFlushTask task;

    setUp(() {
      task = EmailQueueFlushTask();
    });

    test('taskId is "primekit.email_flush"', () {
      expect(task.taskId, 'primekit.email_flush');
    });

    test('static id matches instance taskId', () {
      expect(EmailQueueFlushTask.id, task.taskId);
    });

    test('execute returns true on success', () async {
      final result = await task.execute({});
      expect(result, isTrue);
    });

    test('execute completes without error', () async {
      await expectLater(task.execute({}), completes);
    });
  });
}
