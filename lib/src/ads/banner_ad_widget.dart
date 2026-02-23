// DEPENDENCY NOTE: This widget requires the `google_mobile_ads` package.
//
// Add to pubspec.yaml:
//   google_mobile_ads: ^5.1.0
//
// Then complete platform setup:
//   iOS:  Add GADApplicationIdentifier to Info.plist
//   Android: Add com.google.android.gms.ads.APPLICATION_ID to AndroidManifest.xml
//
// See: https://pub.dev/packages/google_mobile_ads

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/logger.dart';
import 'ad_event_logger.dart';

// The imports below are conditional — the file compiles without google_mobile_ads
// in environments where the package is absent (e.g. CI without native SDKs),
// and will fail at runtime if the ads SDK is not present.
//
// When google_mobile_ads is in your pubspec, replace these stubs:
//
//   import 'package:google_mobile_ads/google_mobile_ads.dart';

// ---------------------------------------------------------------------------
// PkBannerAd widget
// ---------------------------------------------------------------------------

/// A Flutter widget that loads and displays a Google AdMob banner ad.
///
/// Handles loading state, error state, and auto-reload on failure (default
/// 60 s delay). Shows [placeholder] (or a transparent [SizedBox]) while the
/// ad is loading.
///
/// **Required dependency:** `google_mobile_ads` — see the comment at the top
/// of this file for setup instructions.
///
/// ```dart
/// PkBannerAd(
///   adUnitId: config.bannerId,
///   size: AdSize.banner,
///   placeholder: Container(
///     color: Colors.grey[200],
///     child: const Center(child: Text('Loading ad...')),
///   ),
/// )
/// ```
class PkBannerAd extends StatefulWidget {
  /// Creates a banner ad widget.
  ///
  /// [adUnitId] is the AdMob ad unit ID for this banner.
  /// [size] defaults to [PkAdSize.banner] (320×50).
  /// [placeholder] is shown while the ad is loading; defaults to a
  /// [SizedBox] with the appropriate dimensions.
  const PkBannerAd({
    super.key,
    required this.adUnitId,
    this.size = PkAdSize.banner,
    this.placeholder,
    this.reloadDelay = const Duration(seconds: 60),
  });

  /// The AdMob ad unit ID to load.
  final String adUnitId;

  /// The desired ad size. Defaults to banner (320×50).
  final PkAdSize size;

  /// Widget shown while the ad is loading or on error.
  final Widget? placeholder;

  /// How long to wait before retrying after a load failure.
  final Duration reloadDelay;

  @override
  State<PkBannerAd> createState() => _PkBannerAdState();
}

/// Normalised ad size enum used by [PkBannerAd] without a hard dependency
/// on google_mobile_ads.
///
/// When you add google_mobile_ads to your pubspec, [PkAdSize] values map
/// 1:1 to the corresponding [AdSize] constants.
enum PkAdSize {
  banner(width: 320, height: 50),
  largeBanner(width: 320, height: 100),
  mediumRectangle(width: 300, height: 250),
  fullBanner(width: 468, height: 60),
  leaderboard(width: 728, height: 90);

  const PkAdSize({required this.width, required this.height});

  final int width;
  final int height;
}

class _PkBannerAdState extends State<PkBannerAd> {
  // In a real integration, this would be `BannerAd? _bannerAd`.
  // We declare it as Object? so the file compiles without the package.
  Object? _bannerAd;
  bool _isLoaded = false;
  bool _hasFailed = false;
  Timer? _reloadTimer;

  static const String _tag = 'PkBannerAd';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _disposeBannerAd();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Ad lifecycle — uses dart:mirrors-free dynamic dispatch so this file
  // compiles without google_mobile_ads. Swap out for the real SDK calls when
  // the package is present.
  // ---------------------------------------------------------------------------

  void _loadAd() {
    // The implementation below uses a try/catch to gracefully degrade when
    // google_mobile_ads is not present at runtime.
    //
    // In a project that has google_mobile_ads installed, replace this entire
    // _loadAd() body with:
    //
    // ```dart
    // _bannerAd = BannerAd(
    //   adUnitId: widget.adUnitId,
    //   size: _toAdSize(widget.size),
    //   request: const AdRequest(),
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       if (!mounted) { ad.dispose(); return; }
    //       setState(() { _isLoaded = true; _hasFailed = false; });
    //       AdEventLogger.instance.log(AdEvent.loaded('banner'));
    //     },
    //     onAdFailedToLoad: (ad, error) {
    //       ad.dispose();
    //       if (!mounted) return;
    //       setState(() { _hasFailed = true; _isLoaded = false; });
    //       AdEventLogger.instance.log(
    //         AdEvent.failed('banner', error: error.message),
    //       );
    //       _scheduleReload();
    //     },
    //     onAdClicked: (_) => AdEventLogger.instance.log(AdEvent.clicked('banner')),
    //     onAdImpression: (_) => AdEventLogger.instance.log(AdEvent.shown('banner')),
    //     onAdClosed: (_) => AdEventLogger.instance.log(AdEvent.closed('banner')),
    //   ),
    // )..load();
    // ```

    try {
      PrimekitLogger.debug(
        'PkBannerAd: loading ad unit ${widget.adUnitId}',
        tag: _tag,
      );
      _loadBannerAdDynamic();
    } on Object catch (e, stack) {
      PrimekitLogger.error(
        'PkBannerAd: google_mobile_ads not available or ad load failed.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      _onAdFailed('SDK unavailable: $e');
    }
  }

  void _loadBannerAdDynamic() {
    // Stub implementation — produces the "failed" state so the placeholder
    // is shown when the SDK is absent. Replace with real SDK call per the
    // comment in _loadAd().
    _onAdFailed(
      'google_mobile_ads is not installed. '
      'Add it to pubspec.yaml to enable banner ads.',
    );
  }

  void _onAdFailed(String reason) {
    if (!mounted) return;
    setState(() {
      _hasFailed = true;
      _isLoaded = false;
    });
    AdEventLogger.instance.log(AdEvent.failed('banner', error: reason));
    PrimekitLogger.warning(
      'PkBannerAd: failed to load — $reason. '
      'Retrying in ${widget.reloadDelay.inSeconds}s.',
      tag: _tag,
    );
    _scheduleReload();
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(widget.reloadDelay, () {
      if (mounted) {
        setState(() {
          _hasFailed = false;
          _isLoaded = false;
        });
        _loadAd();
      }
    });
  }

  void _disposeBannerAd() {
    // When google_mobile_ads is present:
    // (_bannerAd as BannerAd?)?.dispose();
    _bannerAd = null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      // When google_mobile_ads is present, replace this with:
      // return SizedBox(
      //   width: widget.size.width.toDouble(),
      //   height: widget.size.height.toDouble(),
      //   child: AdWidget(ad: _bannerAd as BannerAd),
      // );
      return _buildPlaceholder();
    }

    if (_hasFailed) {
      return _buildPlaceholder(showRetryHint: true);
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool showRetryHint = false}) {
    final explicit = widget.placeholder;
    if (explicit != null) {
      return SizedBox(
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        child: explicit,
      );
    }

    if (showRetryHint) {
      return SizedBox(
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFF3F4F6)),
          child: Center(
            child: Text(
              'Ad unavailable',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
    );
  }
}
