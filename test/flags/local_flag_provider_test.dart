import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/flags/local_flag_provider.dart';

void main() {
  group('LocalFlagProvider', () {
    late LocalFlagProvider provider;

    setUp(() {
      provider = LocalFlagProvider({
        'bool_flag': true,
        'string_flag': 'hello',
        'int_flag': 42,
        'double_flag': 3.14,
        'int_as_double': 7,
        'json_flag': <String, dynamic>{'key': 'value'},
      });
    });

    // -----------------------------------------------------------------------
    // Metadata
    // -----------------------------------------------------------------------

    test('providerId is "local"', () {
      expect(provider.providerId, 'local');
    });

    test('lastFetchedAt is null', () {
      expect(provider.lastFetchedAt, isNull);
    });

    // -----------------------------------------------------------------------
    // Lifecycle (no-ops)
    // -----------------------------------------------------------------------

    test('initialize completes without error', () async {
      await expectLater(provider.initialize(), completes);
    });

    test('refresh completes without error', () async {
      await expectLater(provider.refresh(), completes);
    });

    // -----------------------------------------------------------------------
    // getBool
    // -----------------------------------------------------------------------

    test('getBool returns correct value', () {
      expect(provider.getBool('bool_flag', defaultValue: false), isTrue);
    });

    test('getBool returns default for missing key', () {
      expect(provider.getBool('missing', defaultValue: false), isFalse);
    });

    test('getBool returns default when type mismatches', () {
      expect(provider.getBool('string_flag', defaultValue: false), isFalse);
    });

    // -----------------------------------------------------------------------
    // getString
    // -----------------------------------------------------------------------

    test('getString returns correct value', () {
      expect(provider.getString('string_flag', defaultValue: ''), 'hello');
    });

    test('getString returns default for missing key', () {
      expect(provider.getString('missing', defaultValue: 'default'), 'default');
    });

    // -----------------------------------------------------------------------
    // getInt
    // -----------------------------------------------------------------------

    test('getInt returns correct value', () {
      expect(provider.getInt('int_flag', defaultValue: 0), 42);
    });

    test('getInt returns default for missing key', () {
      expect(provider.getInt('missing', defaultValue: -1), -1);
    });

    // -----------------------------------------------------------------------
    // getDouble
    // -----------------------------------------------------------------------

    test('getDouble returns correct double value', () {
      expect(provider.getDouble('double_flag', defaultValue: 0.0), 3.14);
    });

    test('getDouble coerces int to double', () {
      expect(provider.getDouble('int_as_double', defaultValue: 0.0), 7.0);
    });

    test('getDouble returns default for missing key', () {
      expect(provider.getDouble('missing', defaultValue: 1.5), 1.5);
    });

    // -----------------------------------------------------------------------
    // getJson
    // -----------------------------------------------------------------------

    test('getJson returns correct map', () {
      final result = provider.getJson('json_flag', defaultValue: {});
      expect(result, {'key': 'value'});
    });

    test('getJson returns default for missing key', () {
      final result = provider.getJson('missing', defaultValue: {'x': 1});
      expect(result, {'x': 1});
    });

    // -----------------------------------------------------------------------
    // getValue generic
    // -----------------------------------------------------------------------

    test('getValue<bool> returns correct value', () {
      expect(provider.getValue<bool>('bool_flag', false), isTrue);
    });

    test('getValue returns default for missing key', () {
      expect(provider.getValue<String>('missing', 'fallback'), 'fallback');
    });
  });
}
