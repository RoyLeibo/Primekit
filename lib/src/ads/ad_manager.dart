// DEPENDENCY NOTE: AdManager requires `google_mobile_ads`.
//
// Add to pubspec.yaml:
//   google_mobile_ads: ^5.1.0
//
// Platform setup:
//   iOS:  Add GADApplicationIdentifier to Info.plist
//   Android: Add com.google.android.gms.ads.APPLICATION_ID to AndroidManifest.xml
//
// See: https://pub.dev/packages/google_mobile_ads

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'ad_cooldown_timer.dart';
import 'ad_event_logger.dart';
import 'ad_frequency_cap.dart';
import 'ad_unit_config.dart';
import 'banner_ad_widget.dart';

/// The user's ad consent status.
enum ConsentStatus {
  /// Consent was granted (e.g. GDPR consent obtained).
  granted,

  /// Consent was denied; serve non-personalised ads.
  denied,

  /// Unknown — typically before consent flow is presented.
  unknown,
}

/// A reward item returned by a rewarded ad.
final class RewardItem {
  const RewardItem({required this.type, required this.amount});

  /// Reward type string returned by the SDK (e.g. `'coins'`).
  final String type;

  /// Reward amount.
  final int amount;
}

/// The central ad coordinator for Google AdMob.
///
/// Manages banner, interstitial, and rewarded ad formats. Integrates
/// [AdCooldownTimer] and [AdFrequencyCap] to enforce responsible ad pacing.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Configure once at startup (before runApp or in main()):
/// AdManager.instance.configure(
///   config: kDebugMode
///       ? AdUnitConfig.testIds()
///       : AdUnitConfig.forPlatform(ios: myIosConfig, android: myAndroidConfig),
/// );
///
/// // 2. Initialize (calls MobileAds.instance.initialize() internally):
/// await AdManager.instance.initialize();
///
/// // 3. Preload ads:
/// await AdManager.instance.loadInterstitial();
///
/// // 4. Show when appropriate:
/// await AdManager.instance.showInterstitial(screenName: 'HomeScreen');
///
/// // 5. Display a banner widget:
/// AdManager.instance.buildBanner()
/// ```
///
/// **Required dependency:** `google_mobile_ads`
class AdManager {
  AdManager._();

  static final AdManager _instance = AdManager._();

  /// The shared singleton instance.
  static AdManager get instance => _instance;

  static const String _tag = 'AdManager';

  // ---------------------------------------------------------------------------
  // Configuration state
  // ---------------------------------------------------------------------------

  AdUnitConfig? _config;
  ConsentStatus _consentStatus = ConsentStatus.unknown;
  bool _initialized = false;

  final AdCooldownTimer _cooldown = AdCooldownTimer();
  final AdFrequencyCap _frequencyCap = AdFrequencyCap();

  // In a real integration these would be typed as InterstitialAd? / RewardedAd?
  Object? _interstitialAd;
  Object? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  final StreamController<AdEvent> _eventController =
      StreamController<AdEvent>.broadcast();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the ad manager.
  ///
  /// Must be called before [initialize]. Safe to call again to reconfigure.
  void configure({
    required AdUnitConfig config,
    bool testMode = false,
    ConsentStatus? consentStatus,
  }) {
    _config = config;
    _consentStatus = consentStatus ?? ConsentStatus.unknown;

    PrimekitLogger.info(
      'AdManager configured. testMode=$testMode '
      'consent=${_consentStatus.name}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialises the Google Mobile Ads SDK and loads persisted state.
  ///
  /// Throws [ConfigurationException] if [configure] has not been called.
  ///
  /// In a real integration, this calls `MobileAds.instance.initialize()`.
  Future<void> initialize() async {
    if (_config == null) {
      throw const ConfigurationException(
        message: 'AdManager.configure() must be called before initialize().',
      );
    }

    if (_initialized) {
      PrimekitLogger.warning(
        'AdManager.initialize() called more than once. Ignoring.',
        tag: _tag,
      );
      return;
    }

    await Future.wait([
      _cooldown.load(),
      _frequencyCap.load(),
    ]);

    // In a real integration, replace this comment block with:
    //
    // await MobileAds.instance.initialize();
    //
    // if (_consentStatus == ConsentStatus.denied) {
    //   await MobileAds.instance.updateRequestConfiguration(
    //     RequestConfiguration(
    //       tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    //       maxAdContentRating: MaxAdContentRating.g,
    //       tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
    //     ),
    //   );
    // }

    _initialized = true;
    PrimekitLogger.info('AdManager initialized.', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  /// Builds a drop-in banner widget with auto-load and error handling.
  ///
  /// Returns a [PkBannerAd] widget sized to [size]. The widget manages its
  /// own lifecycle — no need to hold a reference.
  ///
  /// [size] defaults to [PkAdSize.banner] (320×50). Use [PkAdSize.mediumRectangle]
  /// for a 300×250 rectangle.
  Widget buildBanner({PkAdSize size = PkAdSize.banner}) {
    _assertInitialized('buildBanner');
    return PkBannerAd(
      adUnitId: _config!.bannerId,
      size: size,
    );
  }

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------

  /// Preloads an interstitial ad so it's ready for instant display.
  ///
  /// Call this a few seconds before you intend to show the ad (e.g. after
  /// a level completes).
  Future<void> loadInterstitial() async {
    _assertInitialized('loadInterstitial');

    // In a real integration, replace this with:
    //
    // InterstitialAd.load(
    //   adUnitId: _config!.interstitialId,
    //   request: const AdRequest(),
    //   adLoadCallback: InterstitialAdLoadCallback(
    //     onAdLoaded: (ad) {
    //       _interstitialAd = ad;
    //       _isInterstitialReady = true;
    //       _emit(AdEvent.loaded('interstitial'));
    //     },
    //     onAdFailedToLoad: (error) {
    //       _isInterstitialReady = false;
    //       _emit(AdEvent.failed('interstitial', error: error.message));
    //     },
    //   ),
    // );

    PrimekitLogger.debug(
      'loadInterstitial called — google_mobile_ads not yet installed.',
      tag: _tag,
    );
    _emit(AdEvent.failed(
      'interstitial',
      error: 'google_mobile_ads SDK not installed.',
    ));
  }

  /// Shows the preloaded interstitial ad if all pacing rules allow it.
  ///
  /// Returns `true` if the ad was shown, `false` otherwise.
  /// [screenName] is recorded in analytics.
  Future<bool> showInterstitial({String? screenName}) async {
    _assertInitialized('showInterstitial');

    if (!_isInterstitialReady || _interstitialAd == null) {
      PrimekitLogger.warning(
        'showInterstitial called but no ad is ready.',
        tag: _tag,
      );
      return false;
    }

    if (!_cooldown.canShowAd) {
      PrimekitLogger.debug(
        'showInterstitial: cooldown in effect '
        '(${_cooldown.timeUntilNextAd?.inSeconds}s remaining).',
        tag: _tag,
      );
      return false;
    }

    if (!_frequencyCap.canShow) {
      PrimekitLogger.debug(
        'showInterstitial: frequency cap reached.',
        tag: _tag,
      );
      return false;
    }

    // In a real integration, replace this block with:
    //
    // final ad = _interstitialAd as InterstitialAd;
    // ad.fullScreenContentCallback = FullScreenContentCallback(
    //   onAdShowedFullScreenContent: (_) {
    //     _emit(AdEvent.shown('interstitial', screenName: screenName));
    //   },
    //   onAdDismissedFullScreenContent: (ad) {
    //     ad.dispose();
    //     _interstitialAd = null;
    //     _isInterstitialReady = false;
    //     _emit(AdEvent.closed('interstitial'));
    //     loadInterstitial(); // pre-load next one
    //   },
    //   onAdFailedToShowFullScreenContent: (ad, error) {
    //     ad.dispose();
    //     _interstitialAd = null;
    //     _isInterstitialReady = false;
    //     _emit(AdEvent.failed('interstitial', error: error.message));
    //   },
    //   onAdClicked: (_) => _emit(AdEvent.clicked('interstitial')),
    // );
    // await ad.show();

    await _cooldown.recordAdShown();
    await _frequencyCap.recordImpression();
    _emit(AdEvent.shown('interstitial', screenName: screenName));
    _isInterstitialReady = false;
    _interstitialAd = null;

    return true;
  }

  /// Whether a preloaded interstitial ad is ready to display.
  bool get isInterstitialReady => _isInterstitialReady;

  // ---------------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------------

  /// Preloads a rewarded ad.
  Future<void> loadRewarded() async {
    _assertInitialized('loadRewarded');

    // In a real integration, replace this with:
    //
    // RewardedAd.load(
    //   adUnitId: _config!.rewardedId,
    //   request: const AdRequest(),
    //   rewardedAdLoadCallback: RewardedAdLoadCallback(
    //     onAdLoaded: (ad) {
    //       _rewardedAd = ad;
    //       _isRewardedReady = true;
    //       _emit(AdEvent.loaded('rewarded'));
    //     },
    //     onAdFailedToLoad: (error) {
    //       _isRewardedReady = false;
    //       _emit(AdEvent.failed('rewarded', error: error.message));
    //     },
    //   ),
    // );

    PrimekitLogger.debug(
      'loadRewarded called — google_mobile_ads not yet installed.',
      tag: _tag,
    );
    _emit(AdEvent.failed(
      'rewarded',
      error: 'google_mobile_ads SDK not installed.',
    ));
  }

  /// Shows the preloaded rewarded ad.
  ///
  /// [onReward] is called when the user earns the reward. Returns `true` if
  /// the ad was shown.
  Future<bool> showRewarded({
    required void Function(RewardItem reward) onReward,
  }) async {
    _assertInitialized('showRewarded');

    if (!_isRewardedReady || _rewardedAd == null) {
      PrimekitLogger.warning(
        'showRewarded called but no ad is ready.',
        tag: _tag,
      );
      return false;
    }

    // In a real integration, replace this block with:
    //
    // final ad = _rewardedAd as RewardedAd;
    // ad.fullScreenContentCallback = FullScreenContentCallback(
    //   onAdShowedFullScreenContent: (_) =>
    //       _emit(AdEvent.shown('rewarded')),
    //   onAdDismissedFullScreenContent: (ad) {
    //     ad.dispose();
    //     _rewardedAd = null;
    //     _isRewardedReady = false;
    //     _emit(AdEvent.closed('rewarded'));
    //     loadRewarded();
    //   },
    //   onAdFailedToShowFullScreenContent: (ad, error) {
    //     ad.dispose();
    //     _rewardedAd = null;
    //     _isRewardedReady = false;
    //     _emit(AdEvent.failed('rewarded', error: error.message));
    //   },
    //   onAdClicked: (_) => _emit(AdEvent.clicked('rewarded')),
    // );
    // await ad.show(
    //   onUserEarnedReward: (_, reward) {
    //     final item = RewardItem(type: reward.type, amount: reward.amount.toInt());
    //     onReward(item);
    //     _emit(AdEvent.rewarded(rewardType: item.type, amount: item.amount));
    //   },
    // );

    _emit(AdEvent.shown('rewarded'));
    _isRewardedReady = false;
    _rewardedAd = null;

    return true;
  }

  /// Whether a preloaded rewarded ad is ready to display.
  bool get isRewardedReady => _isRewardedReady;

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Stream of [AdEvent]s emitted by this manager.
  Stream<AdEvent> get events => _eventController.stream;

  void _emit(AdEvent event) {
    AdEventLogger.instance.log(event);
    _eventController.add(event);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _assertInitialized(String caller) {
    if (!_initialized) {
      throw ConfigurationException(
        message:
            'AdManager.$caller() called before initialize(). '
            'Call AdManager.instance.configure() then '
            'await AdManager.instance.initialize() first.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the manager to its unconfigured state.
  ///
  /// For use in tests only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    _config = null;
    _initialized = false;
    _isInterstitialReady = false;
    _isRewardedReady = false;
    _interstitialAd = null;
    _rewardedAd = null;
    await Future.wait([
      // ignore: invalid_use_of_visible_for_testing_member
      _cooldown.resetForTesting(),
      // ignore: invalid_use_of_visible_for_testing_member
      _frequencyCap.resetForTesting(),
    ]);
  }
}
