import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/forms.dart';

void main() {
  group('PkBoolSchema', () {
    test('accepts true', () {
      expect(PkSchema.boolean().validate(true).isValid, isTrue);
    });

    test('accepts false', () {
      expect(PkSchema.boolean().validate(false).isValid, isTrue);
    });

    test('accepts string "true"', () {
      final result = PkSchema.boolean().validate('true');
      expect(result.isValid, isTrue);
      expect(result.value, isTrue);
    });

    test('accepts string "false"', () {
      final result = PkSchema.boolean().validate('false');
      expect(result.isValid, isTrue);
      expect(result.value, isFalse);
    });

    test('accepts 1 as true', () {
      final result = PkSchema.boolean().validate(1);
      expect(result.isValid, isTrue);
      expect(result.value, isTrue);
    });

    test('accepts 0 as false', () {
      final result = PkSchema.boolean().validate(0);
      expect(result.isValid, isTrue);
      expect(result.value, isFalse);
    });

    test('rejects null when required', () {
      expect(PkSchema.boolean().required().validate(null).isValid, isFalse);
    });

    test('optional accepts null', () {
      expect(PkSchema.boolean().optional().validate(null).isValid, isTrue);
    });

    test('rejects invalid type', () {
      expect(PkSchema.boolean().validate('maybe').isValid, isFalse);
    });

    group('mustBeTrue', () {
      test('true passes', () {
        expect(PkSchema.boolean().mustBeTrue().validate(true).isValid, isTrue);
      });

      test('false fails', () {
        final result = PkSchema.boolean().mustBeTrue().validate(false);
        expect(result.isValid, isFalse);
        expect(result.firstError, equals('Must be accepted'));
      });

      test('custom message used', () {
        final result = PkSchema.boolean()
            .mustBeTrue(message: 'Accept the ToS')
            .validate(false);
        expect(result.firstError, equals('Accept the ToS'));
      });
    });

    group('mustBeFalse', () {
      test('false passes', () {
        expect(
          PkSchema.boolean().mustBeFalse().validate(false).isValid,
          isTrue,
        );
      });

      test('true fails', () {
        expect(
          PkSchema.boolean().mustBeFalse().validate(true).isValid,
          isFalse,
        );
      });
    });
  });
}
