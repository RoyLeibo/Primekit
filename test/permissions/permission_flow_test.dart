import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/permissions.dart';

// PermissionFlowResult is a pure-Dart value type with no platform coupling.
// Full PermissionFlow UI flows are covered by integration / widget tests.

void main() {
  group('PermissionRequest', () {
    test('required defaults to true', () {
      const req = PermissionRequest(
        permission: Permission.camera,
        title: 'Camera',
        message: 'Need camera access',
      );
      expect(req.required, isTrue);
    });

    test('required can be set to false', () {
      const req = PermissionRequest(
        permission: Permission.microphone,
        title: 'Microphone',
        message: 'Optional mic',
        required: false,
      );
      expect(req.required, isFalse);
    });
  });

  group('PermissionFlowResult', () {
    test('allGranted returns true when all statuses are granted', () {
      final result = PermissionFlowResult(
        statuses: {
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.granted,
        },
      );
      expect(result.allGranted, isTrue);
    });

    test('allGranted returns false when any status is denied', () {
      final result = PermissionFlowResult(
        statuses: {
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.denied,
        },
      );
      expect(result.allGranted, isFalse);
    });

    test('requiredGrantedFor returns true when all required are granted', () {
      final requests = [
        const PermissionRequest(
          permission: Permission.camera,
          title: 'Camera',
          message: 'Required',
        ),
        const PermissionRequest(
          permission: Permission.microphone,
          title: 'Microphone',
          message: 'Optional',
          required: false,
        ),
      ];

      final result = PermissionFlowResult(
        statuses: {
          Permission.camera: PermissionStatus.granted,
          Permission.microphone: PermissionStatus.denied,
        },
      );

      // camera is required and granted; microphone is optional so ignored.
      expect(result.requiredGrantedFor(requests), isTrue);
    });

    test('requiredGrantedFor returns false when required permission denied', () {
      final requests = [
        const PermissionRequest(
          permission: Permission.camera,
          title: 'Camera',
          message: 'Required',
        ),
      ];

      final result = PermissionFlowResult(
        statuses: {
          Permission.camera: PermissionStatus.denied,
        },
      );

      expect(result.requiredGrantedFor(requests), isFalse);
    });

    test('requiredGrantedFor returns false when required status is absent', () {
      final requests = [
        const PermissionRequest(
          permission: Permission.camera,
          title: 'Camera',
          message: 'Required',
        ),
      ];

      // Camera not in statuses map.
      final result = PermissionFlowResult(statuses: {});

      expect(result.requiredGrantedFor(requests), isFalse);
    });
  });
}
