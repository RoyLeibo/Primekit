import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/flags/feature_flag.dart';

void main() {
  group('FeatureFlag', () {
    test('stores key and defaultValue', () {
      const flag = FeatureFlag<bool>(key: 'my_flag', defaultValue: true);
      expect(flag.key, 'my_flag');
      expect(flag.defaultValue, isTrue);
    });

    test('stores optional description', () {
      const flag = FeatureFlag<String>(
        key: 'msg',
        defaultValue: 'hello',
        description: 'Greeting message',
      );
      expect(flag.description, 'Greeting message');
    });

    test('description is null by default', () {
      const flag = FeatureFlag<int>(key: 'count', defaultValue: 0);
      expect(flag.description, isNull);
    });

    test('isBool is true for bool flag', () {
      const flag = FeatureFlag<bool>(key: 'b', defaultValue: false);
      expect(flag.isBool, isTrue);
      expect(flag.isString, isFalse);
    });

    test('isString is true for string flag', () {
      const flag = FeatureFlag<String>(key: 's', defaultValue: '');
      expect(flag.isString, isTrue);
      expect(flag.isBool, isFalse);
    });

    test('isInt is true for int flag', () {
      const flag = FeatureFlag<int>(key: 'i', defaultValue: 0);
      expect(flag.isInt, isTrue);
    });

    test('isDouble is true for double flag', () {
      const flag = FeatureFlag<double>(key: 'd', defaultValue: 0.0);
      expect(flag.isDouble, isTrue);
    });
  });

  group('BoolFlag', () {
    test('is const constructible', () {
      const flag = BoolFlag(key: 'bf', defaultValue: false);
      expect(flag.key, 'bf');
      expect(flag.defaultValue, isFalse);
    });
  });

  group('StringFlag', () {
    test('is const constructible', () {
      const flag = StringFlag(key: 'sf', defaultValue: 'default');
      expect(flag.defaultValue, 'default');
    });
  });

  group('IntFlag', () {
    test('is const constructible', () {
      const flag = IntFlag(key: 'if', defaultValue: 42);
      expect(flag.defaultValue, 42);
    });
  });

  group('DoubleFlag', () {
    test('is const constructible', () {
      const flag = DoubleFlag(key: 'df', defaultValue: 1.5);
      expect(flag.defaultValue, 1.5);
    });
  });

  group('JsonFlag', () {
    test('is const constructible with empty default', () {
      const flag = JsonFlag(key: 'jf', defaultValue: {});
      expect(flag.defaultValue, isEmpty);
    });
  });
}
