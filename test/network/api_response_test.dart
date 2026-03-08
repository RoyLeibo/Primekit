import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/core.dart';

import 'package:primekit/src/network/api_response.dart';

void main() {
  group('ApiResponse.loading', () {
    const response = ApiResponse<String>.loading();

    test('isLoading is true', () {
      expect(response.isLoading, isTrue);
    });

    test('isSuccess is false', () {
      expect(response.isSuccess, isFalse);
    });

    test('isFailure is false', () {
      expect(response.isFailure, isFalse);
    });

    test('dataOrNull returns null', () {
      expect(response.dataOrNull, isNull);
    });

    test('when calls loading branch', () {
      final result = response.when(
        loading: () => 'loading',
        success: (_) => 'success',
        failure: (_) => 'failure',
      );
      expect(result, 'loading');
    });

    test('map returns ApiLoading of new type', () {
      final mapped = response.map((s) => s.length);
      expect(mapped, isA<ApiLoading<int>>());
      expect(mapped.isLoading, isTrue);
    });

    test('toString contains loading', () {
      expect(response.toString(), contains('loading'));
    });
  });

  group('ApiResponse.success', () {
    const response = ApiResponse<String>.success('hello');

    test('isLoading is false', () {
      expect(response.isLoading, isFalse);
    });

    test('isSuccess is true', () {
      expect(response.isSuccess, isTrue);
    });

    test('isFailure is false', () {
      expect(response.isFailure, isFalse);
    });

    test('dataOrNull returns the data', () {
      expect(response.dataOrNull, 'hello');
    });

    test('when calls success branch with data', () {
      final result = response.when(
        loading: () => '',
        success: (data) => data.toUpperCase(),
        failure: (_) => '',
      );
      expect(result, 'HELLO');
    });

    test('map transforms data into new success', () {
      final mapped = response.map((s) => s.length);
      expect(mapped, isA<ApiSuccess<int>>());
      expect(mapped.dataOrNull, 5);
    });

    test('toString contains data value', () {
      expect(response.toString(), contains('hello'));
    });

    test('equality — same data', () {
      expect(
        const ApiResponse<String>.success('hello'),
        equals(const ApiResponse<String>.success('hello')),
      );
    });

    test('equality — different data', () {
      expect(
        const ApiResponse<String>.success('hello'),
        isNot(equals(const ApiResponse<String>.success('world'))),
      );
    });

    test('hashCode matches for equal instances', () {
      expect(
        const ApiSuccess<String>('hello').hashCode,
        const ApiSuccess<String>('hello').hashCode,
      );
    });
  });

  group('ApiResponse.failure', () {
    const error = NetworkException(message: 'timeout');
    const response = ApiResponse<String>.failure(error);

    test('isLoading is false', () {
      expect(response.isLoading, isFalse);
    });

    test('isSuccess is false', () {
      expect(response.isSuccess, isFalse);
    });

    test('isFailure is true', () {
      expect(response.isFailure, isTrue);
    });

    test('dataOrNull returns null', () {
      expect(response.dataOrNull, isNull);
    });

    test('when calls failure branch with error', () {
      PrimekitException? captured;
      response.when(
        loading: () {},
        success: (_) {},
        failure: (e) => captured = e,
      );
      expect(captured, same(error));
    });

    test('map passes failure through with new type', () {
      final mapped = response.map((s) => s.length);
      expect(mapped, isA<ApiFailure<int>>());
      expect(mapped.isFailure, isTrue);
    });

    test('toString contains failure', () {
      expect(response.toString(), contains('failure'));
    });

    test('equality — same error', () {
      expect(
        const ApiResponse<String>.failure(error),
        equals(const ApiResponse<String>.failure(error)),
      );
    });

    test('hashCode matches for equal instances', () {
      expect(
        const ApiFailure<String>(error).hashCode,
        const ApiFailure<String>(error).hashCode,
      );
    });
  });

  group('ApiResponse type transitions via map', () {
    test('loading maps to loading of new type', () {
      final mapped = const ApiResponse<int>.loading().map((n) => '$n');
      expect(mapped.isLoading, isTrue);
      expect(mapped, isA<ApiLoading<String>>());
    });

    test('success maps data correctly', () {
      final mapped = const ApiResponse<int>.success(42).map((n) => n * 2);
      expect(mapped.isSuccess, isTrue);
      expect(mapped.dataOrNull, 84);
    });

    test('failure maps to failure of new type preserving error', () {
      const err = NoConnectivityException();
      final mapped = const ApiResponse<int>.failure(
        err,
      ).map((n) => n.toString());
      expect(mapped.isFailure, isTrue);
      final result = mapped.when(
        loading: () => null,
        success: (_) => null,
        failure: (e) => e,
      );
      expect(result, isA<NoConnectivityException>());
    });
  });
}
