/// Device — device info, app version, biometric auth, and clipboard helpers.
///
/// ```dart
/// // Device information
/// final info = await DeviceInfo.instance;
/// print(info.details.model);   // 'iPhone 15 Pro'
/// print(info.isIos);           // true
///
/// // App version
/// final version = await AppVersion.info;
/// print(version.version);      // '1.2.3'
///
/// // Biometric authentication
/// final result = await BiometricAuth.authenticate(reason: 'Verify identity');
///
/// // Clipboard
/// await ClipboardHelper.copyWithFeedback(context, 'https://example.com');
/// ```
library primekit_device;

export 'device_info.dart';
export 'app_version.dart';
export 'biometric_auth.dart';
export 'clipboard_helper.dart';
