import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/membership.dart';

void main() {
  late AccessPolicy policy;

  setUp(() {
    policy = AccessPolicy();
  });

  // -------------------------------------------------------------------------
  // define
  // -------------------------------------------------------------------------

  group('define()', () {
    test('adds a feature to the policy', () {
      policy.define('export_pdf', MembershipTier.pro);
      expect(policy.length, 1);
      expect(policy.allDefinedFeatures, contains('export_pdf'));
    });

    test('overwrites existing feature definition', () {
      policy.define('export_pdf', MembershipTier.pro);
      policy.define('export_pdf', MembershipTier.enterprise);

      expect(policy.requiredTierFor('export_pdf'), MembershipTier.enterprise);
      expect(policy.length, 1); // Still only one entry.
    });

    test('multiple features can be defined independently', () {
      policy.define('export_pdf', MembershipTier.pro);
      policy.define('sso', MembershipTier.enterprise);

      expect(policy.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // defineAll
  // -------------------------------------------------------------------------

  group('defineAll()', () {
    test('registers all entries from the map', () {
      policy.defineAll({
        'export_pdf': MembershipTier.pro,
        'sso': MembershipTier.enterprise,
        'dark_theme': MembershipTier.pro,
      });

      expect(policy.length, 3);
      expect(policy.allDefinedFeatures, containsAll(['export_pdf', 'sso', 'dark_theme']));
    });

    test('merges with existing definitions', () {
      policy.define('existing', MembershipTier.free);
      policy.defineAll({'new_feature': MembershipTier.pro});

      expect(policy.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // undefine
  // -------------------------------------------------------------------------

  group('undefine()', () {
    test('removes a previously defined feature', () {
      policy.define('export_pdf', MembershipTier.pro);
      policy.undefine('export_pdf');

      expect(policy.length, 0);
      expect(policy.allDefinedFeatures, isNot(contains('export_pdf')));
    });

    test('removing an undefined feature is a no-op', () {
      expect(() => policy.undefine('nonexistent'), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear()', () {
    test('removes all definitions', () {
      policy.define('a', MembershipTier.pro);
      policy.define('b', MembershipTier.enterprise);
      policy.clear();

      expect(policy.isEmpty, isTrue);
      expect(policy.length, 0);
    });
  });

  // -------------------------------------------------------------------------
  // canAccess
  // -------------------------------------------------------------------------

  group('canAccess()', () {
    setUp(() {
      policy.define('export_pdf', MembershipTier.pro);
      policy.define('sso', MembershipTier.enterprise);
    });

    test('returns true for undefined feature (open access)', () {
      expect(policy.canAccess('unknown_feature', MembershipTier.free), isTrue);
    });

    test('free user cannot access pro feature', () {
      expect(policy.canAccess('export_pdf', MembershipTier.free), isFalse);
    });

    test('pro user can access pro feature', () {
      expect(policy.canAccess('export_pdf', MembershipTier.pro), isTrue);
    });

    test('enterprise user can access pro feature', () {
      expect(
        policy.canAccess('export_pdf', MembershipTier.enterprise),
        isTrue,
      );
    });

    test('pro user cannot access enterprise feature', () {
      expect(policy.canAccess('sso', MembershipTier.pro), isFalse);
    });

    test('enterprise user can access enterprise feature', () {
      expect(policy.canAccess('sso', MembershipTier.enterprise), isTrue);
    });

    test('custom tier at level 15 can access pro feature', () {
      const custom = MembershipTier(id: 'custom', name: 'Custom', level: 15);
      expect(policy.canAccess('export_pdf', custom), isTrue);
    });

    test('custom tier at level 15 cannot access enterprise feature', () {
      const custom = MembershipTier(id: 'custom', name: 'Custom', level: 15);
      expect(policy.canAccess('sso', custom), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // requiredTierFor
  // -------------------------------------------------------------------------

  group('requiredTierFor()', () {
    test('returns the required tier for a defined feature', () {
      policy.define('export_pdf', MembershipTier.pro);
      expect(policy.requiredTierFor('export_pdf'), MembershipTier.pro);
    });

    test('returns null for an undefined feature', () {
      expect(policy.requiredTierFor('unknown'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // featuresAvailableTo
  // -------------------------------------------------------------------------

  group('featuresAvailableTo()', () {
    setUp(() {
      policy.define('basic_feature', MembershipTier.free);
      policy.define('pro_feature', MembershipTier.pro);
      policy.define('enterprise_feature', MembershipTier.enterprise);
    });

    test('free user can access only free features', () {
      final features = policy.featuresAvailableTo(MembershipTier.free);
      expect(features, contains('basic_feature'));
      expect(features, isNot(contains('pro_feature')));
      expect(features, isNot(contains('enterprise_feature')));
    });

    test('pro user can access free and pro features', () {
      final features = policy.featuresAvailableTo(MembershipTier.pro);
      expect(features, containsAll(['basic_feature', 'pro_feature']));
      expect(features, isNot(contains('enterprise_feature')));
    });

    test('enterprise user can access all features', () {
      final features = policy.featuresAvailableTo(MembershipTier.enterprise);
      expect(features, containsAll([
        'basic_feature',
        'pro_feature',
        'enterprise_feature',
      ]));
    });

    test('returns empty list when no features are defined', () {
      policy.clear();
      expect(policy.featuresAvailableTo(MembershipTier.enterprise), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // featuresLockedFor
  // -------------------------------------------------------------------------

  group('featuresLockedFor()', () {
    setUp(() {
      policy.define('basic_feature', MembershipTier.free);
      policy.define('pro_feature', MembershipTier.pro);
      policy.define('enterprise_feature', MembershipTier.enterprise);
    });

    test('free user has pro and enterprise features locked', () {
      final locked = policy.featuresLockedFor(MembershipTier.free);
      expect(locked, containsAll(['pro_feature', 'enterprise_feature']));
      expect(locked, isNot(contains('basic_feature')));
    });

    test('pro user has only enterprise feature locked', () {
      final locked = policy.featuresLockedFor(MembershipTier.pro);
      expect(locked, contains('enterprise_feature'));
      expect(locked, isNot(contains('pro_feature')));
    });

    test('enterprise user has no features locked', () {
      final locked = policy.featuresLockedFor(MembershipTier.enterprise);
      expect(locked, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // allDefinedFeatures
  // -------------------------------------------------------------------------

  group('allDefinedFeatures', () {
    test('returns all defined feature names', () {
      policy.define('a', MembershipTier.pro);
      policy.define('b', MembershipTier.free);
      expect(policy.allDefinedFeatures, containsAll(['a', 'b']));
    });

    test('returns empty list for empty policy', () {
      expect(policy.allDefinedFeatures, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // isEmpty / length
  // -------------------------------------------------------------------------

  group('isEmpty / length', () {
    test('isEmpty is true for new policy', () {
      expect(policy.isEmpty, isTrue);
    });

    test('isEmpty is false after adding a definition', () {
      policy.define('f', MembershipTier.pro);
      expect(policy.isEmpty, isFalse);
    });

    test('length reflects number of defined features', () {
      expect(policy.length, 0);
      policy.define('a', MembershipTier.pro);
      expect(policy.length, 1);
      policy.define('b', MembershipTier.free);
      expect(policy.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // snapshot
  // -------------------------------------------------------------------------

  group('snapshot', () {
    test('returns immutable copy of policy map', () {
      policy.define('x', MembershipTier.pro);
      final snap = policy.snapshot;

      expect(snap, containsValue(MembershipTier.pro));
      // Modifying snap should not affect the policy.
      expect(() => snap['y'] = MembershipTier.free, throwsUnsupportedError);
    });
  });
}
