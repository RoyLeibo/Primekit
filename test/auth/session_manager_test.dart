import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/auth/session_manager.dart';
import 'package:primekit/src/auth/token_store.dart' show TokenStoreBase;
import 'package:primekit/src/storage/secure_prefs.dart' show SecurePrefsBase;

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTokenStore extends Mock implements TokenStoreBase {}
class MockSecurePrefs extends Mock implements SecurePrefsBase {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String makeJwt({required String sub}) {
  const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'sub': sub})))
      .replaceAll('=', '');
  return '$header.$payload.fakesig';
}

void main() {
  late MockTokenStore mockTokenStore;
  late MockSecurePrefs mockSecurePrefs;
  late SessionManager session;

  setUp(() {
    mockTokenStore = MockTokenStore();
    mockSecurePrefs = MockSecurePrefs();

    SessionManager.resetForTesting(
      tokenStore: mockTokenStore,  // TokenStoreBase
      securePrefs: mockSecurePrefs, // SecurePrefsBase
    );
    session = SessionManager.instance;
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('starts in SessionLoading', () {
      expect(session.state, isA<SessionLoading>());
    });

    test('isAuthenticated is false before restore', () {
      expect(session.isAuthenticated, isFalse);
    });

    test('currentUserId is null before restore', () {
      expect(session.currentUserId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // restore
  // ---------------------------------------------------------------------------

  group('restore', () {
    test('transitions to unauthenticated when no valid token', () async {
      when(() => mockTokenStore.hasValidToken()).thenAnswer((_) async => false);

      await session.restore();

      expect(session.state, isA<SessionUnauthenticated>());
      expect(session.isAuthenticated, isFalse);
    });

    test('transitions to unauthenticated when token valid but no userId', () async {
      when(() => mockTokenStore.hasValidToken()).thenAnswer((_) async => true);
      when(() => mockSecurePrefs.getString(any())).thenAnswer((_) async => null);
      when(() => mockTokenStore.clearAll()).thenAnswer((_) async {});

      await session.restore();

      expect(session.state, isA<SessionUnauthenticated>());
      verify(() => mockTokenStore.clearAll()).called(1);
    });

    test('restores authenticated state when token and userId are present', () async {
      const userId = 'user_abc';
      when(() => mockTokenStore.hasValidToken()).thenAnswer((_) async => true);
      when(() => mockSecurePrefs.getString('pk_session_user_id'))
          .thenAnswer((_) async => userId);
      when(() => mockSecurePrefs.getJson('pk_session_user_data'))
          .thenAnswer((_) async => {'name': 'Alice'});

      await session.restore();

      expect(session.state, isA<SessionAuthenticated>());
      expect(session.currentUserId, userId);
      final authenticated = session.state as SessionAuthenticated;
      expect(authenticated.userData, {'name': 'Alice'});
    });

    test('falls back to unauthenticated on storage exception', () async {
      when(() => mockTokenStore.hasValidToken()).thenThrow(Exception('Storage error'));

      await session.restore();

      expect(session.state, isA<SessionUnauthenticated>());
    });
  });

  // ---------------------------------------------------------------------------
  // login
  // ---------------------------------------------------------------------------

  group('login', () {
    const accessToken = 'access.token.here';
    const refreshToken = 'refresh.token.here';

    setUp(() {
      when(() => mockTokenStore.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStore.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockSecurePrefs.setString(any(), any())).thenAnswer((_) async {});
      when(() => mockSecurePrefs.setJson(any(), any())).thenAnswer((_) async {});
    });

    test('stores tokens and transitions to authenticated', () async {
      final jwt = makeJwt(sub: 'user_123');
      await session.login(accessToken: jwt, refreshToken: refreshToken);

      expect(session.isAuthenticated, isTrue);
      expect(session.currentUserId, 'user_123');
    });

    test('uses provided userId over extracted sub', () async {
      await session.login(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: 'override_id',
      );

      expect(session.currentUserId, 'override_id');
    });

    test('stores userData when provided', () async {
      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: refreshToken,
        userData: {'role': 'admin'},
      );

      verify(
        () => mockSecurePrefs.setJson('pk_session_user_data', {'role': 'admin'}),
      ).called(1);
    });

    test('does not call setJson when userData is null', () async {
      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: refreshToken,
      );

      verifyNever(() => mockSecurePrefs.setJson(any(), any()));
    });

    test('emits authenticated state on stateStream', () async {
      final states = <SessionState>[];
      final sub = session.stateStream.listen(states.add);

      await session.login(
        accessToken: makeJwt(sub: 'stream_user'),
        refreshToken: refreshToken,
      );
      // Allow microtasks to settle.
      await Future<void>.value();

      expect(states, isNotEmpty);
      expect(states.last, isA<SessionAuthenticated>());
      await sub.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('logout', () {
    setUp(() {
      when(() => mockTokenStore.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStore.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockSecurePrefs.setString(any(), any())).thenAnswer((_) async {});
      when(() => mockTokenStore.clearAll()).thenAnswer((_) async {});
      when(() => mockSecurePrefs.remove(any())).thenAnswer((_) async {});
    });

    test('transitions to unauthenticated', () async {
      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: 'rt',
      );
      await session.logout();

      expect(session.state, isA<SessionUnauthenticated>());
      expect(session.isAuthenticated, isFalse);
      expect(session.currentUserId, isNull);
    });

    test('clears tokens on logout', () async {
      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: 'rt',
      );
      await session.logout();

      verify(() => mockTokenStore.clearAll()).called(1);
    });

    test('removes persisted userId and userData on logout', () async {
      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: 'rt',
      );
      await session.logout();

      verify(() => mockSecurePrefs.remove('pk_session_user_id')).called(1);
      verify(() => mockSecurePrefs.remove('pk_session_user_data')).called(1);
    });

    test('forces unauthenticated even when clearAll throws', () async {
      when(() => mockTokenStore.clearAll()).thenThrow(Exception('disk full'));
      when(() => mockSecurePrefs.remove(any())).thenAnswer((_) async {});

      await session.login(
        accessToken: makeJwt(sub: 'u1'),
        refreshToken: 'rt',
      );
      await session.logout();

      expect(session.state, isA<SessionUnauthenticated>());
    });
  });

  // ---------------------------------------------------------------------------
  // stateStream
  // ---------------------------------------------------------------------------

  group('stateStream', () {
    test('emits state changes in order', () async {
      when(() => mockTokenStore.hasValidToken()).thenAnswer((_) async => false);
      when(() => mockTokenStore.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStore.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockSecurePrefs.setString(any(), any())).thenAnswer((_) async {});
      when(() => mockTokenStore.clearAll()).thenAnswer((_) async {});
      when(() => mockSecurePrefs.remove(any())).thenAnswer((_) async {});

      final emitted = <Type>[];
      final sub = session.stateStream.listen(
        (s) => emitted.add(s.runtimeType),
      );

      await session.restore();
      await session.login(
        accessToken: makeJwt(sub: 'u2'),
        refreshToken: 'rt',
      );
      await session.logout();
      // Allow all microtasks and async work to complete.
      await Future<void>.value();
      await Future<void>.value();

      await sub.cancel();

      expect(
        emitted,
        [
          SessionLoading,
          SessionUnauthenticated,
          SessionAuthenticated,
          SessionUnauthenticated,
        ],
      );
    });
  });
}
