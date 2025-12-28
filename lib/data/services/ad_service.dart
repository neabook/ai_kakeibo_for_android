import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告設定
class AdConfig {
  // テスト用広告ユニットID（本番では実際のIDに置き換え）
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      // テスト用ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }
    // 本番用ID（TODO: 実際のIDに置き換え）
    if (Platform.isAndroid) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      // テスト用ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }
    // 本番用ID（TODO: 実際のIDに置き換え）
    if (Platform.isAndroid) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return '';
  }
}

/// 広告状態
enum AdStatus {
  notLoaded,
  loading,
  loaded,
  showing,
  failed,
}

/// 広告サービス
class AdService {
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  AdStatus _rewardedAdStatus = AdStatus.notLoaded;
  AdStatus _interstitialAdStatus = AdStatus.notLoaded;
  bool _isInitialized = false;

  AdStatus get rewardedAdStatus => _rewardedAdStatus;
  AdStatus get interstitialAdStatus => _interstitialAdStatus;
  bool get isInitialized => _isInitialized;

  /// 広告SDKを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;

      // 初期広告をプリロード
      await loadRewardedAd();
      await loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }
  }

  /// リワード広告をロード
  Future<void> loadRewardedAd() async {
    if (_rewardedAdStatus == AdStatus.loading ||
        _rewardedAdStatus == AdStatus.loaded) {
      return;
    }

    _rewardedAdStatus = AdStatus.loading;

    await RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAdStatus = AdStatus.loaded;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAdStatus = AdStatus.failed;
          debugPrint('Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// インタースティシャル広告をロード
  Future<void> loadInterstitialAd() async {
    if (_interstitialAdStatus == AdStatus.loading ||
        _interstitialAdStatus == AdStatus.loaded) {
      return;
    }

    _interstitialAdStatus = AdStatus.loading;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAdStatus = AdStatus.loaded;
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAdStatus = AdStatus.failed;
          debugPrint('Interstitial ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// リワード広告を表示
  /// 広告視聴完了でtrueを返す
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || _rewardedAdStatus != AdStatus.loaded) {
      // 広告がロードされていない場合、ロードを試みる
      await loadRewardedAd();
      // それでもロードされていなければスキップ（ユーザー体験優先）
      if (_rewardedAd == null) {
        debugPrint('Rewarded ad not available, skipping');
        return true; // 広告なしで続行を許可
      }
    }

    _rewardedAdStatus = AdStatus.showing;
    final completer = Completer<bool>();
    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedAdStatus = AdStatus.notLoaded;
        // 次の広告をプリロード
        loadRewardedAd();
        // 広告が閉じられたら結果を返す
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedAdStatus = AdStatus.failed;
        debugPrint('Failed to show rewarded ad: ${error.message}');
        loadRewardedAd();
        // エラー時はfalseを返す
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    // 広告が閉じられるまで待機
    return completer.future;
  }

  /// インタースティシャル広告を表示
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null || _interstitialAdStatus != AdStatus.loaded) {
      await loadInterstitialAd();
      if (_interstitialAd == null) {
        debugPrint('Interstitial ad not available, skipping');
        return;
      }
    }

    _interstitialAdStatus = AdStatus.showing;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialAdStatus = AdStatus.notLoaded;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialAdStatus = AdStatus.failed;
        debugPrint('Failed to show interstitial ad: ${error.message}');
        loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }

  /// リソースを解放
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}

/// 広告サービスプロバイダー
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 広告初期化状態プロバイダー
final adInitializedProvider = FutureProvider<bool>((ref) async {
  final adService = ref.watch(adServiceProvider);
  await adService.initialize();
  return adService.isInitialized;
});
