import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/social/user_profile.dart';

void main() {
  final now = DateTime.utc(2025, 1, 15, 12, 0, 0);

  final baseProfile = UserProfile(
    id: 'user_1',
    displayName: 'Alice',
    createdAt: now,
    email: 'alice@example.com',
    avatarUrl: 'https://cdn.example.com/avatars/alice.jpg',
    bio: 'Flutter dev',
    followerCount: 42,
    followingCount: 10,
    metadata: const {'verified': true},
  );

  group('UserProfile', () {
    // -------------------------------------------------------------------------
    // toJson / fromJson round-trip
    // -------------------------------------------------------------------------

    group('toJson / fromJson round-trip', () {
      test('round-trips all fields', () {
        final json = baseProfile.toJson();
        final restored = UserProfile.fromJson(json);

        expect(restored.id, baseProfile.id);
        expect(restored.displayName, baseProfile.displayName);
        expect(restored.email, baseProfile.email);
        expect(restored.avatarUrl, baseProfile.avatarUrl);
        expect(restored.bio, baseProfile.bio);
        expect(restored.followerCount, baseProfile.followerCount);
        expect(restored.followingCount, baseProfile.followingCount);
        expect(restored.createdAt, baseProfile.createdAt);
      });

      test('round-trips profile with null optional fields', () {
        final minimal = UserProfile(
          id: 'u2',
          displayName: 'Bob',
          createdAt: now,
        );
        final json = minimal.toJson();
        final restored = UserProfile.fromJson(json);

        expect(restored.id, 'u2');
        expect(restored.displayName, 'Bob');
        expect(restored.email, isNull);
        expect(restored.avatarUrl, isNull);
        expect(restored.bio, isNull);
        expect(restored.followerCount, 0);
        expect(restored.followingCount, 0);
      });

      test('toJson includes email when present', () {
        final json = baseProfile.toJson();
        expect(json.containsKey('email'), isTrue);
        expect(json['email'], 'alice@example.com');
      });

      test('toJson excludes email when null', () {
        final profile = UserProfile(
          id: 'u3',
          displayName: 'Carol',
          createdAt: now,
        );
        final json = profile.toJson();
        expect(json.containsKey('email'), isFalse);
      });

      test('fromJson defaults followerCount to 0 when absent', () {
        final json = {
          'id': 'u1',
          'displayName': 'Dave',
          'createdAt': now.toIso8601String(),
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.followerCount, 0);
      });
    });

    // -------------------------------------------------------------------------
    // copyWith
    // -------------------------------------------------------------------------

    group('copyWith', () {
      test('updates displayName', () {
        final updated = baseProfile.copyWith(displayName: 'Alicia');
        expect(updated.displayName, 'Alicia');
        expect(updated.id, baseProfile.id);
      });

      test('clears optional field with null', () {
        final updated = baseProfile.copyWith(bio: null);
        expect(updated.bio, isNull);
      });

      test('original is unchanged after copyWith', () {
        baseProfile.copyWith(displayName: 'Changed');
        expect(baseProfile.displayName, 'Alice');
      });
    });

    // -------------------------------------------------------------------------
    // Equality
    // -------------------------------------------------------------------------

    group('equality', () {
      test('equal profiles', () {
        final a = UserProfile(id: 'u1', displayName: 'Alice', createdAt: now);
        final b = UserProfile(id: 'u1', displayName: 'Alice', createdAt: now);
        expect(a, b);
      });

      test('not equal with different ids', () {
        final a = UserProfile(id: 'u1', displayName: 'A', createdAt: now);
        final b = UserProfile(id: 'u2', displayName: 'A', createdAt: now);
        expect(a, isNot(b));
      });
    });
  });
}
