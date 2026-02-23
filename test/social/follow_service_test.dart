import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/social/follow_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFollowDataSource extends Mock implements FollowDataSource {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockFollowDataSource mockSource;
  late FollowService service;

  setUp(() {
    mockSource = MockFollowDataSource();
    service = FollowService(source: mockSource);
  });

  group('FollowService', () {
    // -------------------------------------------------------------------------
    // follow
    // -------------------------------------------------------------------------

    group('follow()', () {
      test('delegates to source.follow with correct arguments', () async {
        when(
          () => mockSource.follow(
            followerId: any(named: 'followerId'),
            targetId: any(named: 'targetId'),
          ),
        ).thenAnswer((_) async {});

        await service.follow(followerId: 'userA', targetId: 'userB');

        verify(
          () => mockSource.follow(followerId: 'userA', targetId: 'userB'),
        ).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // unfollow
    // -------------------------------------------------------------------------

    group('unfollow()', () {
      test('delegates to source.unfollow with correct arguments', () async {
        when(
          () => mockSource.unfollow(
            followerId: any(named: 'followerId'),
            targetId: any(named: 'targetId'),
          ),
        ).thenAnswer((_) async {});

        await service.unfollow(followerId: 'userA', targetId: 'userB');

        verify(
          () => mockSource.unfollow(followerId: 'userA', targetId: 'userB'),
        ).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // isFollowing
    // -------------------------------------------------------------------------

    group('isFollowing()', () {
      test('returns true when source returns true', () async {
        when(
          () => mockSource.isFollowing(
            followerId: any(named: 'followerId'),
            targetId: any(named: 'targetId'),
          ),
        ).thenAnswer((_) async => true);

        final result = await service.isFollowing(
          followerId: 'userA',
          targetId: 'userB',
        );

        expect(result, isTrue);
      });

      test('returns false when source returns false', () async {
        when(
          () => mockSource.isFollowing(
            followerId: any(named: 'followerId'),
            targetId: any(named: 'targetId'),
          ),
        ).thenAnswer((_) async => false);

        final result = await service.isFollowing(
          followerId: 'userA',
          targetId: 'userC',
        );

        expect(result, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // getFollowers
    // -------------------------------------------------------------------------

    group('getFollowers()', () {
      test('delegates to source.getFollowers', () async {
        when(
          () => mockSource.getFollowers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => ['userA', 'userB']);

        final followers = await service.getFollowers('userC');

        expect(followers, containsAll(['userA', 'userB']));
        verify(() => mockSource.getFollowers('userC', limit: null)).called(1);
      });

      test('passes limit to source', () async {
        when(
          () => mockSource.getFollowers(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => ['userA']);

        await service.getFollowers('userC', limit: 10);

        verify(() => mockSource.getFollowers('userC', limit: 10)).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // getFollowing
    // -------------------------------------------------------------------------

    group('getFollowing()', () {
      test('delegates to source.getFollowing', () async {
        when(
          () => mockSource.getFollowing(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => ['userX', 'userY']);

        final following = await service.getFollowing('userA');

        expect(following, containsAll(['userX', 'userY']));
        verify(() => mockSource.getFollowing('userA', limit: null)).called(1);
      });
    });
  });
}
