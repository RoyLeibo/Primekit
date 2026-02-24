import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/device/biometric_auth_stub.dart';

void main() {
  group('BiometricAuth stub', () {
    test('isAvailable returns false', () async {
      expect(await BiometricAuth.isAvailable, isFalse);
    });

    test('availableTypes returns empty list', () async {
      expect(await BiometricAuth.availableTypes, isEmpty);
    });

    test('authenticate returns notAvailable', () async {
      final result = await BiometricAuth.authenticate(
        reason: 'Test authentication',
      );
      expect(result, equals(BiometricResult.notAvailable));
    });

    test('authenticate with cancelButtonText returns notAvailable', () async {
      final result = await BiometricAuth.authenticate(
        reason: 'Test',
        cancelButtonText: 'Cancel',
      );
      expect(result, equals(BiometricResult.notAvailable));
    });

    test('authenticate with stickyAuth=false returns notAvailable', () async {
      final result = await BiometricAuth.authenticate(
        reason: 'Test',
        stickyAuth: false,
      );
      expect(result, equals(BiometricResult.notAvailable));
    });
  });

  group('BiometricType (shared enum)', () {
    test('all values exist', () {
      expect(BiometricType.values, hasLength(4));
      expect(BiometricType.values, contains(BiometricType.fingerprint));
      expect(BiometricType.values, contains(BiometricType.face));
      expect(BiometricType.values, contains(BiometricType.iris));
      expect(BiometricType.values, contains(BiometricType.any));
    });
  });

  group('BiometricResult (shared enum)', () {
    test('all values exist', () {
      expect(BiometricResult.values, hasLength(6));
      expect(BiometricResult.values, contains(BiometricResult.success));
      expect(BiometricResult.values, contains(BiometricResult.failed));
      expect(BiometricResult.values, contains(BiometricResult.cancelled));
      expect(BiometricResult.values, contains(BiometricResult.notAvailable));
      expect(BiometricResult.values, contains(BiometricResult.lockedOut));
      expect(BiometricResult.values,
          contains(BiometricResult.permanentlyLockedOut));
    });
  });
}
