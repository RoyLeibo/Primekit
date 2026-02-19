import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/primekit.dart';

void main() {
  group('PkNumberSchema', () {
    group('required / optional', () {
      test('required rejects null', () {
        expect(PkSchema.number().required().validate(null).isValid, isFalse);
      });

      test('optional accepts null', () {
        final result = PkSchema.number().optional().validate(null);
        expect(result.isValid, isTrue);
        expect(result.value, isNull);
      });

      test('accepts integer', () {
        expect(PkSchema.number().validate(42).isValid, isTrue);
      });

      test('accepts double', () {
        expect(PkSchema.number().validate(3.14).isValid, isTrue);
      });

      test('accepts numeric string', () {
        final result = PkSchema.number().validate('99');
        expect(result.isValid, isTrue);
        expect(result.value, equals(99));
      });

      test('rejects non-numeric string', () {
        expect(PkSchema.number().validate('abc').isValid, isFalse);
      });

      test('rejects non-numeric type', () {
        expect(PkSchema.number().validate(true).isValid, isFalse);
      });
    });

    group('min', () {
      test('value above minimum passes', () {
        expect(PkSchema.number().min(5).validate(10).isValid, isTrue);
      });

      test('value equal to minimum passes', () {
        expect(PkSchema.number().min(5).validate(5).isValid, isTrue);
      });

      test('value below minimum fails', () {
        final result = PkSchema.number().min(5).validate(4);
        expect(result.isValid, isFalse);
        expect(result.firstError, contains('5'));
      });

      test('custom message is used', () {
        final result = PkSchema.number().min(0, message: 'Must be positive').validate(-1);
        expect(result.firstError, equals('Must be positive'));
      });
    });

    group('max', () {
      test('value below maximum passes', () {
        expect(PkSchema.number().max(100).validate(50).isValid, isTrue);
      });

      test('value equal to maximum passes', () {
        expect(PkSchema.number().max(100).validate(100).isValid, isTrue);
      });

      test('value above maximum fails', () {
        expect(PkSchema.number().max(100).validate(101).isValid, isFalse);
      });
    });

    group('positive / negative', () {
      test('positive accepts 1', () {
        expect(PkSchema.number().positive().validate(1).isValid, isTrue);
      });

      test('positive rejects 0', () {
        expect(PkSchema.number().positive().validate(0).isValid, isFalse);
      });

      test('positive rejects -1', () {
        expect(PkSchema.number().positive().validate(-1).isValid, isFalse);
      });

      test('negative accepts -1', () {
        expect(PkSchema.number().negative().validate(-1).isValid, isTrue);
      });

      test('negative rejects 0', () {
        expect(PkSchema.number().negative().validate(0).isValid, isFalse);
      });
    });

    group('integer', () {
      test('whole number passes', () {
        expect(PkSchema.number().integer().validate(5).isValid, isTrue);
      });

      test('integer-valued double passes', () {
        expect(PkSchema.number().integer().validate(5.0).isValid, isTrue);
      });

      test('fractional double fails', () {
        expect(PkSchema.number().integer().validate(5.5).isValid, isFalse);
      });
    });

    group('multipleOf', () {
      test('multiple of 5 passes', () {
        expect(PkSchema.number().multipleOf(5).validate(25).isValid, isTrue);
      });

      test('non-multiple of 5 fails', () {
        expect(PkSchema.number().multipleOf(5).validate(7).isValid, isFalse);
      });
    });

    group('chaining', () {
      test('age schema validates correctly', () {
        final age = PkSchema.number().min(0).max(150).integer().required();
        expect(age.validate(25).isValid, isTrue);
        expect(age.validate(-1).isValid, isFalse);
        expect(age.validate(151).isValid, isFalse);
        expect(age.validate(25.5).isValid, isFalse);
        expect(age.validate(null).isValid, isFalse);
      });
    });
  });
}
