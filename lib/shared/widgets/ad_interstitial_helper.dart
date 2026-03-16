import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdInterstitialHelper {
  static const _adUnitId = 'ca-app-pub-1242280591895560/7058174693';

  InterstitialAd? _interstitialAd;

  void preload() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('전면 광고 로드 실패: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void show({VoidCallback? onDismissed}) {
    if (_interstitialAd == null) {
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preload();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('전면 광고 표시 실패: $error');
        ad.dispose();
        _interstitialAd = null;
        preload();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
