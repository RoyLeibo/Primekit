import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/forms.dart';

void main() {
  group('PkObjectSchema', () {
    final schema = PkSchema.object({
      'email': PkSchema.string().email().required(),
      'age': PkSchema.number().min(0).max(150).integer().required(),
      'name': PkSchema.string().minLength(2).maxLength(100),
      'website': PkSchema.string().url().optional(),
    });

    test('fully valid input passes', () {
      final result = schema.validate({
        'email': 'user@example.com',
        'age': 30,
        'name': 'Alice',
      });
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('optional field absent — still valid', () {
      final result = schema.validate({
        'email': 'user@example.com',
        'age': 30,
        'name': 'Alice',
        // 'website' absent
      });
      expect(result.isValid, isTrue);
    });

    test('invalid email produces field-level error', () {
      final result = schema.validate({
        'email': 'not-an-email',
        'age': 30,
        'name': 'Alice',
      });
      expect(result.isValid, isFalse);
      expect(result.hasError('email'), isTrue);
      expect(result.hasError('age'), isFalse);
    });

    test('multiple invalid fields produce multiple errors', () {
      final result = schema.validate({
        'email': 'bad-email',
        'age': 200,
        'name': 'Alice',
      });
      expect(result.isValid, isFalse);
      expect(result.hasError('email'), isTrue);
      expect(result.hasError('age'), isTrue);
    });

    test('missing required field produces error', () {
      final result = schema.validate({
        'age': 25,
        'name': 'Bob',
        // 'email' missing
      });
      expect(result.isValid, isFalse);
      expect(result.hasError('email'), isTrue);
    });

    test('null input is rejected when required', () {
      final result = schema.validate(null);
      expect(result.isValid, isFalse);
    });

    test('non-map input is rejected', () {
      final result = schema.validate('not a map');
      expect(result.isValid, isFalse);
    });

    test('validated values are returned in valid result', () {
      final result = schema.validate({
        'email': 'user@example.com',
        'age': 25,
        'name': 'Charlie',
      });
      expect(result.isValid, isTrue);
      final values = result.value as Map<String, dynamic>;
      expect(values['email'], equals('user@example.com'));
      expect(values['age'], equals(25));
      expect(values['name'], equals('Charlie'));
    });

    test('optional schema accepts null', () {
      final optionalSchema = PkSchema.object({
        'x': PkSchema.string(),
      }).optional();
      expect(optionalSchema.validate(null).isValid, isTrue);
    });

    group('fields getter', () {
      test('exposes field schemas', () {
        expect(schema.fields.containsKey('email'), isTrue);
        expect(schema.fields.containsKey('age'), isTrue);
      });
    });
  });
}
