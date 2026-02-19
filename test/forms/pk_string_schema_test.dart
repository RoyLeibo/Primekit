import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/primekit.dart';

void main() {
  group('PkStringSchema', () {
    group('required / optional', () {
      test('required rejects null', () {
        final schema = PkSchema.string().required();
        expect(schema.validate(null).isValid, isFalse);
      });

      test('required rejects empty string', () {
        final schema = PkSchema.string().required();
        expect(schema.validate('').isValid, isFalse);
      });

      test('required accepts non-empty string', () {
        final schema = PkSchema.string().required();
        final result = schema.validate('hello');
        expect(result.isValid, isTrue);
        expect(result.value, equals('hello'));
      });

      test('optional accepts null', () {
        final schema = PkSchema.string().optional();
        final result = schema.validate(null);
        expect(result.isValid, isTrue);
        expect(result.value, isNull);
      });

      test('optional accepts empty string', () {
        final schema = PkSchema.string().optional();
        expect(schema.validate('').isValid, isTrue);
      });

      test('non-string input is rejected', () {
        final schema = PkSchema.string();
        expect(schema.validate(42).isValid, isFalse);
      });
    });

    group('email', () {
      test('valid email passes', () {
        final schema = PkSchema.string().email();
        expect(schema.validate('user@example.com').isValid, isTrue);
      });

      test('email with subdomain passes', () {
        final schema = PkSchema.string().email();
        expect(schema.validate('a@b.co.uk').isValid, isTrue);
      });

      test('invalid email fails', () {
        final schema = PkSchema.string().email();
        expect(schema.validate('not-an-email').isValid, isFalse);
      });

      test('missing TLD fails', () {
        final schema = PkSchema.string().email();
        expect(schema.validate('user@').isValid, isFalse);
      });

      test('custom error message is used', () {
        final schema = PkSchema.string().email(message: 'Enter valid email');
        final result = schema.validate('bad');
        expect(result.firstError, equals('Enter valid email'));
      });
    });

    group('url', () {
      test('https URL passes', () {
        expect(PkSchema.string().url().validate('https://example.com').isValid, isTrue);
      });

      test('http URL passes', () {
        expect(PkSchema.string().url().validate('http://example.com').isValid, isTrue);
      });

      test('ftp URL fails', () {
        expect(PkSchema.string().url().validate('ftp://files.example.com').isValid, isFalse);
      });

      test('plain string fails', () {
        expect(PkSchema.string().url().validate('example.com').isValid, isFalse);
      });
    });

    group('phone', () {
      test('international format passes', () {
        expect(PkSchema.string().phone().validate('+1 555-555-5555').isValid, isTrue);
      });

      test('local format passes', () {
        expect(PkSchema.string().phone().validate('0541234567').isValid, isTrue);
      });

      test('too short fails', () {
        expect(PkSchema.string().phone().validate('12345').isValid, isFalse);
      });
    });

    group('minLength / maxLength', () {
      test('string meeting minLength passes', () {
        expect(PkSchema.string().minLength(3).validate('abc').isValid, isTrue);
      });

      test('string below minLength fails', () {
        expect(PkSchema.string().minLength(3).validate('ab').isValid, isFalse);
      });

      test('string within maxLength passes', () {
        expect(PkSchema.string().maxLength(5).validate('hello').isValid, isTrue);
      });

      test('string exceeding maxLength fails', () {
        expect(PkSchema.string().maxLength(5).validate('toolong').isValid, isFalse);
      });

      test('chained min and max both applied', () {
        final schema = PkSchema.string().minLength(2).maxLength(4);
        expect(schema.validate('a').isValid, isFalse);
        expect(schema.validate('ab').isValid, isTrue);
        expect(schema.validate('abcd').isValid, isTrue);
        expect(schema.validate('abcde').isValid, isFalse);
      });
    });

    group('pattern', () {
      test('matching pattern passes', () {
        final schema = PkSchema.string().pattern(RegExp(r'^\d{4}$'));
        expect(schema.validate('1234').isValid, isTrue);
      });

      test('non-matching pattern fails', () {
        final schema = PkSchema.string().pattern(RegExp(r'^\d{4}$'));
        expect(schema.validate('abcd').isValid, isFalse);
      });
    });

    group('oneOf', () {
      test('value in list passes', () {
        final schema = PkSchema.string().oneOf(['red', 'green', 'blue']);
        expect(schema.validate('red').isValid, isTrue);
      });

      test('value not in list fails', () {
        final schema = PkSchema.string().oneOf(['red', 'green', 'blue']);
        expect(schema.validate('yellow').isValid, isFalse);
      });
    });

    group('notEmpty', () {
      test('non-whitespace string passes', () {
        expect(PkSchema.string().notEmpty().validate('x').isValid, isTrue);
      });

      test('whitespace-only string fails', () {
        expect(PkSchema.string().notEmpty().validate('   ').isValid, isFalse);
      });
    });

    group('trim', () {
      test('trims before min-length check', () {
        final schema = PkSchema.string().trim().minLength(3);
        // '  a  ' trimmed = 'a' — 1 char — fails minLength(3).
        expect(schema.validate('  a  ').isValid, isFalse);
      });

      test('trimmed value is returned', () {
        final schema = PkSchema.string().trim();
        final result = schema.validate('  hello  ');
        expect(result.value, equals('hello'));
      });
    });

    group('creditCard', () {
      test('valid Visa number passes (Luhn)', () {
        // Test Visa number that passes Luhn.
        expect(
          PkSchema.string().creditCard().validate('4111111111111111').isValid,
          isTrue,
        );
      });

      test('invalid number fails', () {
        expect(
          PkSchema.string().creditCard().validate('1234567890123456').isValid,
          isFalse,
        );
      });

      test('valid number with spaces passes', () {
        expect(
          PkSchema.string().creditCard().validate('4111 1111 1111 1111').isValid,
          isTrue,
        );
      });
    });

    group('isRequired getter', () {
      test('default schema is required', () {
        expect(PkSchema.string().isRequired, isTrue);
      });

      test('optional schema is not required', () {
        expect(PkSchema.string().optional().isRequired, isFalse);
      });

      test('calling required() makes schema required', () {
        expect(PkSchema.string().optional().required().isRequired, isTrue);
      });
    });
  });
}
