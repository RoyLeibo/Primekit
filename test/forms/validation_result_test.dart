import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/primekit.dart';

void main() {
  group('ValidationResult', () {
    group('valid', () {
      test('isValid is true', () {
        const result = ValidationResult.valid('hello');
        expect(result.isValid, isTrue);
      });

      test('errors is empty', () {
        const result = ValidationResult.valid(42);
        expect(result.errors, isEmpty);
      });

      test('value is preserved', () {
        const result = ValidationResult.valid('test-value');
        expect(result.value, equals('test-value'));
      });

      test('firstError is null', () {
        const result = ValidationResult.valid(true);
        expect(result.firstError, isNull);
      });

      test('errorFor any field returns null', () {
        const result = ValidationResult.valid('x');
        expect(result.errorFor('email'), isNull);
      });

      test('hasError returns false for any field', () {
        const result = ValidationResult.valid('x');
        expect(result.hasError('email'), isFalse);
      });
    });

    group('invalid', () {
      test('isValid is false', () {
        const result = ValidationResult.invalid({'email': 'Required'});
        expect(result.isValid, isFalse);
      });

      test('value is null', () {
        const result = ValidationResult.invalid({'_': 'Error'});
        expect(result.value, isNull);
      });

      test('firstError returns first error message', () {
        const result = ValidationResult.invalid({'_': 'Must be valid'});
        expect(result.firstError, equals('Must be valid'));
      });

      test('errorFor returns correct message', () {
        const result = ValidationResult.invalid({'email': 'Invalid email'});
        expect(result.errorFor('email'), equals('Invalid email'));
        expect(result.errorFor('name'), isNull);
      });

      test('hasError returns true for affected field', () {
        const result = ValidationResult.invalid({'age': 'Too young'});
        expect(result.hasError('age'), isTrue);
        expect(result.hasError('email'), isFalse);
      });
    });

    group('merge', () {
      test('two valid results yield valid', () {
        const a = ValidationResult.valid('a');
        const b = ValidationResult.valid('b');
        final merged = a.merge(b);
        expect(merged.isValid, isTrue);
      });

      test('valid + invalid yields invalid', () {
        const a = ValidationResult.valid('a');
        const b = ValidationResult.invalid({'field': 'Error'});
        final merged = a.merge(b);
        expect(merged.isValid, isFalse);
        expect(merged.errors.containsKey('field'), isTrue);
      });

      test('two invalid results combine errors', () {
        const a = ValidationResult.invalid({'email': 'Bad email'});
        const b = ValidationResult.invalid({'age': 'Too young'});
        final merged = a.merge(b);
        expect(merged.isValid, isFalse);
        expect(merged.errors.containsKey('email'), isTrue);
        expect(merged.errors.containsKey('age'), isTrue);
      });
    });
  });
}
