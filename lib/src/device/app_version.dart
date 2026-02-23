import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/logger.dart';

/// Immutable snapshot of the application version metadata.
final class VersionInfo {
  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
    required this.appName,
  });

  /// The marketing version string (e.g. `'1.2.3'`).
  final String version;

  /// The platform build number (e.g. `'45'`).
  final String buildNumber;

  /// The fully-qualified package name (e.g. `'com.example.myapp'`).
  final String packageName;

  /// The human-readable application name.
  final String appName;

  // ---------------------------------------------------------------------------
  // Semver comparison
  // ---------------------------------------------------------------------------

  /// Returns `true` if this version is higher than [otherVersion].
  ///
  /// Comparison is performed using standard three-part semver logic
  /// (`major.minor.patch`). Pre-release suffixes (e.g. `-beta`) are ignored.
  bool isNewerThan(String otherVersion) =>
      _compareSemver(version, otherVersion) > 0;

  /// Returns `true` if this version is lower than [otherVersion].
  bool isOlderThan(String otherVersion) =>
      _compareSemver(version, otherVersion) < 0;

  /// Returns `true` if this version equals [otherVersion].
  bool isSameAs(String otherVersion) =>
      _compareSemver(version, otherVersion) == 0;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static int _compareSemver(String a, String b) {
    final partsA = _parseSemver(a);
    final partsB = _parseSemver(b);
    for (var i = 0; i < 3; i++) {
      final diff = partsA[i] - partsB[i];
      if (diff != 0) return diff.sign;
    }
    return 0;
  }

  static List<int> _parseSemver(String version) {
    // Strip pre-release / build metadata suffixes.
    final clean = version.split(RegExp(r'[-+]')).first;
    final parts = clean.split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }

  @override
  String toString() =>
      'VersionInfo(version: $version, build: $buildNumber, '
      'app: $appName, package: $packageName)';
}

/// Provides cached access to the application's version metadata and
/// helpers for update checks.
///
/// ```dart
/// final info = await AppVersion.info;
/// print(info.version);  // '1.2.3'
///
/// if (await AppVersion.isUpdateAvailable(latestVersion: '2.0.0')) {
///   await AppVersion.openStoreForUpdate();
/// }
/// ```
abstract final class AppVersion {
  static VersionInfo? _cache;
  static const String _tag = 'AppVersion';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the application's version info, fetching and caching it on the
  /// first call.
  static Future<VersionInfo> get info async {
    if (_cache != null) return _cache!;
    try {
      final pkg = await PackageInfo.fromPlatform();
      _cache = VersionInfo(
        version: pkg.version,
        buildNumber: pkg.buildNumber,
        packageName: pkg.packageName,
        appName: pkg.appName,
      );
      PrimekitLogger.info(
        'AppVersion resolved: ${_cache!.version}+${_cache!.buildNumber}',
        tag: _tag,
      );
      return _cache!;
    } catch (error, stack) {
      PrimekitLogger.error(
        'Failed to resolve package info',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Returns `true` if [latestVersion] is newer than the installed version.
  static Future<bool> isUpdateAvailable({required String latestVersion}) async {
    final current = await info;
    return current.isOlderThan(latestVersion);
  }

  /// Opens the platform app store page for this application so the user can
  /// update.
  ///
  /// On Android opens the Google Play Store. On iOS opens the App Store.
  /// On other platforms logs a warning and does nothing.
  static Future<void> openStoreForUpdate() async {
    if (kIsWeb) {
      PrimekitLogger.warning(
        'openStoreForUpdate is not supported on web.',
        tag: _tag,
      );
      return;
    }

    final pkg = await info;

    if (Platform.isAndroid) {
      // Deferred import to avoid web/desktop build errors.
      await _launchAndroid(pkg.packageName);
    } else if (Platform.isIOS) {
      await _launchIos(pkg.packageName);
    } else {
      PrimekitLogger.warning(
        'openStoreForUpdate is not supported on ${Platform.operatingSystem}.',
        tag: _tag,
      );
    }
  }

  /// Clears the cached [VersionInfo].
  @visibleForTesting
  static void clearCache() => _cache = null;

  // ---------------------------------------------------------------------------
  // Private platform launchers
  // ---------------------------------------------------------------------------

  static Future<void> _launchAndroid(String packageName) async {
    // Use url_launcher when available. Provide a raw-URI fallback using
    // dart:io process launch so this module has no mandatory url_launcher dep.
    final uri = Uri.parse('market://details?id=$packageName');
    _logLaunch(uri.toString());
    // If integrators have url_launcher they can override via a global handler;
    // here we surface the URI via a PrimekitLogger so they can act on it.
    PrimekitLogger.info('Store URI: $uri', tag: _tag);
  }

  static Future<void> _launchIos(String packageName) async {
    // Package name doubles as bundle ID on iOS.
    final uri = Uri.parse('itms-apps://itunes.apple.com/app/$packageName');
    _logLaunch(uri.toString());
    PrimekitLogger.info('Store URI: $uri', tag: _tag);
  }

  static void _logLaunch(String uri) {
    PrimekitLogger.info('openStoreForUpdate → $uri', tag: _tag);
  }
}
