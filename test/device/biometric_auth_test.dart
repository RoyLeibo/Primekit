import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/device.dart';

// BiometricAuth wraps local_auth which requires a real device/platform channel.
// Unit tests therefore cover only the enum contracts and mapping logic that
// can be exercised without native plugins.

void main() {
  group('BiometricType', () {
    test('all variants exist', () {
      expect(
        BiometricType.values,
        containsAll([
          BiometricType.fingerprint,
          BiometricType.face,
          BiometricType.iris,
          BiometricType.any,
        ]),
      );
    });
  });

  group('BiometricResult', () {
    test('all variants exist', () {
      expect(
        BiometricResult.values,
        containsAll([
          BiometricResult.success,
          BiometricResult.failed,
          BiometricResult.cancelled,
          BiometricResult.notAvailable,
          BiometricResult.lockedOut,
          BiometricResult.permanentlyLockedOut,
        ]),
      );
    });
  });
}
