import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/logger.dart';

/// Immutable snapshot of device hardware and OS information.
final class DeviceDetails {
  const DeviceDetails({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.manufacturer,
    required this.isPhysicalDevice,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.isTablet,
  });

  /// A stable, platform-provided identifier for this specific device.
  final String deviceId;

  /// Lowercase platform name: `'ios'`, `'android'`, `'web'`, `'macos'`,
  /// `'windows'`, `'linux'`, or `'fuchsia'`.
  final String platform;

  /// OS version string as reported by the platform (e.g. `'17.0'`, `'14'`).
  final String osVersion;

  /// Human-readable device model (e.g. `'iPhone 15 Pro'`, `'Pixel 8'`).
  final String model;

  /// Device manufacturer (e.g. `'Apple'`, `'Google'`).
  final String manufacturer;

  /// `true` when running on a real device; `false` on simulators/emulators.
  final bool isPhysicalDevice;

  /// Logical screen width in density-independent pixels.
  ///
  /// Populated on mobile platforms; `0` on desktop/web where the window
  /// size is dynamic and should be read via [MediaQuery] instead.
  final double screenWidth;

  /// Logical screen height in density-independent pixels.
  ///
  /// Populated on mobile platforms; `0` on desktop/web.
  final double screenHeight;

  /// Native device pixel ratio.
  final double pixelRatio;

  /// `true` when the device is classified as a tablet.
  ///
  /// On Android: `true` when the `feature.hardware.type.tablet` system
  /// feature is present. On iOS: `true` when the model string contains `iPad`.
  final bool isTablet;

  @override
  String toString() =>
      'DeviceDetails(platform: $platform, model: $model, os: $osVersion, '
      'physical: $isPhysicalDevice, tablet: $isTablet)';
}

/// Singleton that provides device hardware and OS information.
///
/// Initialize by calling [DeviceInfo.init] once at app startup, or rely on
/// lazy initialization via [DeviceInfo.instance].
///
/// ```dart
/// final info = await DeviceInfo.instance;
/// if (info.isIos) { ... }
/// print(info.details.model);
/// ```
final class DeviceInfo {
  DeviceInfo._(this.details);

  /// The resolved device details.
  final DeviceDetails details;

  static DeviceInfo? _instance;
  static final _plugin = DeviceInfoPlugin();
  static const String _tag = 'DeviceInfo';

  // ---------------------------------------------------------------------------
  // Singleton access
  // ---------------------------------------------------------------------------

  /// Returns the shared [DeviceInfo] instance, initializing it on first call.
  static Future<DeviceInfo> get instance async =>
      _instance ??= await _resolve();

  /// Pre-initializes [DeviceInfo] and caches the result.
  ///
  /// Call once during app startup so that subsequent [instance] calls are
  /// instantaneous after the first await.
  static Future<void> init() async {
    await instance;
  }

  /// Resets the cached instance (for testing only).
  @visibleForTesting
  static void reset() => _instance = null;

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// Returns `true` when running on iOS.
  bool get isIos => details.platform == 'ios';

  /// Returns `true` when running on Android.
  bool get isAndroid => details.platform == 'android';

  /// Returns `true` when running in a web browser.
  bool get isWeb => details.platform == 'web';

  /// Returns `true` when running on a desktop OS (macOS, Windows, Linux).
  bool get isDesktop =>
      const {'macos', 'windows', 'linux'}.contains(details.platform);

  /// Returns `true` when running on macOS.
  bool get isMacos => details.platform == 'macos';

  /// Returns `true` when running on Windows.
  bool get isWindows => details.platform == 'windows';

  /// Returns `true` when running on Linux.
  bool get isLinux => details.platform == 'linux';

  /// The platform name (same as [DeviceDetails.platform]).
  String get platformName => details.platform;

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  static Future<DeviceInfo> _resolve() async {
    try {
      if (kIsWeb) return _fromWeb();
      if (Platform.isAndroid) return await _fromAndroid();
      if (Platform.isIOS) return await _fromIos();
      if (Platform.isMacOS) return await _fromMacos();
      if (Platform.isWindows) return await _fromWindows();
      if (Platform.isLinux) return await _fromLinux();
      return _fallback('unknown');
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to resolve device info',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      return _fallback('unknown');
    }
  }

  static DeviceInfo _fromWeb() => DeviceInfo._(
    const DeviceDetails(
      deviceId: 'web',
      platform: 'web',
      osVersion: 'unknown',
      model: 'Browser',
      manufacturer: 'unknown',
      isPhysicalDevice: false,
      screenWidth: 0,
      screenHeight: 0,
      pixelRatio: 1.0,
      isTablet: false,
    ),
  );

  static Future<DeviceInfo> _fromAndroid() async {
    final info = await _plugin.androidInfo;
    // Tablet detection: Android declares this standard feature on tablets.
    final isTablet = info.systemFeatures.contains(
      'android.hardware.type.tablet',
    );
    return DeviceInfo._(
      DeviceDetails(
        deviceId: info.id,
        platform: 'android',
        osVersion: info.version.release,
        model: info.model,
        manufacturer: info.manufacturer,
        isPhysicalDevice: info.isPhysicalDevice,
        screenWidth: 0,
        screenHeight: 0,
        pixelRatio: 0,
        isTablet: isTablet,
      ),
    );
  }

  static Future<DeviceInfo> _fromIos() async {
    final info = await _plugin.iosInfo;
    return DeviceInfo._(
      DeviceDetails(
        deviceId: info.identifierForVendor ?? 'unknown',
        platform: 'ios',
        osVersion: info.systemVersion,
        model: info.utsname.machine,
        manufacturer: 'Apple',
        isPhysicalDevice: info.isPhysicalDevice,
        screenWidth: 0,
        screenHeight: 0,
        pixelRatio: 0,
        isTablet: info.model.toLowerCase().contains('ipad'),
      ),
    );
  }

  static Future<DeviceInfo> _fromMacos() async {
    final info = await _plugin.macOsInfo;
    return DeviceInfo._(
      DeviceDetails(
        deviceId: info.systemGUID ?? info.computerName,
        platform: 'macos',
        osVersion:
            '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}',
        model: info.model,
        manufacturer: 'Apple',
        isPhysicalDevice: true,
        screenWidth: 0,
        screenHeight: 0,
        pixelRatio: 1.0,
        isTablet: false,
      ),
    );
  }

  static Future<DeviceInfo> _fromWindows() async {
    final info = await _plugin.windowsInfo;
    return DeviceInfo._(
      DeviceDetails(
        deviceId: info.deviceId,
        platform: 'windows',
        osVersion: info.displayVersion,
        model: info.productName,
        manufacturer: 'unknown',
        isPhysicalDevice: true,
        screenWidth: 0,
        screenHeight: 0,
        pixelRatio: 1.0,
        isTablet: false,
      ),
    );
  }

  static Future<DeviceInfo> _fromLinux() async {
    final info = await _plugin.linuxInfo;
    return DeviceInfo._(
      DeviceDetails(
        deviceId: info.machineId ?? info.id,
        platform: 'linux',
        osVersion: info.version ?? 'unknown',
        model: info.prettyName,
        manufacturer: 'unknown',
        isPhysicalDevice: true,
        screenWidth: 0,
        screenHeight: 0,
        pixelRatio: 1.0,
        isTablet: false,
      ),
    );
  }

  static DeviceInfo _fallback(String platform) => DeviceInfo._(
    DeviceDetails(
      deviceId: 'unknown',
      platform: platform,
      osVersion: 'unknown',
      model: 'unknown',
      manufacturer: 'unknown',
      isPhysicalDevice: false,
      screenWidth: 0,
      screenHeight: 0,
      pixelRatio: 1.0,
      isTablet: false,
    ),
  );
}
