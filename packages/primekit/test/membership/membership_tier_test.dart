import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/membership.dart';

void main() {
  // -------------------------------------------------------------------------
  // Standard tiers
  // -------------------------------------------------------------------------

  group('standard tiers', () {
    test('free tier has level 0', () {
      expect(MembershipTier.free.level, 0);
    });

    test('pro tier has level 10', () {
      expect(MembershipTier.pro.level, 10);
    });

    test('enterprise tier has level 20', () {
      expect(MembershipTier.enterprise.level, 20);
    });

    test('free tier has id "free"', () {
      expect(MembershipTier.free.id, 'free');
    });

    test('pro tier has id "pro"', () {
      expect(MembershipTier.pro.id, 'pro');
    });

    test('enterprise tier has id "enterprise"', () {
      expect(MembershipTier.enterprise.id, 'enterprise');
    });

    test('pro tier has badge label PRO', () {
      expect(MembershipTier.pro.badgeLabel, 'PRO');
    });

    test('free tier has no badge label', () {
      expect(MembershipTier.free.badgeLabel, isNull);
    });

    test('enterprise tier has amber badge color', () {
      expect(MembershipTier.enterprise.badgeColor, isNotNull);
    });

    test('free tier has no badge color', () {
      expect(MembershipTier.free.badgeColor, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // isAtLeast
  // -------------------------------------------------------------------------

  group('isAtLeast()', () {
    test('free is at least free', () {
      expect(MembershipTier.free.isAtLeast(MembershipTier.free), isTrue);
    });

    test('pro is at least free', () {
      expect(MembershipTier.pro.isAtLeast(MembershipTier.free), isTrue);
    });

    test('pro is at least pro', () {
      expect(MembershipTier.pro.isAtLeast(MembershipTier.pro), isTrue);
    });

    test('enterprise is at least pro', () {
      expect(MembershipTier.enterprise.isAtLeast(MembershipTier.pro), isTrue);
    });

    test('enterprise is at least enterprise', () {
      expect(
        MembershipTier.enterprise.isAtLeast(MembershipTier.enterprise),
        isTrue,
      );
    });

    test('free is NOT at least pro', () {
      expect(MembershipTier.free.isAtLeast(MembershipTier.pro), isFalse);
    });

    test('pro is NOT at least enterprise', () {
      expect(MembershipTier.pro.isAtLeast(MembershipTier.enterprise), isFalse);
    });

    test('custom tier with level 15 is at least pro', () {
      const custom = MembershipTier(id: 'custom', name: 'Custom', level: 15);
      expect(custom.isAtLeast(MembershipTier.pro), isTrue);
    });

    test('custom tier with level 15 is NOT at least enterprise', () {
      const custom = MembershipTier(id: 'custom', name: 'Custom', level: 15);
      expect(custom.isAtLeast(MembershipTier.enterprise), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isAbove
  // -------------------------------------------------------------------------

  group('isAbove()', () {
    test('pro is above free', () {
      expect(MembershipTier.pro.isAbove(MembershipTier.free), isTrue);
    });

    test('pro is NOT above pro (same level)', () {
      expect(MembershipTier.pro.isAbove(MembershipTier.pro), isFalse);
    });

    test('enterprise is above pro', () {
      expect(MembershipTier.enterprise.isAbove(MembershipTier.pro), isTrue);
    });

    test('free is NOT above pro', () {
      expect(MembershipTier.free.isAbove(MembershipTier.pro), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isBelow
  // -------------------------------------------------------------------------

  group('isBelow()', () {
    test('free is below pro', () {
      expect(MembershipTier.free.isBelow(MembershipTier.pro), isTrue);
    });

    test('pro is NOT below pro (same level)', () {
      expect(MembershipTier.pro.isBelow(MembershipTier.pro), isFalse);
    });

    test('enterprise is NOT below pro', () {
      expect(MembershipTier.enterprise.isBelow(MembershipTier.pro), isFalse);
    });

    test('pro is below enterprise', () {
      expect(MembershipTier.pro.isBelow(MembershipTier.enterprise), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // equality
  // -------------------------------------------------------------------------

  group('equality', () {
    test('two tiers with same id and level are equal', () {
      const a = MembershipTier(id: 'x', name: 'X', level: 5);
      const b = MembershipTier(id: 'x', name: 'Different Name', level: 5);
      expect(a, equals(b));
    });

    test('two tiers with same id but different level are not equal', () {
      const a = MembershipTier(id: 'x', name: 'X', level: 5);
      const b = MembershipTier(id: 'x', name: 'X', level: 6);
      expect(a, isNot(equals(b)));
    });

    test('MembershipTier.free is equal to itself', () {
      expect(MembershipTier.free, equals(MembershipTier.free));
    });
  });

  // -------------------------------------------------------------------------
  // hashCode
  // -------------------------------------------------------------------------

  group('hashCode', () {
    test('equal tiers have the same hashCode', () {
      const a = MembershipTier(id: 'x', name: 'X', level: 5);
      const b = MembershipTier(id: 'x', name: 'Y', level: 5);
      expect(a.hashCode, b.hashCode);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('copyWith()', () {
    test('replaces level', () {
      final copy = MembershipTier.pro.copyWith(level: 15);
      expect(copy.level, 15);
      expect(copy.id, MembershipTier.pro.id);
    });

    test('replaces name', () {
      final copy = MembershipTier.pro.copyWith(name: 'Super Pro');
      expect(copy.name, 'Super Pro');
    });

    test('replaces perks', () {
      final copy = MembershipTier.free.copyWith(perks: ['Custom perk']);
      expect(copy.perks, ['Custom perk']);
    });

    test('replaces badgeLabel', () {
      final copy = MembershipTier.free.copyWith(badgeLabel: 'FREE');
      expect(copy.badgeLabel, 'FREE');
    });

    test('replaces badgeColor', () {
      const color = Color(0xFF123456);
      final copy = MembershipTier.free.copyWith(badgeColor: color);
      expect(copy.badgeColor, color);
    });

    test('unspecified fields are preserved', () {
      final copy = MembershipTier.pro.copyWith(level: 12);
      expect(copy.name, MembershipTier.pro.name);
      expect(copy.badgeLabel, MembershipTier.pro.badgeLabel);
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------

  group('toString()', () {
    test('includes id, name, and level', () {
      final str = MembershipTier.pro.toString();
      expect(str, contains('pro'));
      expect(str, contains('Pro'));
      expect(str, contains('10'));
    });
  });

  // -------------------------------------------------------------------------
  // Custom tier
  // -------------------------------------------------------------------------

  group('custom tier', () {
    test('can create a tier with level between free and pro', () {
      const starter = MembershipTier(id: 'starter', name: 'Starter', level: 5);
      expect(starter.isAbove(MembershipTier.free), isTrue);
      expect(starter.isBelow(MembershipTier.pro), isTrue);
    });

    test('perks list defaults to empty', () {
      const tier = MembershipTier(id: 't', name: 'T', level: 1);
      expect(tier.perks, isEmpty);
    });
  });
}
