import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/forms.dart';

void main() {
  group('PkListSchema', () {
    final stringList = PkSchema.list(PkSchema.string().notEmpty());

    test('valid list passes', () {
      final result = stringList.validate(['a', 'b', 'c']);
      expect(result.isValid, isTrue);
      expect((result.value as List).length, equals(3));
    });

    test('null when required fails', () {
      expect(stringList.validate(null).isValid, isFalse);
    });

    test('optional null passes', () {
      final schema = PkSchema.list(PkSchema.string()).optional();
      expect(schema.validate(null).isValid, isTrue);
    });

    test('non-list input fails', () {
      expect(stringList.validate('not a list').isValid, isFalse);
    });

    test('invalid item produces indexed error', () {
      final result = stringList.validate(['a', '', 'c']);
      expect(result.isValid, isFalse);
      expect(result.hasError('[1]'), isTrue);
      expect(result.hasError('[0]'), isFalse);
    });

    test('multiple invalid items produce multiple errors', () {
      final result = stringList.validate(['', '', '']);
      expect(result.isValid, isFalse);
      expect(result.hasError('[0]'), isTrue);
      expect(result.hasError('[1]'), isTrue);
      expect(result.hasError('[2]'), isTrue);
    });

    group('minItems / maxItems', () {
      test('list with enough items passes minItems', () {
        final schema = PkSchema.list(PkSchema.string()).minItems(2);
        expect(schema.validate(['a', 'b']).isValid, isTrue);
      });

      test('list below minItems fails', () {
        final schema = PkSchema.list(PkSchema.string()).minItems(2);
        expect(schema.validate(['a']).isValid, isFalse);
      });

      test('list within maxItems passes', () {
        final schema = PkSchema.list(PkSchema.string()).maxItems(3);
        expect(schema.validate(['a', 'b']).isValid, isTrue);
      });

      test('list above maxItems fails', () {
        final schema = PkSchema.list(PkSchema.string()).maxItems(2);
        expect(schema.validate(['a', 'b', 'c']).isValid, isFalse);
      });
    });

    group('notEmpty', () {
      test('non-empty list passes', () {
        expect(
          PkSchema.list(PkSchema.string()).notEmpty().validate(['x']).isValid,
          isTrue,
        );
      });

      test('empty list fails', () {
        expect(
          PkSchema.list(PkSchema.string()).notEmpty().validate([]).isValid,
          isFalse,
        );
      });
    });

    group('unique', () {
      test('unique list passes', () {
        expect(
          PkSchema.list(
            PkSchema.string(),
          ).unique().validate(['a', 'b', 'c']).isValid,
          isTrue,
        );
      });

      test('duplicate list fails', () {
        expect(
          PkSchema.list(
            PkSchema.string(),
          ).unique().validate(['a', 'a', 'b']).isValid,
          isFalse,
        );
      });
    });
  });
}
