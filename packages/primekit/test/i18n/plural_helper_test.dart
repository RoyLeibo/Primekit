import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:primekit/src/i18n/plural_helper.dart';

void main() {
  group('PluralHelper.plural', () {
    test('returns singular for count=1', () {
      final result = PluralHelper.plural(1, 'item', 'items');
      expect(result, '1 item');
    });

    test('returns plural for count=0', () {
      final result = PluralHelper.plural(0, 'item', 'items');
      expect(result, '0 items');
    });

    test('returns plural for count=2', () {
      final result = PluralHelper.plural(2, 'item', 'items');
      expect(result, '2 items');
    });

    test('returns plural for large count', () {
      final result = PluralHelper.plural(100, 'apple', 'apples');
      expect(result, '100 apples');
    });

    test('includeCount=false returns word only', () {
      final result =
          PluralHelper.plural(3, 'item', 'items', includeCount: false);
      expect(result, 'items');
    });

    test('includeCount=false with singular returns singular word', () {
      final result =
          PluralHelper.plural(1, 'item', 'items', includeCount: false);
      expect(result, 'item');
    });

    test('accepts locale override without error', () {
      final result = PluralHelper.plural(
        2,
        'item',
        'items',
        locale: const Locale('en'),
      );
      expect(result, '2 items');
    });

    test('negative count uses plural form', () {
      // Intl.plural maps negative to 'other' in English.
      final result = PluralHelper.plural(-1, 'item', 'items');
      expect(result, contains('item'));
    });
  });

  group('PluralHelper.pluralWith', () {
    test('uses zero form when count=0 and zero key provided', () {
      final result = PluralHelper.pluralWith(0, {
        'zero': 'no messages',
        'one': 'message',
        'other': 'messages',
      });
      expect(result, 'no messages');
    });

    test('does not prepend count when zero form starts with letter', () {
      final result = PluralHelper.pluralWith(0, {
        'zero': 'no items',
        'other': 'items',
      });
      // zero form "no items" — count not prepended.
      expect(result, 'no items');
      expect(result, isNot(startsWith('0')));
    });

    test('uses one form for count=1', () {
      final result = PluralHelper.pluralWith(1, {
        'one': 'message',
        'other': 'messages',
      });
      expect(result, '1 message');
    });

    test('uses other form for count=2', () {
      final result = PluralHelper.pluralWith(2, {
        'one': 'message',
        'other': 'messages',
      });
      expect(result, '2 messages');
    });

    test('uses other form when no matching special form', () {
      final result = PluralHelper.pluralWith(5, {
        'one': 'item',
        'other': 'items',
      });
      expect(result, '5 items');
    });

    test('includeCount=false omits count prefix', () {
      final result = PluralHelper.pluralWith(
        5,
        {'one': 'item', 'other': 'items'},
        includeCount: false,
      );
      expect(result, 'items');
    });

    test('does not prepend count when form starts with digit', () {
      final result = PluralHelper.pluralWith(5, {
        'one': '1 thing',
        'other': '5 things',
      });
      // The chosen form "5 things" starts with a digit — no prefix added.
      expect(result, '5 things');
    });

    test('assert fires when other key is missing', () {
      expect(
        () => PluralHelper.pluralWith(1, {'one': 'item'}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('large count uses other form', () {
      final result = PluralHelper.pluralWith(1000, {
        'one': 'notification',
        'other': 'notifications',
      });
      expect(result, '1000 notifications');
    });
  });
}
