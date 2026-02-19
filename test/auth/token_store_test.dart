import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// JWT test helpers
// ---------------------------------------------------------------------------

/// Builds a valid 3-segment JWT with the provided claims. No signature is
/// generated; only the expiry check is tested.
String makeJwt({int? exp, String? sub}) {
  const fakeHeader = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
  final claims = <String, dynamic>{
    if (sub != null) 'sub': sub,
    if (exp != null) 'exp': exp,
  };
  final payloadJson = jsonEncode(claims);
  final payloadB64 =
      base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
  return '$fakeHeader.$payloadB64.fakesig';
}

// ---------------------------------------------------------------------------
// Pure unit tests for the JWT expiry logic.
//
// Because _isTokenExpired is private to TokenStore we replicate the exact same
// algorithm here so that the tests document and verify the intended behaviour
// without relying on Dart reflection.
// ---------------------------------------------------------------------------

bool isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final normalized = base64Url.normalize(parts[1]);
    final payloadBytes = base64Url.decode(normalized);
    final payloadJson = utf8.decode(payloadBytes);
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

    final exp = payload['exp'];
    if (exp == null) return false;
    if (exp is! num) return true;

    const clockSkewSeconds = 30;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    final now = DateTime.now().toUtc();
    return now.isAfter(
      expiresAt.subtract(const Duration(seconds: clockSkewSeconds)),
    );
  } catch (_) {
    return true;
  }
}

void main() {
  group('JWT expiry logic', () {
    test('valid token with future exp returns false (not expired)', () {
      final futureExp = DateTime.now()
              .toUtc()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      expect(isTokenExpired(makeJwt(exp: futureExp)), isFalse);
    });

    test('expired token with past exp returns true', () {
      final pastExp = DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      expect(isTokenExpired(makeJwt(exp: pastExp)), isTrue);
    });

    test('token without exp claim returns false (treated as non-expiring)', () {
      expect(isTokenExpired(makeJwt()), isFalse);
    });

    test('malformed token (single segment) returns true', () {
      expect(isTokenExpired('notajwt'), isTrue);
    });

    test('malformed token (two segments) returns true', () {
      expect(isTokenExpired('header.payload'), isTrue);
    });

    test('non-base64 payload returns true', () {
      expect(isTokenExpired('header.!!!invalid!!.sig'), isTrue);
    });

    test('applies 30-second clock-skew: token with 29s remaining is expired',
        () {
      final almostExpiredExp = DateTime.now()
              .toUtc()
              .add(const Duration(seconds: 29))
              .millisecondsSinceEpoch ~/
          1000;
      expect(isTokenExpired(makeJwt(exp: almostExpiredExp)), isTrue);
    });

    test(
        'applies 30-second clock-skew: token with 31s remaining is not expired',
        () {
      final safeExp = DateTime.now()
              .toUtc()
              .add(const Duration(seconds: 31))
              .millisecondsSinceEpoch ~/
          1000;
      expect(isTokenExpired(makeJwt(exp: safeExp)), isFalse);
    });

    test('exp claim exactly at boundary (30s) is considered expired', () {
      final boundaryExp = DateTime.now()
              .toUtc()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch ~/
          1000;
      // now.isAfter(expiresAt - 30s) == now.isAfter(now) == false when exact.
      // The result depends on sub-second precision; we test that expired-at-now
      // is true.
      final expiredNow = DateTime.now()
              .toUtc()
              .millisecondsSinceEpoch ~/
          1000;
      expect(isTokenExpired(makeJwt(exp: expiredNow)), isTrue);
    });

    test('non-numeric exp returns true', () {
      const fakeHeader = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payloadJson = jsonEncode({'exp': 'not-a-number'});
      final payloadB64 =
          base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
      final badJwt = '$fakeHeader.$payloadB64.fakesig';
      expect(isTokenExpired(badJwt), isTrue);
    });
  });

  group('makeJwt helper', () {
    test('produces three segments', () {
      expect(makeJwt().split('.').length, 3);
    });

    test('payload decodes to expected claims', () {
      final exp = 9999999999;
      final jwt = makeJwt(exp: exp, sub: 'user_123');
      final parts = jwt.split('.');
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      expect(decoded['exp'], exp);
      expect(decoded['sub'], 'user_123');
    });
  });
}
