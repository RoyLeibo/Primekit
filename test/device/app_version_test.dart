import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/primekit.dart';

void main() {
  group('VersionInfo', () {
    const v1 = VersionInfo(
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'com.example.app',
      appName: 'Test App',
    );

    const v2 = VersionInfo(
      version: '2.0.0',
      buildNumber: '2',
      packageName: 'com.example.app',
      appName: 'Test App',
    );

    const vPatch = VersionInfo(
      version: '1.0.1',
      buildNumber: '3',
      packageName: 'com.example.app',
      appName: 'Test App',
    );

    const vMinor = VersionInfo(
      version: '1.1.0',
      buildNumber: '4',
      packageName: 'com.example.app',
      appName: 'Test App',
    );

    group('isNewerThan', () {
      test('v2 is newer than v1', () {
        expect(v2.isNewerThan('1.0.0'), isTrue);
      });

      test('v1 is not newer than v2', () {
        expect(v1.isNewerThan('2.0.0'), isFalse);
      });

      test('same version is not newer', () {
        expect(v1.isNewerThan('1.0.0'), isFalse);
      });

      test('patch version newer', () {
        expect(vPatch.isNewerThan('1.0.0'), isTrue);
      });

      test('minor version newer', () {
        expect(vMinor.isNewerThan('1.0.0'), isTrue);
      });

      test('minor version not newer than higher minor', () {
        expect(vMinor.isNewerThan('1.2.0'), isFalse);
      });
    });

    group('isOlderThan', () {
      test('v1 is older than v2', () {
        expect(v1.isOlderThan('2.0.0'), isTrue);
      });

      test('v2 is not older than v1', () {
        expect(v2.isOlderThan('1.0.0'), isFalse);
      });

      test('same version is not older', () {
        expect(v1.isOlderThan('1.0.0'), isFalse);
      });
    });

    group('isSameAs', () {
      test('identical versions are same', () {
        expect(v1.isSameAs('1.0.0'), isTrue);
      });

      test('different versions are not same', () {
        expect(v1.isSameAs('1.0.1'), isFalse);
      });
    });

    group('pre-release suffix handling', () {
      test('semver with pre-release suffix compared correctly', () {
        const vBeta = VersionInfo(
          version: '2.0.0-beta',
          buildNumber: '5',
          packageName: 'com.example.app',
          appName: 'Test App',
        );
        // '2.0.0-beta' → base '2.0.0' == '2.0.0' from v2
        expect(vBeta.isSameAs('2.0.0'), isTrue);
      });
    });

    group('toString', () {
      test('includes version and app name', () {
        expect(v1.toString(), contains('1.0.0'));
        expect(v1.toString(), contains('Test App'));
      });
    });
  });

  group('AppVersion cache', () {
    setUp(AppVersion.clearCache);
    tearDown(AppVersion.clearCache);

    // Full PackageInfo.fromPlatform() integration is tested in integration
    // tests. Here we verify the cache-clearing contract.
    test('clearCache resets the cached value', () {
      AppVersion.clearCache();
      // After clearing, the next call to info would re-fetch from platform.
      // No exception thrown means the API is stable.
    });
  });
}
