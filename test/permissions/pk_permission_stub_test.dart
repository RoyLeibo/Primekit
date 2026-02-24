import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/permissions/permission_helper_stub.dart';

void main() {
  group('PermissionHelper stub', () {
    test('isGranted() returns true for all permissions', () async {
      for (final p in PkPermission.values) {
        expect(await PermissionHelper.isGranted(p), isTrue,
            reason: 'isGranted($p) should be true on stub');
      }
    });

    test('status() returns granted for all permissions', () async {
      for (final p in PkPermission.values) {
        expect(
          await PermissionHelper.status(p),
          equals(PkPermissionStatus.granted),
          reason: 'status($p) should be granted on stub',
        );
      }
    });

    test('request() returns true for all permissions', () async {
      for (final p in PkPermission.values) {
        expect(await PermissionHelper.request(p), isTrue,
            reason: 'request($p) should be true on stub');
      }
    });

    test('requestMultiple() returns all granted', () async {
      final permissions = PkPermission.values.toList();
      final result = await PermissionHelper.requestMultiple(permissions);

      expect(result.length, equals(permissions.length));
      for (final entry in result.entries) {
        expect(entry.value, equals(PkPermissionStatus.granted),
            reason: '${entry.key} should be granted');
      }
    });

    test('isPermanentlyDenied() returns false for any status', () {
      for (final s in PkPermissionStatus.values) {
        expect(PermissionHelper.isPermanentlyDenied(s), isFalse,
            reason: 'isPermanentlyDenied($s) should be false on stub');
      }
    });

    test('openSettings() completes without error', () async {
      await expectLater(PermissionHelper.openSettings(), completes);
    });
  });

  group('PkPermission enum', () {
    test('has all expected values', () {
      expect(PkPermission.values, contains(PkPermission.camera));
      expect(PkPermission.values, contains(PkPermission.microphone));
      expect(PkPermission.values, contains(PkPermission.location));
      expect(PkPermission.values, contains(PkPermission.notifications));
    });
  });

  group('PkPermissionStatus enum', () {
    test('has all expected values', () {
      expect(PkPermissionStatus.values, contains(PkPermissionStatus.granted));
      expect(PkPermissionStatus.values, contains(PkPermissionStatus.denied));
      expect(PkPermissionStatus.values,
          contains(PkPermissionStatus.permanentlyDenied));
      expect(PkPermissionStatus.values,
          contains(PkPermissionStatus.restricted));
    });
  });
}
