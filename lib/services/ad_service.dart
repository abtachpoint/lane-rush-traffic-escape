import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'game_store.dart';

class AdConfig {
  // Safe test IDs are enabled in the starter project.
  // Replace the AndroidManifest App ID + these production IDs before publishing.
  static const bool useTestAds = true;
  static const String rewardedProductionId = 'REPLACE_WITH_REWARDED_AD_UNIT_ID';
  static const String interstitialProductionId = 'REPLACE_WITH_INTERSTITIAL_AD_UNIT_ID';

  static const String rewardedTestId = 'ca-app-pub-3940256099942544/5224354917';
  static const String interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';

  static String get rewardedId => useTestAds ? rewardedTestId : rewardedProductionId;
  static String get interstitialId => useTestAds ? interstitialTestId : interstitialProductionId;
}

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _rewardLoading = false;
  bool _interstitialLoading = false;
  int _completedRunsSinceInterstitial = 0;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewarded();
    loadInterstitial();
  }

  void loadRewarded() {
    if (_rewardLoading || _rewarded != null) return;
    _rewardLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardLoading = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (_) {
          _rewardLoading = false;
          _rewarded = null;
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

  void loadInterstitial() {
    if (_interstitialLoading || _interstitial != null || GameStore.instance.removeAds) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = false;
          _interstitial = null;
        },
      ),
    );
  }

  Future<void> onRunCompleted() async {
    if (GameStore.instance.removeAds) return;
    _completedRunsSinceInterstitial++;
    if (_completedRunsSinceInterstitial < 4) return;
    _completedRunsSinceInterstitial = 0;
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    ad.show();
    return done.future;
  }

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
