import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/forms.dart';

void main() {
  group('PkDateSchema', () {
    final baseDate = DateTime(2000, 1, 1);
    final earlyDate = DateTime(1990, 1, 1);
    final lateDate = DateTime(2010, 1, 1);

    test('accepts DateTime directly', () {
      final result = PkSchema.date().validate(baseDate);
      expect(result.isValid, isTrue);
      expect(result.value, equals(baseDate));
    });

    test('accepts ISO-8601 string', () {
      final result = PkSchema.date().validate('2000-01-01T00:00:00.000');
      expect(result.isValid, isTrue);
    });

    test('rejects invalid string', () {
      expect(PkSchema.date().validate('not-a-date').isValid, isFalse);
    });

    test('rejects null when required', () {
      expect(PkSchema.date().required().validate(null).isValid, isFalse);
    });

    test('optional accepts null', () {
      expect(PkSchema.date().optional().validate(null).isValid, isTrue);
    });

    group('after', () {
      test('date after boundary passes', () {
        expect(
          PkSchema.date().after(earlyDate).validate(baseDate).isValid,
          isTrue,
        );
      });

      test('date equal to boundary fails (exclusive)', () {
        expect(
          PkSchema.date().after(baseDate).validate(baseDate).isValid,
          isFalse,
        );
      });

      test('date before boundary fails', () {
        expect(
          PkSchema.date().after(baseDate).validate(earlyDate).isValid,
          isFalse,
        );
      });
    });

    group('before', () {
      test('date before boundary passes', () {
        expect(
          PkSchema.date().before(lateDate).validate(baseDate).isValid,
          isTrue,
        );
      });

      test('date equal to boundary fails (exclusive)', () {
        expect(
          PkSchema.date().before(baseDate).validate(baseDate).isValid,
          isFalse,
        );
      });

      test('date after boundary fails', () {
        expect(
          PkSchema.date().before(baseDate).validate(lateDate).isValid,
          isFalse,
        );
      });
    });

    group('notBefore / notAfter', () {
      test('notBefore with equal date passes', () {
        expect(
          PkSchema.date().notBefore(baseDate).validate(baseDate).isValid,
          isTrue,
        );
      });

      test('notAfter with equal date passes', () {
        expect(
          PkSchema.date().notAfter(baseDate).validate(baseDate).isValid,
          isTrue,
        );
      });
    });

    group('inPast / inFuture', () {
      test('past date passes inPast', () {
        expect(PkSchema.date().inPast().validate(earlyDate).isValid, isTrue);
      });

      test('future date fails inPast', () {
        final future = DateTime.now().add(const Duration(days: 365));
        expect(PkSchema.date().inPast().validate(future).isValid, isFalse);
      });

      test('future date passes inFuture', () {
        final future = DateTime.now().add(const Duration(days: 365));
        expect(PkSchema.date().inFuture().validate(future).isValid, isTrue);
      });

      test('past date fails inFuture', () {
        expect(PkSchema.date().inFuture().validate(earlyDate).isValid, isFalse);
      });
    });
  });
}
