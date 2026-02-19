/// Ads — Google AdMob integration with banner, interstitial, and rewarded ads.
///
/// Includes cooldown timers, frequency caps, and analytics event logging.
/// Designed to integrate with the AdMob SDK (`google_mobile_ads`) while
/// compiling cleanly without it so CI environments without native SDKs work.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Add google_mobile_ads to pubspec.yaml, then configure:
/// AdManager.instance.configure(
///   config: kDebugMode
///       ? AdUnitConfig.testIds()
///       : AdUnitConfig.forPlatform(
///           ios: AdUnitConfig(
///             bannerId: 'ca-app-pub-xxx/yyy',
///             interstitialId: 'ca-app-pub-xxx/zzz',
///             rewardedId: 'ca-app-pub-xxx/www',
///           ),
///           android: AdUnitConfig(
///             bannerId: 'ca-app-pub-aaa/bbb',
///             interstitialId: 'ca-app-pub-aaa/ccc',
///             rewardedId: 'ca-app-pub-aaa/ddd',
///           ),
///         ),
/// );
///
/// // 2. Initialize:
/// await AdManager.instance.initialize();
///
/// // 3. Pre-load an interstitial:
/// await AdManager.instance.loadInterstitial();
///
/// // 4. Show after a natural breakpoint:
/// final shown = await AdManager.instance.showInterstitial(
///   screenName: 'LevelComplete',
/// );
///
/// // 5. Place a banner in your widget tree:
/// AdManager.instance.buildBanner()
///
/// // 6. Listen to events:
/// AdManager.instance.events.listen((event) {
///   switch (event) {
///     case AdRewarded(:final rewardType, :final amount):
///       giveUserCoins(amount);
///     default:
///       break;
///   }
/// });
/// ```
library primekit_ads;

export 'ad_cooldown_timer.dart';
export 'ad_event_logger.dart';
export 'ad_frequency_cap.dart';
export 'ad_manager.dart';
export 'ad_unit_config.dart';
export 'banner_ad_widget.dart';
