import 'dart:io';

/// Configuration holding ad unit IDs for every ad format your app uses.
///
/// Create one config per platform and use [AdUnitConfig.forPlatform] to
/// select the right one at runtime:
///
/// ```dart
/// final config = AdUnitConfig.forPlatform(
///   ios: AdUnitConfig(
///     bannerId: 'ca-app-pub-xxx/yyy',
///     interstitialId: 'ca-app-pub-xxx/zzz',
///     rewardedId: 'ca-app-pub-xxx/www',
///   ),
///   android: AdUnitConfig(
///     bannerId: 'ca-app-pub-aaa/bbb',
///     interstitialId: 'ca-app-pub-aaa/ccc',
///     rewardedId: 'ca-app-pub-aaa/ddd',
///   ),
/// );
/// ```
///
/// During development, use [AdUnitConfig.testIds] to avoid invalid traffic:
///
/// ```dart
/// AdManager.instance.configure(
///   config: kDebugMode ? AdUnitConfig.testIds() : config,
/// );
/// ```
final class AdUnitConfig {
  /// Creates an ad unit configuration.
  const AdUnitConfig({
    required this.bannerId,
    required this.interstitialId,
    required this.rewardedId,
    this.nativeId,
    this.appOpenId,
  });

  /// The ad unit ID for banner ads.
  final String bannerId;

  /// The ad unit ID for interstitial ads.
  final String interstitialId;

  /// The ad unit ID for rewarded ads.
  final String rewardedId;

  /// The ad unit ID for native ads (optional).
  final String? nativeId;

  /// The ad unit ID for app open ads (optional).
  final String? appOpenId;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Selects [ios] or [android] based on the current platform.
  ///
  /// Throws [UnsupportedError] on non-mobile platforms.
  factory AdUnitConfig.forPlatform({
    required AdUnitConfig ios,
    required AdUnitConfig android,
  }) {
    if (Platform.isIOS) return ios;
    if (Platform.isAndroid) return android;
    throw UnsupportedError(
      'AdUnitConfig.forPlatform() is only supported on iOS and Android.',
    );
  }

  /// Returns Google's standard test ad unit IDs.
  ///
  /// Use this during development and testing to avoid generating invalid
  /// traffic against your production ad units.
  ///
  /// See: https://developers.google.com/admob/flutter/test-ads
  factory AdUnitConfig.testIds() {
    if (Platform.isIOS) {
      return const AdUnitConfig(
        bannerId: 'ca-app-pub-3940256099942544/2934735716',
        interstitialId: 'ca-app-pub-3940256099942544/4411468910',
        rewardedId: 'ca-app-pub-3940256099942544/1712485313',
        nativeId: 'ca-app-pub-3940256099942544/3986624511',
        appOpenId: 'ca-app-pub-3940256099942544/5575463023',
      );
    }
    // Android test IDs
    return const AdUnitConfig(
      bannerId: 'ca-app-pub-3940256099942544/6300978111',
      interstitialId: 'ca-app-pub-3940256099942544/1033173712',
      rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      nativeId: 'ca-app-pub-3940256099942544/2247696110',
      appOpenId: 'ca-app-pub-3940256099942544/9257395921',
    );
  }

  /// Returns a copy with the given fields replaced.
  AdUnitConfig copyWith({
    String? bannerId,
    String? interstitialId,
    String? rewardedId,
    String? nativeId,
    String? appOpenId,
  }) =>
      AdUnitConfig(
        bannerId: bannerId ?? this.bannerId,
        interstitialId: interstitialId ?? this.interstitialId,
        rewardedId: rewardedId ?? this.rewardedId,
        nativeId: nativeId ?? this.nativeId,
        appOpenId: appOpenId ?? this.appOpenId,
      );

  @override
  String toString() =>
      'AdUnitConfig(banner: $bannerId, interstitial: $interstitialId, '
      'rewarded: $rewardedId)';
}
