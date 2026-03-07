import 'package:flutter_test/flutter_test.dart';
import 'package:primekit_core/forms.dart';

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

    // -------------------------------------------------------------------------
    // New v1.0.0 method: refine
    // -------------------------------------------------------------------------

    group('refine', () {
      test('passing refinement does not affect valid result', () {
        final passwordSchema = PkSchema.object({
          'password': PkSchema.string().minLength(8).required(),
          'confirmPassword': PkSchema.string().required(),
        }).refine(
          (data) => data['password'] == data['confirmPassword'],
          message: 'Passwords do not match',
        );

        final result = passwordSchema.validate({
          'password': 'secret123',
          'confirmPassword': 'secret123',
        });
        expect(result.isValid, isTrue);
      });

      test('failing refinement produces error under "_" key', () {
        final passwordSchema = PkSchema.object({
          'password': PkSchema.string().minLength(8).required(),
          'confirmPassword': PkSchema.string().required(),
        }).refine(
          (data) => data['password'] == data['confirmPassword'],
          message: 'Passwords do not match',
        );

        final result = passwordSchema.validate({
          'password': 'secret123',
          'confirmPassword': 'different',
        });
        expect(result.isValid, isFalse);
        expect(result.hasError('_'), isTrue);
        expect(result.errorFor('_'), equals('Passwords do not match'));
      });

      test('refinement is not run when field validation fails', () {
        var refinementCalled = false;
        final s = PkSchema.object({
          'email': PkSchema.string().email().required(),
        }).refine((data) {
          refinementCalled = true;
          return true;
        }, message: 'Should not run');

        s.validate({'email': 'bad-email'});
        expect(refinementCalled, isFalse);
      });

      test('multiple refinements are all evaluated in order', () {
        final s = PkSchema.object({
          'start': PkSchema.number().required(),
          'end': PkSchema.number().required(),
        })
            .refine(
              (data) => (data['end'] as num) > (data['start'] as num),
              message: 'end must be after start',
            )
            .refine(
              (data) => (data['end'] as num) - (data['start'] as num) <= 100,
              message: 'range must not exceed 100',
            );

        // Both pass
        expect(
          s.validate({'start': 0, 'end': 50}).isValid,
          isTrue,
        );

        // First refinement fails
        final result1 = s.validate({'start': 10, 'end': 5});
        expect(result1.isValid, isFalse);
        expect(result1.errorFor('_'), equals('end must be after start'));

        // First passes, second fails
        final result2 = s.validate({'start': 0, 'end': 200});
        expect(result2.isValid, isFalse);
        expect(result2.errorFor('_'), equals('range must not exceed 100'));
      });

      test('refine with custom cross-field message is surfaced correctly', () {
        final s = PkSchema.object({
          'username': PkSchema.string().required(),
          'displayName': PkSchema.string().required(),
        }).refine(
          (data) => data['username'] != data['displayName'],
          message: 'Username and display name must differ',
        );

        final result = s.validate({
          'username': 'alice',
          'displayName': 'alice',
        });
        expect(result.isValid, isFalse);
        expect(
          result.firstError,
          equals('Username and display name must differ'),
        );
      });

      test('optional schema with failing refine on non-null input still fails', () {
        final s = PkSchema.object({
          'x': PkSchema.number().required(),
        })
            .optional()
            .refine(
              (data) => (data['x'] as num) > 0,
              message: 'x must be positive',
            );

        expect(s.validate(null).isValid, isTrue); // null is fine — optional
        final result = s.validate({'x': -1});
        expect(result.isValid, isFalse);
        expect(result.errorFor('_'), equals('x must be positive'));
      });
    });
  });
}
