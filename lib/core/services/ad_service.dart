import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';
import '../../models/user_model.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Android Real Ad Units
  static const String androidHomeBanner = 'ca-app-pub-5496538363794882/1656126354';
  static const String androidPathBanner = 'ca-app-pub-5496538363794882/5136206368';
  static const String androidExerciseBanner = 'ca-app-pub-5496538363794882/3567973828';
  static const String androidSettingsBanner = 'ca-app-pub-5496538363794882/7467395239';
  static const String androidInterstitial = 'ca-app-pub-5496538363794882/9822095836';
  static const String androidRewarded = 'ca-app-pub-5496538363794882/7946202535';

  // iOS Real Ad Units
  static const String iosHomeBanner = 'ca-app-pub-5496538363794882/6960423928';
  static const String iosPathBanner = 'ca-app-pub-5496538363794882/6281767075';
  static const String iosExerciseBanner = 'ca-app-pub-5496538363794882/2035400309';
  static const String iosSettingsBanner = 'ca-app-pub-5496538363794882/6908453032';
  static const String iosInterstitial = 'ca-app-pub-5496538363794882/1412583776';
  static const String iosRewarded = 'ca-app-pub-5496538363794882/7786420431';

  String getBannerAdUnitId(String screenName) {
    if (Platform.isAndroid) {
      switch (screenName) {
        case 'home': return androidHomeBanner;
        case 'path': return androidPathBanner;
        case 'exercise': return androidExerciseBanner;
        case 'settings': return androidSettingsBanner;
        default: return '';
      }
    } else {
      switch (screenName) {
        case 'home': return iosHomeBanner;
        case 'path': return iosPathBanner;
        case 'exercise': return iosExerciseBanner;
        case 'settings': return iosSettingsBanner;
        default: return '';
      }
    }
  }

  String get interstitialAdUnitId => Platform.isAndroid ? androidInterstitial : iosInterstitial;
  String get rewardedAdUnitId => Platform.isAndroid ? androidRewarded : iosRewarded;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitial({VoidCallback? onComplete}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitial();
          onComplete?.call();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      onComplete?.call();
      loadInterstitial();
    }
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewarded({
    required UserModel user,
    required FirebaseService firebaseService,
    required VoidCallback onRewarded,
    required Function(String) onError,
  }) async {
    if (user.dailyRewardedAdCount >= 3) {
      onError("Daily ad limit reached! (3/3)");
      return;
    }

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadRewarded();
          onError("Failed to show ad.");
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: (ad, reward) async {
        await firebaseService.awardJetons(user.uid, 50, source: 'rewarded_ad');
        await firebaseService.updateUserField(user.uid, 'dailyRewardedAdCount', user.dailyRewardedAdCount + 1);
        onRewarded();
      });
      _rewardedAd = null;
    } else {
      onError("Ad not ready yet. Please try again.");
      loadRewarded();
    }
  }
}

final adServiceProvider = Provider((ref) => AdService());
