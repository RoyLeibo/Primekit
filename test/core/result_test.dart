import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/core/result.dart';
import 'package:primekit/src/core/exceptions.dart';

void main() {
  group('Result<S, F>', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Result<int, String>.success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('valueOrNull returns value', () {
        const result = Result<String, String>.success('hello');
        expect(result.valueOrNull, equals('hello'));
      });

      test('failureOrNull returns null', () {
        const result = Result<String, String>.success('hello');
        expect(result.failureOrNull, isNull);
      });

      test('valueOrThrow returns value', () {
        const result = Result<int, String>.success(99);
        expect(result.valueOrThrow, equals(99));
      });

      test('map transforms success value', () {
        const result = Result<int, String>.success(2);
        final mapped = result.map((v) => v * 10);
        expect(mapped.valueOrNull, equals(20));
      });

      test('mapFailure leaves success unchanged', () {
        const result = Result<int, String>.success(5);
        final mapped = result.mapFailure((f) => f.length);
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(5));
      });

      test('when calls success branch', () {
        const result = Result<int, String>.success(7);
        final output = result.when(
          success: (v) => 'got $v',
          failure: (_) => 'failed',
        );
        expect(output, equals('got 7'));
      });

      test('equality based on value', () {
        const a = Result<int, String>.success(1);
        const b = Result<int, String>.success(1);
        const c = Result<int, String>.success(2);
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('toString includes value', () {
        const result = Result<int, String>.success(42);
        expect(result.toString(), contains('42'));
      });
    });

    group('Failure', () {
      test('isFailure returns true', () {
        const result = Result<int, String>.failure('error');
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('valueOrNull returns null', () {
        const result = Result<int, String>.failure('error');
        expect(result.valueOrNull, isNull);
      });

      test('failureOrNull returns failure', () {
        const result = Result<int, String>.failure('oops');
        expect(result.failureOrNull, equals('oops'));
      });

      test('valueOrThrow throws StateError', () {
        const result = Result<int, String>.failure('err');
        expect(() => result.valueOrThrow, throwsStateError);
      });

      test('map leaves failure unchanged', () {
        const result = Result<int, String>.failure('err');
        final mapped = result.map((v) => v * 2);
        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull, equals('err'));
      });

      test('mapFailure transforms failure', () {
        const result = Result<int, String>.failure('error');
        final mapped = result.mapFailure((f) => f.length);
        expect(mapped.failureOrNull, equals(5)); // 'error'.length
      });

      test('when calls failure branch', () {
        const result = Result<int, String>.failure('bad');
        final output = result.when(
          success: (_) => 'ok',
          failure: (f) => 'fail: $f',
        );
        expect(output, equals('fail: bad'));
      });

      test('or returns other on failure', () {
        const failed = Result<int, String>.failure('err');
        const fallback = Result<int, String>.success(0);
        expect(failed.or(fallback).valueOrNull, equals(0));
      });

      test('or returns self on success', () {
        const success = Result<int, String>.success(5);
        const fallback = Result<int, String>.success(0);
        expect(success.or(fallback).valueOrNull, equals(5));
      });
    });

    group('asyncMap', () {
      test('maps success asynchronously', () async {
        const result = Result<int, String>.success(3);
        final mapped = await result.asyncMap(
          (v) async => Result<String, String>.success('value: $v'),
        );
        expect(mapped.valueOrNull, equals('value: 3'));
      });

      test('propagates failure without calling transform', () async {
        const result = Result<int, String>.failure('err');
        var called = false;
        final mapped = await result.asyncMap((v) async {
          called = true;
          return Result<String, String>.success('x');
        });
        expect(called, isFalse);
        expect(mapped.isFailure, isTrue);
      });
    });
  });

  group('PkResult<T>', () {
    test('is a Result with PrimekitException failure type', () {
      const result = Result<String, PrimekitException>.success('ok');
      expect(result, isA<PkResult<String>>());
    });
  });
}
